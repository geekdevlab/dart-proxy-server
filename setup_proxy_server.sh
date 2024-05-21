#!/bin/bash

set -e

# Функция для вывода сообщений об ошибке и завершения скрипта
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Удаление всех файлов с предыдущей установки
PROJECT_DIR="/opt/proxy_server"
SERVICE_FILE="/etc/systemd/system/proxy_server.service"

if [ -d "$PROJECT_DIR" ]; then
    echo "Удаление предыдущей установки..."
    sudo systemctl stop proxy_server.service || true
    sudo systemctl disable proxy_server.service || true
    sudo rm -rf "$PROJECT_DIR"
    sudo rm -f "$SERVICE_FILE"
    sudo systemctl daemon-reload
fi

# Обновление пакетов и установка необходимых зависимостей
echo "Обновление пакетов и установка необходимых зависимостей..."
if command -v apt-get > /dev/null; then
    sudo apt-get update || error_exit "Не удалось выполнить обновление пакетов."
    sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa || error_exit "Не удалось установить необходимые зависимости."
elif command -v yum > /dev/null; then
    sudo yum install -y curl git unzip xz-utils zip mesa-libGLU || error_exit "Не удалось установить необходимые зависимости."
else
    error_exit "Не удалось определить менеджер пакетов. Скрипт поддерживает только apt-get и yum."
fi

# Загрузка последней версии Flutter SDK
FLUTTER_VERSION="stable"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.10.5-stable.tar.xz"
FLUTTER_DIR="$HOME/flutter"

if [ -d "$FLUTTER_DIR" ]; then
    echo "Flutter уже установлен в $FLUTTER_DIR"
else
    echo "Скачивание Flutter SDK с $FLUTTER_URL..."
    curl -L -o flutter.tar.xz $FLUTTER_URL || error_exit "Ошибка при скачивании Flutter SDK. Проверьте URL и соединение с интернетом."

    # Проверка размера скачанного файла
    FILESIZE=$(stat -c%s "flutter.tar.xz")
    echo "Размер скачанного файла: $FILESIZE байт"
    if [ "$FILESIZE" -lt 1000000 ]; then
        error_exit "Файл слишком маленький, вероятно, загрузка прошла неудачно."
    fi

    echo "Распаковка Flutter SDK..."
    mkdir -p flutter_temp
    tar -xf flutter.tar.xz -C flutter_temp || error_exit "Ошибка при распаковке Flutter SDK. Проверьте, что файл flutter.tar.xz не поврежден."
    
    mv flutter_temp/flutter $FLUTTER_DIR
    rm -rf flutter_temp flutter.tar.xz
fi

# Добавление Flutter в PATH для разных оболочек
SHELL_PROFILE=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -n "$FISH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.config/fish/config.fish"
else
    SHELL_PROFILE="$HOME/.profile"
fi

if grep -q "$FLUTTER_DIR/bin" "$SHELL_PROFILE"; then
    echo "Flutter уже добавлен в PATH"
else
    echo "Добавление Flutter в PATH..."
    echo "export PATH=\"\$PATH:$FLUTTER_DIR/bin\"" >> $SHELL_PROFILE
    source $SHELL_PROFILE
fi

# Установка PATH для текущей сессии
export PATH="$PATH:$FLUTTER_DIR/bin"

# Проверка установки Flutter
flutter --version || error_exit "Ошибка при проверке версии Flutter. Убедитесь, что Flutter установлен правильно."

# Запуск flutter doctor для диагностики установки
flutter doctor || error_exit "Ошибка при запуске 'flutter doctor'. Проверьте, что все зависимости установлены правильно."

echo "Установка Flutter завершена. Пожалуйста, перезапустите терминал или выполните 'source $SHELL_PROFILE' для обновления PATH."

# Создание нового Dart проекта
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

cd $PROJECT_DIR || exit

# Инициализация нового проекта Dart
flutter create --template=package .
dart pub get

# Обновление pubspec.yaml для добавления зависимостей
cat <<EOF > pubspec.yaml
name: proxy_server
description: A simple proxy server to OpenAI API.
version: 1.0.0

environment:
  sdk: '>=2.12.0 <3.0.0'

dependencies:
  shelf: ^1.2.0
  http: ^0.13.4

dev_dependencies:
  lints: ^1.0.0
  test: ^1.16.0
EOF

# Установка зависимостей
dart pub get

# Создание серверного файла
mkdir -p bin
cat <<EOF > bin/server.dart
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:http/http.dart' as http;
import 'package:shelf_router/shelf_router.dart';

Future<Response> proxyOpenAI(Request request) async {
  final apiKey = request.headers['Authorization'];
  if (apiKey == null) {
    return Response(400, body: jsonEncode({'error': 'Authorization header is required'}), headers: {
      'Content-Type': 'application/json',
    });
  }

  final payload = await request.readAsString();
  final openaiUrl = 'https://api.openai.com/v1/engines/davinci-codex/completions';

  final openaiResponse = await http.post(
    Uri.parse(openaiUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': apiKey,
    },
    body: payload,
  );

  return Response(
    openaiResponse.statusCode,
    body: openaiResponse.body,
    headers: {
      'Content-Type': 'application/json',
    },
  );
}

void main() async {
  final router = Router();
  router.post('/proxy_openai', proxyOpenAI);

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 8000);
  print('Server listening on port \${server.port}');
}
EOF

# Создание файла для запуска сервера
cat <<EOF > start_server.sh
#!/bin/bash
dart run bin/server.dart
EOF

# Сделать файл start_server.sh исполняемым
chmod +x start_server.sh

# Создание сервисного файла systemd
cat <<EOF | sudo tee /etc/systemd/system/proxy_server.service
[Unit]
Description=Proxy Server for OpenAI API
After=network.target

[Service]
User=$USER
Group=$(id -gn $USER)
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/start_server.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка systemd для распознавания нового сервиса
sudo systemctl daemon-reload

# Включение сервиса для автозапуска
sudo systemctl enable proxy_server.service

# Запуск сервиса
sudo systemctl start proxy_server.service

# Проверка состояния сервиса
sudo systemctl status proxy_server.service
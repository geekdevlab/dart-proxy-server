#!/bin/bash

# Удаление всех файлов с предыдущей установки
PROJECT_DIR="/opt/proxy_server"
SERVICE_FILE="/etc/systemd/system/proxy_server.service"

if [ -d "$PROJECT_DIR" ]; then
    echo "Удаление предыдущей установки..."
    sudo systemctl stop proxy_server.service
    sudo systemctl disable proxy_server.service
    sudo rm -rf "$PROJECT_DIR"
    sudo rm -f "$SERVICE_FILE"
    sudo systemctl daemon-reload
fi

# Установка Dart SDK
if ! command -v dart &> /dev/null
then
    echo "Dart SDK не найден. Установка..."
    sudo apt update
    sudo apt install -y apt-transport-https
    sudo wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/dart-archive-keyring.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" > /etc/apt/sources.list.d/dart_stable.list'
    sudo apt update
    sudo apt install -y dart
else
    echo "Dart SDK уже установлен."
fi

# Создание нового Dart проекта
dart create $PROJECT_DIR
cd $PROJECT_DIR || exit

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
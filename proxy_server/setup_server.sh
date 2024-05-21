#!/bin/bash

set -e

# Функция для вывода сообщений об ошибке и завершения скрипта
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# URL репозитория с файлом server.dart
REPO_URL="https://raw.githubusercontent.com/geekdevlab/public-tools/main/proxy_server/app"

PROJECT_DIR="/opt/proxy_server"

# Удаление предыдущей установки, если она существует
if [ -d "$PROJECT_DIR" ]; then
    sudo rm -rf "$PROJECT_DIR"
fi

# Создание нового проекта
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

cd $PROJECT_DIR || exit

# Загрузка pubspec.yaml
echo "Скачивание pubspec.yaml ..."
curl -L -o pubspec.yaml "$REPO_URL/pubspec.yaml"

# Установка зависимостей
dart pub get

# Создание директории для сервера и загрузка server.dart
mkdir -p bin
echo "Скачивание server.dart ..."
curl -L -o bin/server.dart "$REPO_URL/bin/server.dart"

# Создание файла для запуска сервера
cat <<EOF > start_server.sh
#!/bin/bash
dart run bin/server.dart
EOF

# Сделать файл start_server.sh исполняемым
chmod +x start_server.sh
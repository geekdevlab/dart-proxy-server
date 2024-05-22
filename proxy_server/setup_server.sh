#!/bin/bash

set -e

# Функция для вывода сообщений об ошибке и завершения скрипта
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# URL репозитория и ветка
REPO_URL="https://github.com/geekdevlab/public-tools.git"
TARGET_DIR="proxy_server/app"

PROJECT_DIR="/opt/proxy_server"
TEMP_DIR="/tmp/proxy_server"

# Удаление предыдущей установки, если она существует
if [ -d "$PROJECT_DIR" ]; then
    sudo rm -rf "$PROJECT_DIR"
fi

# Удаление временной директории, если она существует
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# Создание временной директории
mkdir -p $TEMP_DIR

# Скачивание и извлечение нужной папки из репозитория
echo "Скачивание и извлечение папки $TARGET_DIR из репозитория ..."
git archive --remote=$REPO_URL HEAD $TARGET_DIR | tar -x -C $TEMP_DIR || error_exit "Не удалось скачать или распаковать архив проекта"

# Перемещение файлов проекта в целевую директорию
sudo mkdir -p $PROJECT_DIR
sudo mv $TEMP_DIR/$TARGET_DIR/* $PROJECT_DIR || error_exit "Не удалось переместить файлы проекта"
sudo chown -R $USER:$USER $PROJECT_DIR

# Установка зависимостей
cd $PROJECT_DIR || exit
dart pub get || error_exit "Не удалось установить зависимости"

# Создание файла для запуска сервера
cat <<EOF > start_server.sh
#!/bin/bash
dart run bin/server.dart
EOF

# Сделать файл start_server.sh исполняемым
chmod +x start_server.sh

# Запуск сервера в фоновом режиме
./start_server.sh &

# Ожидание запуска сервера
sleep 5

# Проверка состояния сервера
echo "Проверка состояния сервера..."
HEALTHCHECK_URL="http://localhost:8000/healthcheck"
HEALTHCHECK_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTHCHECK_URL)

if [ "$HEALTHCHECK_RESPONSE" -eq 200 ]; then
    echo "Сервер успешно запущен и работает."
else
    error_exit "Сервер не отвечает на запрос healthcheck."
fi
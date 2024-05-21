#!/bin/bash

set -e

# Функция для загрузки скрипта
download_script() {
    local url=$1
    local script_name=$(basename $url)
    echo "Скачивание $script_name ..."
    curl -L -o $script_name $url
    chmod +x $script_name
}

# URL скриптов
BASE_URL="https://github.com/geekdevlab/public-tools/main"

SCRIPTS=(
    "$BASE_URL/proxy_server/cleanup_previous_installation.sh"
    "$BASE_URL/tools/install_flutter_linux.sh"
    "$BASE_URL/proxy_server/setup_server.sh"
    "$BASE_URL/proxy_server/setup_service.sh"
)

# Загрузка и выполнение скриптов
for script in "${SCRIPTS[@]}"; do
    download_script $script
    ./$(basename $script)
done

# Удаление загруженных скриптов
for script in "${SCRIPTS[@]}"; do
    rm -f $(basename $script)
done

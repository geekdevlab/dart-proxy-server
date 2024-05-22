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
BASE_URL="https://raw.githubusercontent.com/geekdevlab/public-tools/main"

SCRIPTS=(
    "$BASE_URL/proxy_server/cleanup.sh"
    "$BASE_URL/tools/install_flutter_linux.sh"
    "$BASE_URL/proxy_server/setup_server.sh"
    "$BASE_URL/proxy_server/setup_service.sh"
    "$BASE_URL/proxy_server/setup_nginx.sh"
    "$BASE_URL/proxy_server/setup_https.sh"
)

# Загрузка и выполнение скриптов
for script in "${SCRIPTS[@]}"; do
    download_script $script
    ./$(basename $script)
    rm -f $(basename $script) # Удаление скрипта после выполнения
done

echo "Все скрипты выполнены и удалены."
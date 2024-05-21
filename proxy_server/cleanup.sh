#!/bin/bash

set -e

# Функция для вывода сообщений об ошибке и завершения скрипта
error_exit() {
    echo "$1" 1>&2
    exit 1
}

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
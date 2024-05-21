#!/bin/bash

set -e

# Функция для вывода сообщений об ошибке и завершения скрипта
error_exit() {
    echo "$1" 1>&2
    exit 1
}

PROJECT_DIR="/opt/proxy_server"

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
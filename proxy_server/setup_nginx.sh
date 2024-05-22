#!/bin/bash

set -e

# Функция для вывода сообщений об ошибке и завершения скрипта
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Установка Nginx
echo "Установка Nginx..."
sudo apt-get update
sudo apt-get install -y nginx || error_exit "Не удалось установить Nginx"

# Настройка Nginx для проксирования запросов к приложению Dart
NGINX_CONFIG="/etc/nginx/sites-available/default"
sudo cat <<EOF > $NGINX_CONFIG
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Перезапуск Nginx для применения изменений
sudo systemctl restart nginx || error_exit "Не удалось перезапустить Nginx"

echo "Nginx установлен и настроен для проксирования запросов к приложению Dart."
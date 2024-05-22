#!/bin/bash

set -e

# Проверка на наличие входного параметра
if [ -z "$1" ]; then
    echo "Использование: $0 <домен>"
    exit 1
fi

DOMAIN=$1

# Функция для вывода сообщений об ошибке и завершения скрипта
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Проверка и установка необходимых зависимостей
install_dependencies() {
    echo "Обновление пакетов и установка необходимых зависимостей..."
    if command -v apt-get > /dev/null; then
        sudo apt-get update || error_exit "Не удалось выполнить обновление пакетов."
        sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa nginx certbot python3-certbot-nginx || error_exit "Не удалось установить необходимые зависимости."
    elif command -v yum > /dev/null; then
        sudo yum install -y curl git unzip xz-utils zip mesa-libGLU nginx certbot python3-certbot-nginx || error_exit "Не удалось установить необходимые зависимости."
    else
        error_exit "Не удалось определить менеджер пакетов. Скрипт поддерживает только apt-get и yum."
    fi
}

# Настройка Nginx для проксирования запросов
setup_nginx() {
    NGINX_CONFIG="/etc/nginx/sites-available/default"
    echo "Настройка Nginx..."
    sudo bash -c "cat > $NGINX_CONFIG" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    echo "Перезапуск Nginx..."
    sudo systemctl restart nginx || error_exit "Не удалось перезапустить Nginx"
}

# Получение и настройка SSL-сертификата
setup_https() {
    echo "Получение SSL-сертификата от Let's Encrypt..."
    sudo certbot --nginx -d $DOMAIN || error_exit "Не удалось получить SSL-сертификат"
    echo "Перезагрузка Nginx..."
    sudo systemctl reload nginx || error_exit "Не удалось перезагрузить Nginx"
}

# Проверка состояния сервера
check_server() {
    echo "Проверка HTTP-запроса..."
    HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" http://$DOMAIN/healthcheck)
    echo "HTTP статус: $HTTP_STATUS"
    if [ "$HTTP_STATUS" -ne 301 ]; then
        error_exit "Сервер не отвечает на запрос healthcheck через HTTP"
    fi
    
    echo "Проверка HTTPS-запроса..."
    HTTPS_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" https://$DOMAIN/healthcheck)
    echo "HTTPS статус: $HTTPS_STATUS"
    if [ "$HTTPS_STATUS" -ne 200 ];then
        error_exit "HTTPS сервер не отвечает на запрос healthcheck"
    fi

    echo "Сервер успешно запущен и работает с HTTPS."
}

# Основной процесс
main() {
    install_dependencies
    setup_nginx
    setup_https
    check_server
}

main
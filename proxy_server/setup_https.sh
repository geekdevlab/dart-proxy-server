#!/bin/bash

set -e

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
    sudo bash -c "cat > $NGINX_CONFIG" <<EOF
server {
    listen 80;
    server_name proxy.gdlabenv.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    sudo systemctl restart nginx || error_exit "Не удалось перезапустить Nginx"
}

# Получение и настройка SSL-сертификата
setup_https() {
    sudo certbot --nginx -d proxy.gdlabenv.com || error_exit "Не удалось получить SSL-сертификат"
    sudo systemctl reload nginx || error_exit "Не удалось перезагрузить Nginx"
}

# Проверка состояния сервера
check_server() {
    # Проверка HTTP-запроса
    HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" http://proxy.gdlabenv.com/healthcheck)
    if [ "$HTTP_STATUS" -ne 301 ]; then
        error_exit "Сервер не отвечает на запрос healthcheck через HTTP"
    fi
    
    # Проверка HTTPS-запроса
    HTTPS_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" https://proxy.gdlabenv.com/healthcheck)
    if [ "$HTTPS_STATUS" -ne 200 ]; then
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
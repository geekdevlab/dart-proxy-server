Этот скрипт выполнит все необходимые шаги для установки, настройки и запуска вашего прокси-сервера для API OpenAI на Dart, а также настроит его для автоматического запуска при старте системы.

wget https://raw.githubusercontent.com/geekdevlab/public-tools/main/proxy_server/install.sh

Сделайте файл install.sh исполняемым

chmod +x install.sh

Запустите скрипт
./install.sh

Проверка сервера
curl "http://localhost:8000/healthcheck"
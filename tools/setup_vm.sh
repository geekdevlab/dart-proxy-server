#!/bin/bash

# Обновление списка пакетов и установка необходимых зависимостей
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Создание директории для ключей APT и добавление официального GPG-ключа Docker
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Добавление Docker репозитория в список источников APT
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Обновление списка пакетов
sudo apt-get update

# Установка Docker и его компонентов
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Настройка Docker для использования зеркала Яндекса
sudo mkdir -p /etc/docker
echo '{
  "registry-mirrors": ["https://cr.yandex/mirror"]
}' | sudo tee /etc/docker/daemon.json > /dev/null

# Перезапуск Docker для применения новых настроек
sudo systemctl restart docker

# Проверка статуса Docker
sudo systemctl status docker --no-pager

# Запуск тестового контейнера, чтобы проверить, что Docker работает правильно
sudo docker run hello-world

# Проверка, что Docker работает правильно (опционально)
if sudo docker run hello-world​⬤
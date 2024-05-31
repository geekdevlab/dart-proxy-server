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
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Обновление списка пакетов
sudo apt-get update

# Установка Docker и его компонентов
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Проверка статуса Docker
sudo systemctl status docker --no-pager

# Запуск тестового контейнера, чтобы проверить, что Docker работает правильно
sudo docker run hello-world

# Проверка, что Docker работает правильно (опционально)
if sudo docker run hello-world | grep -q "Hello from Docker!"; then
  echo "Docker установлен и работает правильно."
else
  echo "Проблема с установкой Docker."
fi
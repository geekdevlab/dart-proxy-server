#!/bin/bash

# Обновление списка пакетов и установка необходимых зависимостей
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Добавление официального GPG-ключа Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Добавление Docker репозитория в список источников APT
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Обновление списка пакетов еще раз
sudo apt-get update

# Установка Docker
sudo apt-get install -y docker-ce

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
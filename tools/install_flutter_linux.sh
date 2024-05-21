#!/bin/bash

set -e

# Функция для вывода сообщений об ошибке и завершения скрипта
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Обновление пакетов и установка необходимых зависимостей
echo "Обновление пакетов и установка необходимых зависимостей..."
if command -v apt-get > /dev/null; then
    sudo apt-get update || error_exit "Не удалось выполнить обновление пакетов."
    sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa || error_exit "Не удалось установить необходимые зависимости."
elif command -v yum > /dev/null; then
    sudo yum install -y curl git unzip xz-utils zip mesa-libGLU || error_exit "Не удалось установить необходимые зависимости."
else
    error_exit "Не удалось определить менеджер пакетов. Скрипт поддерживает только apt-get и yum."
fi

# Загрузка последней версии Flutter SDK
FLUTTER_VERSION="stable"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.0-stable.tar.xz"
FLUTTER_DIR="$HOME/flutter"

if [ -d "$FLUTTER_DIR" ]; then
    echo "Flutter уже установлен в $FLUTTER_DIR"
else
    echo "Скачивание Flutter SDK с $FLUTTER_URL..."
    curl -L -o flutter.tar.xz $FLUTTER_URL || error_exit "Ошибка при скачивании Flutter SDK. Проверьте URL и соединение с интернетом."

    # Проверка размера скачанного файла
    FILESIZE=$(stat -c%s "flutter.tar.xz")
    echo "Размер скачанного файла: $FILESIZE байт"
    if [ "$FILESIZE" -lt 1000000 ]; then
        error_exit "Файл слишком маленький, вероятно, загрузка прошла неудачно."
    fi

    echo "Распаковка Flutter SDK..."
    mkdir -p flutter_temp
    tar -xf flutter.tar.xz -C flutter_temp || error_exit "Ошибка при распаковке Flutter SDK. Проверьте, что файл flutter.tar.xz не поврежден."
    
    mv flutter_temp/flutter $FLUTTER_DIR
    rm -rf flutter_temp flutter.tar.xz
fi

# Добавление Flutter в PATH для разных оболочек
SHELL_PROFILE=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -n "$FISH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.config/fish/config.fish"
else
    SHELL_PROFILE="$HOME/.profile"
fi

if grep -q "$FLUTTER_DIR/bin" "$SHELL_PROFILE"; then
    echo "Flutter уже добавлен в PATH"
else
    echo "Добавление Flutter в PATH..."
    echo "export PATH=\"\$PATH:$FLUTTER_DIR/bin\"" >> $SHELL_PROFILE
    source $SHELL_PROFILE
fi

# Установка PATH для текущей сессии
export PATH="$PATH:$FLUTTER_DIR/bin"

# Проверка установки Flutter
flutter --version || error_exit "Ошибка при проверке версии Flutter. Убедитесь, что Flutter установлен правильно."

# Запуск flutter doctor для диагностики установки
flutter doctor || error_exit "Ошибка при запуске 'flutter doctor'. Проверьте, что все зависимости установлены правильно."

echo "Установка Flutter завершена. Пожалуйста, перезапустите терминал или выполните 'source $SHELL_PROFILE' для обновления PATH."
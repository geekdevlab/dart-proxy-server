

#!/bin/bash

set -e

# Функция для вывода сообщений об ошибке и завершения скрипта
error_exit() {
    echo "$1" 1>&2
    exit 1
}

PROJECT_DIR="/opt/proxy_server"

# Создание нового Dart проекта
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

cd $PROJECT_DIR || exit

# Инициализация нового проекта Dart
flutter create --template=package .
dart pub get

# Обновление pubspec.yaml для добавления зависимостей
cat <<EOF > pubspec.yaml
name: proxy_server
description: A simple proxy server to OpenAI API.
version: 1.0.0

environment:
  sdk: '>=2.12.0 <3.0.0'

dependencies:
  shelf: ^1.2.0
  http: ^0.13.4

dev_dependencies:
  lints: ^1.0.0
  test: ^1.16.0
EOF

# Установка зависимостей
dart pub get

# Создание серверного файла
mkdir -p bin
cat <<EOF > bin/server.dart
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:http/http.dart' as http;
import 'package:shelf_router/shelf_router.dart';

Future<Response> proxyOpenAI(Request request) async {
  final apiKey = request.headers['Authorization'];
  if (apiKey == null) {
    return Response(400, body: jsonEncode({'error': 'Authorization header is required'}), headers: {
      'Content-Type': 'application/json',
    });
  }

  final payload = await request.readAsString();
  final openaiUrl = 'https://api.openai.com/v1/engines/davinci-codex/completions';

  final openaiResponse = await http.post(
    Uri.parse(openaiUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': apiKey,
    },
    body: payload,
  );

  return Response(
    openaiResponse.statusCode,
    body: openaiResponse.body,
    headers: {
      'Content-Type': 'application/json',
    },
  );
}

void main() async {
  final router = Router();
  router.post('/proxy_openai', proxyOpenAI);

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 8000);
  print('Server listening on port \${server.port}');
}
EOF

# Создание файла для запуска сервера
cat <<EOF > start_server.sh
#!/bin/bash
dart run bin/server.dart
EOF

# Сделать файл start_server.sh исполняемым
chmod +x start_server.sh
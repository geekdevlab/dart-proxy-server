import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Future<Response> proxyRequest(Request request) async {
  final apiKey = request.headers['Authorization'];
  if (apiKey == null) {
    return Response(400,
        body: jsonEncode({'error': 'Authorization header is required'}),
        headers: {
          'Content-Type': 'application/json',
        });
  }

  final payload = await request.readAsString();
  final targetBaseUrl = 'https://api.openai.com/';
  final targetUrl = Uri.parse(targetBaseUrl + request.url.toString());

  final openaiResponse = await http.post(
    targetUrl,
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

Future<Response> healthCheck(Request request) async {
  return Response.ok(jsonEncode({'status': 'ok'}), headers: {
    'Content-Type': 'application/json',
  });
}

void main() async {
  final router = Router();

  router.all('/<path|.*>', proxyRequest);
  router.get('/healthcheck', healthCheck);

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 8000);
  print('Server listening on port ${server.port}');
}

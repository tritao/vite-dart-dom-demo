import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonResponse(
  Object body, {
  int statusCode = 200,
  Map<String, String> headers = const {},
}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {
      'content-type': 'application/json; charset=utf-8',
      ...headers,
    },
  );
}

Response jsonError(
  int statusCode,
  String message, {
  String? code,
  Map<String, Object?>? details,
  Map<String, String> headers = const {},
}) {
  return jsonResponse(
    {
      'error': {
        'message': message,
        if (code != null) 'code': code,
        if (details != null) 'details': details,
      },
    },
    statusCode: statusCode,
    headers: headers,
  );
}

Future<Map<String, Object?>> readJsonObject(Request request) async {
  final text = await request.readAsString();
  if (text.trim().isEmpty) return const {};
  final decoded = jsonDecode(text);
  if (decoded is Map<String, dynamic>) {
    return decoded.cast<String, Object?>();
  }
  throw const FormatException('Expected JSON object');
}

String? getString(Map<String, Object?> json, String key) {
  final v = json[key];
  return v is String ? v : null;
}


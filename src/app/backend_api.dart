import 'dart:convert';

import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

final class BackendApiException implements Exception {
  BackendApiException(this.message, {this.statusCode, this.body});
  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => statusCode == null ? message : 'HTTP $statusCode: $message';
}

final class SolidusBackendApi {
  SolidusBackendApi({required String baseUrl})
      : _client = BrowserClient()..withCredentials = true,
        _baseUrl = baseUrl;

  final BrowserClient _client;
  String _baseUrl;

  String? csrfToken;

  String get baseUrl => _baseUrl;

  set baseUrl(String value) {
    _baseUrl = value.trim().isEmpty ? '/api' : value.trim();
  }

  void close() => _client.close();

  Uri _resolve(String path) {
    final base = _baseUrl.trim().isEmpty ? '/api' : _baseUrl.trim();
    final baseUri = Uri.parse(base.endsWith('/') ? base : '$base/');
    final p = path.startsWith('/') ? path.substring(1) : path;
    return baseUri.resolve(p);
  }

  Future<Map<String, Object?>> getJson(String path) async {
    final res = await _client.get(_resolve(path), headers: {
      'accept': 'application/json',
    });
    return _decodeJson(res);
  }

  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body, {
    bool csrf = false,
  }) async {
    final headers = <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json; charset=utf-8',
    };
    if (csrf) {
      final token = csrfToken;
      if (token == null || token.isEmpty) {
        throw BackendApiException('Missing CSRF token');
      }
      headers['x-csrf-token'] = token;
    }

    final res = await _client.post(
      _resolve(path),
      headers: headers,
      body: jsonEncode(body),
    );
    return _decodeJson(res);
  }

  Map<String, Object?> _decodeJson(http.Response res) {
    final text = utf8.decode(res.bodyBytes);
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    if (!ok) {
      String? message;
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          final err = decoded['error'];
          if (err is Map && err['message'] is String) {
            message = err['message'] as String;
          }
        }
      } catch (_) {}
      if (message != null) {
        throw BackendApiException(message!, statusCode: res.statusCode, body: text);
      }
      throw BackendApiException(
        'Request failed',
        statusCode: res.statusCode,
        body: text,
      );
    }

    if (text.trim().isEmpty) return const {};
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw BackendApiException(
        'Expected JSON object response',
        statusCode: res.statusCode,
        body: text,
      );
    }
    return decoded.cast<String, Object?>();
  }
}

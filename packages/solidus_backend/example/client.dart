import 'dart:convert';
import 'dart:io';

class ApiClient {
  ApiClient(this.baseUri);

  final Uri baseUri;
  final _http = HttpClient();
  final _cookies = <String, String>{};

  String? csrfToken;

  void close() => _http.close(force: true);

  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) {
    return _requestJson(
      'POST',
      path,
      headers: {'content-type': 'application/json', ...headers},
      body: jsonEncode(body),
    );
  }

  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, String> headers = const {},
  }) {
    return _requestJson('GET', path, headers: headers);
  }

  void _applyHeaders(HttpClientRequest req, Map<String, String> headers) {
    if (_cookies.isNotEmpty) {
      req.headers.set(
        'cookie',
        _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
      );
    }
    headers.forEach(req.headers.set);
    req.headers.set('accept', 'application/json');
  }

  void _absorbSetCookies(HttpClientResponse resp) {
    final setCookies = resp.headers[HttpHeaders.setCookieHeader] ?? const <String>[];
    for (final raw in setCookies) {
      final cookie = Cookie.fromSetCookieValue(raw);
      if (cookie.value.isEmpty) {
        _cookies.remove(cookie.name);
      } else {
        _cookies[cookie.name] = cookie.value;
      }
    }
  }

  Future<Map<String, Object?>> _requestJson(
    String method,
    String path, {
    required Map<String, String> headers,
    String? body,
  }) async {
    final uri = baseUri.resolve(path);
    final req = await (method == 'GET' ? _http.getUrl(uri) : _http.openUrl(method, uri));
    _applyHeaders(req, headers);
    if (body != null) req.write(body);
    final resp = await req.close();
    _absorbSetCookies(resp);
    final text = await resp.transform(utf8.decoder).join();
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException('HTTP ${resp.statusCode}: $text');
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw StateError('expected JSON object response');
    return decoded.cast<String, Object?>();
  }
}

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  final base = Uri.parse(_must(parsed, 'base'));
  final email = _must(parsed, 'email');
  final password = _must(parsed, 'password');

  final client = ApiClient(base);
  try {
    final login = await client.postJson('/login', {'email': email, 'password': password});
    client.csrfToken = login['csrfToken'] as String?;
    stdout.writeln('logged in; csrfToken=${client.csrfToken}');

    final tenants = await client.getJson('/tenants');
    final list = (tenants['tenants'] as List).cast<Map>();
    stdout.writeln('tenants: ${list.map((t) => t['slug']).toList()}');

    final slug = (list.first['slug'] as String);
    await client.postJson(
      '/tenants/select',
      {'slug': slug},
      headers: {'x-csrf-token': client.csrfToken ?? ''},
    );
    stdout.writeln('selected tenant: $slug');

    final me = await client.getJson('/t/$slug/me');
    stdout.writeln('tenant me: ${jsonEncode(me)}');
  } finally {
    client.close();
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('--')) continue;
    final key = a.substring(2);
    final value = (i + 1) < args.length ? args[i + 1] : '';
    if (value.startsWith('--')) continue;
    out[key] = value;
    i++;
  }
  return out;
}

String _must(Map<String, String> args, String key) {
  final v = args[key];
  if (v == null || v.isEmpty) {
    stderr.writeln('missing --$key');
    stderr.writeln('usage: dart run example/client.dart --base http://127.0.0.1:8080 --email you@x --password ...');
    exit(2);
  }
  return v;
}

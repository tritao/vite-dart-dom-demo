import 'dart:io';

Map<String, String> parseCookieHeader(String? cookieHeader) {
  if (cookieHeader == null || cookieHeader.trim().isEmpty) return const {};
  final cookies = <String, String>{};
  for (final part in cookieHeader.split(';')) {
    final idx = part.indexOf('=');
    if (idx <= 0) continue;
    final name = part.substring(0, idx).trim();
    final value = part.substring(idx + 1).trim();
    if (name.isEmpty) continue;
    cookies[name] = value;
  }
  return cookies;
}

String buildSetCookie({
  required String name,
  required String value,
  required bool secure,
  required String sameSite, // Lax|Strict|None
  String path = '/',
  String? domain,
  Duration? maxAge,
  bool httpOnly = true,
}) {
  final cookie = Cookie(name, value)
    ..path = path
    ..httpOnly = httpOnly
    ..secure = secure
    ..sameSite = _toSameSite(sameSite);
  if (domain != null && domain.isNotEmpty) cookie.domain = domain;
  if (maxAge != null) cookie.maxAge = maxAge.inSeconds;
  return cookie.toString();
}

String buildClearCookie({
  required String name,
  required bool secure,
  required String sameSite,
  String path = '/',
  String? domain,
}) {
  return buildSetCookie(
    name: name,
    value: '',
    secure: secure,
    sameSite: sameSite,
    path: path,
    domain: domain,
    maxAge: Duration.zero,
  );
}

SameSite _toSameSite(String value) {
  switch (value.toLowerCase()) {
    case 'strict':
      return SameSite.strict;
    case 'none':
      return SameSite.none;
    case 'lax':
    default:
      return SameSite.lax;
  }
}


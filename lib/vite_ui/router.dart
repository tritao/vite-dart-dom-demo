import 'package:web/web.dart' as web;

String? getQueryParam(String key) => Uri.base.queryParameters[key];

bool getQueryFlag(String key, {bool defaultValue = false}) {
  final value = getQueryParam(key);
  if (value == null) return defaultValue;
  return value == '1' || value.toLowerCase() == 'true';
}

void setQueryParam(
  String key,
  String? value, {
  bool replace = true,
}) {
  final current = Uri.base;
  final params = Map<String, String>.from(current.queryParameters);
  if (value == null) {
    params.remove(key);
  } else {
    params[key] = value;
  }

  final next = current.replace(queryParameters: params.isEmpty ? null : params);
  final url = next.toString();

  if (replace) {
    web.window.history.replaceState(null, '', url);
  } else {
    web.window.history.pushState(null, '', url);
  }
}


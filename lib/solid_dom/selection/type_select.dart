import "dart:async";

import "package:web/web.dart" as web;

final class TypeSelect {
  TypeSelect({this.timeout = const Duration(milliseconds: 500)});

  final Duration timeout;
  Timer? _timer;
  String _buffer = "";

  void clear() {
    _buffer = "";
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => clear();

  /// Returns the matching key, or null.
  String? handleKey(
    web.KeyboardEvent e,
    List<String> keys, {
    required String? startKey,
    required bool Function(String key) isDisabled,
    required String Function(String key) textValueForKey,
  }) {
    final key = e.key;
    if (key.length != 1 || e.ctrlKey || e.metaKey || e.altKey) return null;

    _timer?.cancel();
    _buffer += key.toLowerCase();
    _timer = Timer(timeout, clear);

    if (keys.isEmpty) return null;

    var start = 0;
    if (startKey != null) {
      final idx = keys.indexOf(startKey);
      if (idx != -1) start = idx;
    }

    for (var i = 0; i < keys.length; i++) {
      final idx = (start + i) % keys.length;
      final k = keys[idx];
      if (isDisabled(k)) continue;
      final text = textValueForKey(k).trim().toLowerCase();
      if (text.isEmpty) continue;
      if (text.startsWith(_buffer)) return k;
    }
    return null;
  }
}


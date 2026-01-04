import "dart:math";

import "package:web/web.dart" as web;

import "./keyboard_delegate.dart";

final class ListKeyboardDelegate extends KeyboardDelegate {
  ListKeyboardDelegate({
    required this.keys,
    required this.isDisabled,
    required this.textValueForKey,
    required this.getContainer,
    this.getItemElement,
    this.pageSize,
  });

  final List<String> Function() keys;
  final bool Function(String key) isDisabled;
  final String Function(String key) textValueForKey;
  final web.HTMLElement? Function() getContainer;
  final web.HTMLElement? Function(String key)? getItemElement;
  final int Function()? pageSize;

  web.HTMLElement? _itemFor(String key) {
    final custom = getItemElement;
    if (custom != null) return custom(key);
    final c = getContainer();
    if (c == null) return null;
    try {
      return c.querySelector('[data-key="$key"]') as web.HTMLElement?;
    } catch (_) {
      return null;
    }
  }

  String? _firstEnabledFrom(int start, int delta) {
    final list = keys();
    if (list.isEmpty) return null;
    var idx = start;
    while (idx >= 0 && idx < list.length) {
      final key = list[idx];
      if (!isDisabled(key)) return key;
      idx += delta;
    }
    return null;
  }

  @override
  String? getFirstKey([String? key, bool global = false]) =>
      _firstEnabledFrom(0, 1);

  @override
  String? getLastKey([String? key, bool global = false]) {
    final list = keys();
    return _firstEnabledFrom(list.length - 1, -1);
  }

  @override
  String? getKeyBelow(String key) {
    final list = keys();
    final start = list.indexOf(key);
    if (start == -1) return getFirstKey();
    return _firstEnabledFrom(start + 1, 1);
  }

  @override
  String? getKeyAbove(String key) {
    final list = keys();
    final start = list.indexOf(key);
    if (start == -1) return getLastKey();
    return _firstEnabledFrom(start - 1, -1);
  }

  int _fallbackPageStep() {
    try {
      final fromProp = pageSize?.call();
      if (fromProp != null && fromProp > 0) return fromProp;
    } catch (_) {}
    final c = getContainer();
    if (c == null) return 5;
    try {
      final h = c.getBoundingClientRect().height;
      if (h <= 0) return 5;
    } catch (_) {}
    return 5;
  }

  @override
  String? getKeyPageBelow(String key) {
    final list = keys();
    if (list.isEmpty) return null;
    final startIdx = list.indexOf(key);
    if (startIdx == -1) return getFirstKey();

    final container = getContainer();
    final currentEl = _itemFor(key);
    if (container == null || currentEl == null) {
      final nextIdx = min(list.length - 1, startIdx + _fallbackPageStep());
      return _firstEnabledFrom(nextIdx, 1) ?? list.last;
    }

    try {
      final cRect = container.getBoundingClientRect();
      final iRect = currentEl.getBoundingClientRect();
      final targetTop = iRect.top + cRect.height;
      for (var i = startIdx + 1; i < list.length; i++) {
        final k = list[i];
        if (isDisabled(k)) continue;
        final el = _itemFor(k);
        if (el == null) continue;
        final r = el.getBoundingClientRect();
        if (r.top >= targetTop - 1) return k;
      }
      return getLastKey();
    } catch (_) {
      final nextIdx = min(list.length - 1, startIdx + _fallbackPageStep());
      return _firstEnabledFrom(nextIdx, 1) ?? list.last;
    }
  }

  @override
  String? getKeyPageAbove(String key) {
    final list = keys();
    if (list.isEmpty) return null;
    final startIdx = list.indexOf(key);
    if (startIdx == -1) return getLastKey();

    final container = getContainer();
    final currentEl = _itemFor(key);
    if (container == null || currentEl == null) {
      final nextIdx = max(0, startIdx - _fallbackPageStep());
      return _firstEnabledFrom(nextIdx, -1) ?? list.first;
    }

    try {
      final cRect = container.getBoundingClientRect();
      final iRect = currentEl.getBoundingClientRect();
      final targetTop = iRect.top - cRect.height;
      for (var i = startIdx - 1; i >= 0; i--) {
        final k = list[i];
        if (isDisabled(k)) continue;
        final el = _itemFor(k);
        if (el == null) continue;
        final r = el.getBoundingClientRect();
        if (r.top <= targetTop + 1) return k;
      }
      return getFirstKey();
    } catch (_) {
      final nextIdx = max(0, startIdx - _fallbackPageStep());
      return _firstEnabledFrom(nextIdx, -1) ?? list.first;
    }
  }

  @override
  String? getKeyForSearch(String search, [String? fromKey]) {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return null;
    final list = keys();
    if (list.isEmpty) return null;

    var start = 0;
    if (fromKey != null) {
      final idx = list.indexOf(fromKey);
      if (idx != -1) start = (idx + 1) % list.length;
    }

    for (var i = 0; i < list.length; i++) {
      final idx = (start + i) % list.length;
      final key = list[idx];
      if (isDisabled(key)) continue;
      final text = textValueForKey(key).trim().toLowerCase();
      if (text.isEmpty) continue;
      if (text.startsWith(query)) return key;
    }
    return null;
  }
}

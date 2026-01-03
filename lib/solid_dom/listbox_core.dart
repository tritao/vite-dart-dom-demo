import "dart:async";

import "package:web/web.dart" as web;

abstract interface class ListboxItem<T> {
  T get value;
  String get label;
  String get textValue;
  bool get disabled;
  String? get id;
}

bool defaultListboxEquals<T>(T a, T b) => a == b;

int findSelectedIndex<T, O extends ListboxItem<T>>(
  List<O> options,
  T? selected, {
  required bool Function(T a, T b) equals,
}) {
  if (selected == null) return -1;
  for (var i = 0; i < options.length; i++) {
    if (equals(options[i].value, selected)) return i;
  }
  return -1;
}

int firstEnabledIndex<O extends ListboxItem<Object?>>(List<O> options) {
  for (var i = 0; i < options.length; i++) {
    if (!options[i].disabled) return i;
  }
  return -1;
}

int lastEnabledIndex<O extends ListboxItem<Object?>>(List<O> options) {
  for (var i = options.length - 1; i >= 0; i--) {
    if (!options[i].disabled) return i;
  }
  return -1;
}

int nextEnabledIndex<O extends ListboxItem<Object?>>(
  List<O> options,
  int start,
  int delta,
) {
  if (options.isEmpty) return -1;
  if (start < 0) start = 0;
  if (start >= options.length) start = options.length - 1;
  var idx = start;
  for (var i = 0; i < options.length; i++) {
    idx = (idx + delta + options.length) % options.length;
    if (!options[idx].disabled) return idx;
  }
  return start;
}

String optionIdFor<O extends ListboxItem<Object?>>(
  List<O> options,
  String listboxId,
  int index,
) {
  if (index < 0 || index >= options.length) return "$listboxId-opt--1";
  return options[index].id ?? "$listboxId-opt-$index";
}

final class ListboxTypeahead {
  ListboxTypeahead({this.timeout = const Duration(milliseconds: 500)});

  final Duration timeout;
  Timer? _timer;
  String _buffer = "";

  void clear() {
    _buffer = "";
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => clear();

  int? handleKey<O extends ListboxItem<Object?>>(
    web.KeyboardEvent e,
    List<O> options, {
    required int startIndex,
  }) {
    final key = e.key;
    if (key.length != 1 || e.ctrlKey || e.metaKey || e.altKey) return null;

    _timer?.cancel();
    _buffer += key.toLowerCase();
    _timer = Timer(timeout, clear);

    if (options.isEmpty) return null;
    final start = startIndex < 0 ? 0 : startIndex;
    for (var i = 0; i < options.length; i++) {
      final idx = (start + i) % options.length;
      final o = options[idx];
      if (o.disabled) continue;
      final text = o.textValue.trim().toLowerCase();
      if (text.isEmpty) continue;
      if (text.startsWith(_buffer)) return idx;
    }
    return null;
  }
}


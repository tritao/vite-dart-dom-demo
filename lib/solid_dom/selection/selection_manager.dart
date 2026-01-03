import "package:dart_web_test/solid.dart";

import "./types.dart";

final class SelectionManager {
  SelectionManager({
    this.selectionMode = SelectionMode.single,
    this.selectionBehavior = SelectionBehavior.replace,
    this.disallowEmptySelection = false,
    Set<String>? defaultSelectedKeys,
  }) : _selectedKeys = createSignal<Set<String>>(
          {...?defaultSelectedKeys},
          equals: (a, b) => _setEquals(a, b),
        );

  final SelectionMode selectionMode;
  final SelectionBehavior selectionBehavior;
  final bool disallowEmptySelection;

  final Signal<Set<String>> _selectedKeys;
  final _focusedKey = createSignal<String?>(null);
  final _isFocused = createSignal<bool>(false);

  String? _selectionAnchor;

  Set<String> selectedKeys() => _selectedKeys.value;
  String? focusedKey() => _focusedKey.value;
  bool isFocused() => _isFocused.value;

  bool isSelected(String key) => _selectedKeys.value.contains(key);

  void setFocused(bool focused) => _isFocused.value = focused;
  void setFocusedKey(String? key) => _focusedKey.value = key;

  void setSelectedKeys(Iterable<String> keys) {
    if (selectionMode == SelectionMode.none) return;
    final next = {...keys};
    if (disallowEmptySelection && next.isEmpty) return;
    _selectedKeys.value = next;
    _selectionAnchor = next.isEmpty ? null : next.first;
  }

  void clearSelection() {
    if (selectionMode == SelectionMode.none) return;
    if (disallowEmptySelection) return;
    _selectedKeys.value = <String>{};
    _selectionAnchor = null;
  }

  void replaceSelection(String key) {
    if (selectionMode == SelectionMode.none) return;
    _selectedKeys.value = {key};
    _selectionAnchor = key;
  }

  void toggleSelection(String key) {
    if (selectionMode == SelectionMode.none) return;

    if (selectionMode == SelectionMode.single) {
      if (isSelected(key) && !disallowEmptySelection) {
        _selectedKeys.value = <String>{};
        _selectionAnchor = null;
      } else {
        _selectedKeys.value = {key};
        _selectionAnchor = key;
      }
      return;
    }

    final next = {..._selectedKeys.value};
    if (next.contains(key)) {
      if (disallowEmptySelection && next.length == 1) return;
      next.remove(key);
    } else {
      next.add(key);
    }
    _selectedKeys.value = next;
    _selectionAnchor ??= key;
  }

  void extendSelection(String key, List<String> orderedKeys) {
    if (selectionMode != SelectionMode.multiple) {
      replaceSelection(key);
      return;
    }
    final anchor = _selectionAnchor ?? key;
    final a = orderedKeys.indexOf(anchor);
    final b = orderedKeys.indexOf(key);
    if (a == -1 || b == -1) {
      replaceSelection(key);
      return;
    }
    final start = a < b ? a : b;
    final end = a < b ? b : a;
    final next = <String>{};
    for (var i = start; i <= end; i++) {
      next.add(orderedKeys[i]);
    }
    if (disallowEmptySelection && next.isEmpty) return;
    _selectedKeys.value = next;
  }
}

bool _setEquals(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final v in a) {
    if (!b.contains(v)) return false;
  }
  return true;
}


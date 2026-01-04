import "package:dart_web_test/solid.dart";

import "./types.dart";

final class SelectionManager {
  SelectionManager({
    SelectionMode selectionMode = SelectionMode.single,
    SelectionBehavior selectionBehavior = SelectionBehavior.replace,
    bool disallowEmptySelection = false,
    this.orderedKeys,
    bool Function(String key)? isDisabled,
    bool Function(String key)? canSelectItem,
    Set<String>? defaultSelectedKeys,
  })  : _selectionMode = selectionMode,
        _selectionBehavior = selectionBehavior,
        _disallowEmptySelection = disallowEmptySelection,
        _isDisabled = isDisabled,
        _canSelectItem = canSelectItem,
        _selectedKeys = createSignal<Set<String>>(
          {...?defaultSelectedKeys},
          equals: (a, b) => _setEquals(a, b),
        );

  final List<String> Function()? orderedKeys;
  final bool Function(String key)? _isDisabled;
  final bool Function(String key)? _canSelectItem;

  SelectionMode _selectionMode;
  SelectionBehavior _selectionBehavior;
  bool _disallowEmptySelection;

  final Signal<Set<String>> _selectedKeys;
  final _focusedKey = createSignal<String?>(null);
  final _isFocused = createSignal<bool>(false);

  String? _selectionAnchor;
  String? _selectionCurrent;

  Set<String> selectedKeys() => _selectedKeys.value;
  String? focusedKey() => _focusedKey.value;
  bool isFocused() => _isFocused.value;

  SelectionMode selectionMode() => _selectionMode;
  SelectionBehavior selectionBehavior() => _selectionBehavior;
  bool disallowEmptySelection() => _disallowEmptySelection;

  void setSelectionBehavior(SelectionBehavior behavior) {
    _selectionBehavior = behavior;
  }

  bool isEmpty() => _selectedKeys.value.isEmpty;

  bool isSelectAll() {
    final keys = orderedKeys?.call();
    if (keys == null || keys.isEmpty) return false;
    final selected = _selectedKeys.value;
    var any = false;
    for (final k in keys) {
      if (!canSelectItem(k)) continue;
      any = true;
      if (!selected.contains(k)) return false;
    }
    return any;
  }

  String? firstSelectedKey() {
    final keys = orderedKeys?.call();
    if (keys == null || keys.isEmpty) {
      return _selectedKeys.value.isEmpty ? null : _selectedKeys.value.first;
    }
    for (final k in keys) {
      if (_selectedKeys.value.contains(k)) return k;
    }
    return null;
  }

  String? lastSelectedKey() {
    final keys = orderedKeys?.call();
    if (keys == null || keys.isEmpty) {
      return _selectedKeys.value.isEmpty ? null : _selectedKeys.value.last;
    }
    for (var i = keys.length - 1; i >= 0; i--) {
      final k = keys[i];
      if (_selectedKeys.value.contains(k)) return k;
    }
    return null;
  }

  bool isSelected(String key) => _selectedKeys.value.contains(key);

  void setFocused(bool focused) => _isFocused.value = focused;
  void setFocusedKey(String? key) => _focusedKey.value = key;

  bool isDisabled(String key) => _isDisabled?.call(key) ?? false;

  bool canSelectItem(String key) {
    if (isDisabled(key)) return false;
    return _canSelectItem?.call(key) ?? true;
  }

  bool isSelectionEqual(Set<String> other) => _setEquals(_selectedKeys.value, other);

  void setSelectedKeys(Iterable<String> keys) {
    if (selectionMode() == SelectionMode.none) return;
    final next = {...keys};
    if (disallowEmptySelection() && next.isEmpty) return;
    _selectedKeys.value = next;
    final anchor = next.isEmpty
        ? null
        : (orderedKeys != null ? firstSelectedKey() : next.first);
    _selectionAnchor = anchor;
    _selectionCurrent = anchor;
  }

  void clearSelection() {
    if (selectionMode() == SelectionMode.none) return;
    if (disallowEmptySelection()) return;
    _selectedKeys.value = <String>{};
    _selectionAnchor = null;
    _selectionCurrent = null;
  }

  void replaceSelection(String key) {
    if (selectionMode() == SelectionMode.none) return;
    if (!canSelectItem(key)) return;
    _selectedKeys.value = {key};
    _selectionAnchor = key;
    _selectionCurrent = key;
  }

  void toggleSelection(String key) {
    if (selectionMode() == SelectionMode.none) return;
    if (!canSelectItem(key)) return;

    if (selectionMode() == SelectionMode.single) {
      if (isSelected(key) && !disallowEmptySelection()) {
        _selectedKeys.value = <String>{};
        _selectionAnchor = null;
        _selectionCurrent = null;
      } else {
        _selectedKeys.value = {key};
        _selectionAnchor = key;
        _selectionCurrent = key;
      }
      return;
    }

    final next = {..._selectedKeys.value};
    if (next.contains(key)) {
      if (disallowEmptySelection() && next.length == 1) return;
      next.remove(key);
    } else {
      next.add(key);
    }
    _selectedKeys.value = next;
    _selectionAnchor ??= key;
    _selectionCurrent = key;
  }

  void extendSelection(String key) {
    if (selectionMode() != SelectionMode.multiple) {
      replaceSelection(key);
      return;
    }

    final keys = orderedKeys?.call();
    if (keys == null || keys.isEmpty) {
      replaceSelection(key);
      return;
    }

    final toKey = key;
    final anchorKey = _selectionAnchor ?? toKey;
    final currentKey = _selectionCurrent ?? toKey;
    final anchorIndex = keys.indexOf(anchorKey);
    final currentIndex = keys.indexOf(currentKey);
    final toIndex = keys.indexOf(toKey);
    if (anchorIndex == -1 || currentIndex == -1 || toIndex == -1) {
      replaceSelection(toKey);
      return;
    }

    final selection = {..._selectedKeys.value};

    void deleteRange(String a, String b) {
      final start = keys.indexOf(a);
      final end = keys.indexOf(b);
      if (start == -1 || end == -1) return;
      final s = start <= end ? start : end;
      final e = start <= end ? end : start;
      for (var i = s; i <= e; i++) {
        selection.remove(keys[i]);
      }
    }

    void addRange(String a, String b) {
      final start = keys.indexOf(a);
      final end = keys.indexOf(b);
      if (start == -1 || end == -1) return;
      final s = start <= end ? start : end;
      final e = start <= end ? end : start;
      for (var i = s; i <= e; i++) {
        final k = keys[i];
        if (canSelectItem(k)) selection.add(k);
      }
    }

    deleteRange(anchorKey, currentKey);
    addRange(toKey, anchorKey);

    if (disallowEmptySelection() && selection.isEmpty) return;
    _selectedKeys.value = selection;
    _selectionAnchor = anchorKey;
    _selectionCurrent = toKey;
  }

  void selectAll() {
    if (selectionMode() != SelectionMode.multiple) return;
    final keys = orderedKeys?.call();
    if (keys == null || keys.isEmpty) return;
    final next = <String>{};
    for (final k in keys) {
      if (canSelectItem(k)) next.add(k);
    }
    if (disallowEmptySelection() && next.isEmpty) return;
    _selectedKeys.value = next;
    _selectionAnchor = firstSelectedKey();
    _selectionCurrent = _selectionAnchor;
  }

  void toggleSelectAll() {
    if (isSelectAll()) {
      clearSelection();
    } else {
      selectAll();
    }
  }

  void select(
    String key, {
    required bool shiftKey,
    required bool toggleKey,
    required bool isTouch,
  }) {
    if (selectionMode() == SelectionMode.none) return;

    if (selectionMode() == SelectionMode.single) {
      if (isSelected(key) && !disallowEmptySelection()) {
        toggleSelection(key);
      } else {
        replaceSelection(key);
      }
      return;
    }

    if (shiftKey) {
      extendSelection(key);
      return;
    }

    if (selectionBehavior() == SelectionBehavior.toggle || toggleKey || isTouch) {
      toggleSelection(key);
      return;
    }

    replaceSelection(key);
  }

  void setSelectionMode(SelectionMode mode) {
    _selectionMode = mode;
    if (mode == SelectionMode.none) {
      clearSelection();
      return;
    }
    if (mode == SelectionMode.single && _selectedKeys.value.length > 1) {
      replaceSelection(firstSelectedKey() ?? _selectedKeys.value.first);
    }
  }

  void setDisallowEmptySelection(bool disallow) {
    _disallowEmptySelection = disallow;
    if (disallow && _selectedKeys.value.isEmpty) {
      final keys = orderedKeys?.call();
      if (keys != null) {
        for (final k in keys) {
          if (canSelectItem(k)) {
            replaceSelection(k);
            break;
          }
        }
      }
    }
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

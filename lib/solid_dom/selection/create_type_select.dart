import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./keyboard_delegate.dart";
import "./selection_manager.dart";
import "./utils.dart";

final class TypeSelectHandlers {
  TypeSelectHandlers({required this.onKeyDown});
  final void Function(web.KeyboardEvent e) onKeyDown;
}

final class TypeSelect {
  TypeSelect({required this.typeSelectHandlers});
  final TypeSelectHandlers typeSelectHandlers;
}

TypeSelect createTypeSelect({
  required bool Function() isDisabled,
  required KeyboardDelegate Function() keyboardDelegate,
  required SelectionManager Function() selectionManager,
  void Function(String key)? onTypeSelect,
}) {
  Timer? timer;
  var search = "";

  void clear() {
    search = "";
    timer?.cancel();
    timer = null;
  }

  onCleanup(clear);

  void onKeyDown(web.KeyboardEvent e) {
    if (isDisabled()) return;
    final delegate = keyboardDelegate();
    final manager = selectionManager();

    final character = typeaheadCharForKey(e.key);
    if (character == null || e.ctrlKey || e.metaKey) return;

    if (character == " " && search.trim().isNotEmpty) {
      e.preventDefault();
      e.stopPropagation();
    }

    search = "$search$character";

    String? key = delegate.getKeyForSearch(search, manager.focusedKey()) ??
        delegate.getKeyForSearch(search);

    if (key == null && isAllSameLetter(search)) {
      search = search[0];
      key = delegate.getKeyForSearch(search, manager.focusedKey()) ??
          delegate.getKeyForSearch(search);
    }

    if (key != null) {
      manager.setFocusedKey(key);
      onTypeSelect?.call(key);
    }

    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 500), clear);
  }

  return TypeSelect(typeSelectHandlers: TypeSelectHandlers(onKeyDown: onKeyDown));
}

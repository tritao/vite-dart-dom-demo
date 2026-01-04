import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "../solid_dom.dart";
import "./selection_manager.dart";
import "./types.dart";
import "./utils.dart";

final class SelectableItemResult {
  SelectableItemResult({
    required this.isSelected,
    required this.isDisabled,
    required this.allowsSelection,
    required this.tabIndex,
    required this.dataKey,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onClick,
    required this.onKeyDown,
    required this.onMouseDown,
    required this.onFocus,
  });

  final bool Function() isSelected;
  final bool Function() isDisabled;
  final bool Function() allowsSelection;
  final int? Function() tabIndex;
  final String? Function() dataKey;

  final void Function(web.PointerEvent e) onPointerDown;
  final void Function(web.PointerEvent e) onPointerUp;
  final void Function(web.MouseEvent e) onClick;
  final void Function(web.KeyboardEvent e) onKeyDown;
  final void Function(web.MouseEvent e) onMouseDown;
  final void Function(web.FocusEvent e) onFocus;

  void attach(web.HTMLElement el) {
    // Bind tabIndex; omit the attribute entirely when null (virtual focus).
    createRenderEffect(() {
      final ti = tabIndex();
      if (ti == null) {
        el.removeAttribute("tabindex");
      } else {
        el.tabIndex = ti;
      }
    });
    attr(el, "data-key", dataKey);

    on(el, "pointerdown", (e) {
      if (e is web.PointerEvent) onPointerDown(e);
    });
    on(el, "pointerup", (e) {
      if (e is web.PointerEvent) onPointerUp(e);
    });
    on(el, "click", (e) {
      if (e is web.MouseEvent) onClick(e);
    });
    on(el, "keydown", (e) {
      if (e is web.KeyboardEvent) onKeyDown(e);
    });
    on(el, "mousedown", (e) {
      if (e is web.MouseEvent) onMouseDown(e);
    });
    on(el, "focus", (e) {
      if (e is web.FocusEvent) onFocus(e);
    });
  }
}

SelectableItemResult createSelectableItem({
  required SelectionManager Function() selectionManager,
  required String Function() key,
  required web.HTMLElement? Function() ref,
  bool Function()? shouldSelectOnPressUp,
  bool Function()? shouldUseVirtualFocus,
  bool Function()? allowsDifferentPressOrigin,
  bool Function()? virtualized,
  bool Function()? disabled,
  void Function()? focus,
}) {
  final shouldUseVirtualFocusAccessor = shouldUseVirtualFocus ?? () => false;
  final shouldSelectOnPressUpAccessor = shouldSelectOnPressUp ?? () => false;
  final allowsDifferentPressOriginAccessor =
      allowsDifferentPressOrigin ?? () => false;
  final virtualizedAccessor = virtualized ?? () => false;
  final disabledAccessor = disabled ?? () => false;

  final manager = selectionManager;

  void onSelect(Object e) {
    final m = manager();
    if (m.selectionMode() == SelectionMode.none) return;

    final k = key();
    if (m.selectionMode() == SelectionMode.single) {
      if (m.isSelected(k) && !m.disallowEmptySelection()) {
        m.toggleSelection(k);
      } else {
        m.replaceSelection(k);
      }
      return;
    }

    final shiftKey = switch (e) {
      web.KeyboardEvent ev => ev.shiftKey,
      web.MouseEvent ev => ev.shiftKey,
      web.PointerEvent ev => ev.shiftKey,
      _ => false,
    };

    if (shiftKey) {
      m.extendSelection(k);
      return;
    }

    var isTouch = false;
    if (e is web.PointerEvent) {
      try {
        isTouch = e.pointerType == "touch";
      } catch (_) {
        isTouch = false;
      }
    }
    final toggleKey = isCtrlKeyPressed(e) || isTouch;

    if (m.selectionBehavior() == SelectionBehavior.toggle || toggleKey) {
      m.toggleSelection(k);
    } else {
      m.replaceSelection(k);
    }
  }

  bool isSelected() => manager().isSelected(key());

  bool isDisabled() => disabledAccessor() || manager().isDisabled(key());

  bool allowsSelection() => !isDisabled() && manager().canSelectItem(key());

  String? pointerDownType;

  void onPointerDown(web.PointerEvent e) {
    if (!allowsSelection()) return;
    pointerDownType = e.pointerType;

    if (e.pointerType == "mouse" &&
        e.button == 0 &&
        !shouldSelectOnPressUpAccessor()) {
      onSelect(e);
    }
  }

  void onPointerUp(web.PointerEvent e) {
    if (!allowsSelection()) return;
    if (e.pointerType == "mouse" &&
        e.button == 0 &&
        shouldSelectOnPressUpAccessor() &&
        allowsDifferentPressOriginAccessor()) {
      onSelect(e);
    }
  }

  void onClick(web.MouseEvent e) {
    if (!allowsSelection()) return;
    final type = pointerDownType;
    final isMouse = type == "mouse";
    if ((shouldSelectOnPressUpAccessor() &&
            !allowsDifferentPressOriginAccessor()) ||
        !isMouse) {
      onSelect(e);
    }
  }

  void onKeyDown(web.KeyboardEvent e) {
    if (!allowsSelection()) return;
    if (e.key != "Enter" && e.key != " ") return;

    if (isNonContiguousSelectionModifier(e)) {
      manager().toggleSelection(key());
    } else {
      onSelect(e);
    }
  }

  void onMouseDown(web.MouseEvent e) {
    if (isDisabled()) {
      // Prevent focus going to the body when clicking on a disabled item.
      e.preventDefault();
    }
  }

  void onFocus(web.FocusEvent e) {
    final el = ref();
    if (shouldUseVirtualFocusAccessor() || isDisabled() || el == null) return;
    if (identical(e.target, el)) {
      manager().setFocusedKey(key());
    }
  }

  final tabIndexMemo = createMemo<int?>(() {
    if (shouldUseVirtualFocusAccessor() || isDisabled()) return null;
    return key() == manager().focusedKey() ? 0 : -1;
  });

  final dataKeyMemo = createMemo<String?>(() {
    return virtualizedAccessor() ? null : key();
  });

  // Focus the associated DOM node when this item becomes the focusedKey.
  createEffect(() {
    final el = ref();
    final k = key();
    final focusedKey = manager().focusedKey();
    final isFocused = manager().isFocused();
    final useVirtual = shouldUseVirtualFocusAccessor();

    if (el == null ||
        k != focusedKey ||
        !isFocused ||
        useVirtual ||
        web.document.activeElement == el) {
      return;
    }

    if (focus != null) {
      focus();
    } else {
      focusWithoutScrolling(el);
    }
  });

  return SelectableItemResult(
    isSelected: isSelected,
    isDisabled: isDisabled,
    allowsSelection: allowsSelection,
    tabIndex: () => tabIndexMemo.value,
    dataKey: () => dataKeyMemo.value,
    onPointerDown: onPointerDown,
    onPointerUp: onPointerUp,
    onClick: onClick,
    onKeyDown: onKeyDown,
    onMouseDown: onMouseDown,
    onFocus: onFocus,
  );
}

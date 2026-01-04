import "dart:async";
import "dart:js_interop";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "../solid_dom.dart";
import "./create_type_select.dart";
import "./keyboard_delegate.dart";
import "./selection_manager.dart";
import "./types.dart";
import "./utils.dart";

final class SelectableCollectionResult {
  SelectableCollectionResult({
    required this.tabIndex,
    required this.onKeyDown,
    required this.onMouseDown,
    required this.onFocusIn,
    required this.onFocusOut,
  });

  final int? Function() tabIndex;
  final void Function(web.KeyboardEvent e) onKeyDown;
  final void Function(web.MouseEvent e) onMouseDown;
  final void Function(web.FocusEvent e) onFocusIn;
  final void Function(web.FocusEvent e) onFocusOut;

  void attach(
    web.HTMLElement el, {
    web.HTMLElement? scrollEl,
  }) {
    createRenderEffect(() {
      final ti = tabIndex();
      if (ti == null) {
        el.removeAttribute("tabindex");
      } else {
        el.tabIndex = ti;
      }
    });

    on(el, "keydown", (e) {
      if (e is web.KeyboardEvent) onKeyDown(e);
    });
    on(el, "mousedown", (e) {
      if (e is web.MouseEvent) onMouseDown(e);
    });
    on(el, "focusin", (e) {
      if (e is web.FocusEvent) onFocusIn(e);
    });
    on(el, "focusout", (e) {
      if (e is web.FocusEvent) onFocusOut(e);
    });
  }
}

SelectableCollectionResult createSelectableCollection({
  required SelectionManager Function() selectionManager,
  required KeyboardDelegate Function() keyboardDelegate,
  required web.HTMLElement? Function() ref,
  web.HTMLElement? Function()? scrollRef,
  FocusStrategy? Function()? autoFocus,
  bool Function()? deferAutoFocus,
  bool Function()? shouldFocusWrap,
  bool Function()? disallowEmptySelection,
  bool Function()? disallowSelectAll,
  bool Function()? selectOnFocus,
  bool Function()? disallowTypeAhead,
  bool Function()? shouldUseVirtualFocus,
  bool Function()? allowsTabNavigation,
  bool Function()? isVirtualized,
  void Function(String key)? scrollToKey,
  Orientation Function()? orientation,
  bool Function()? isRtl,
}) {
  final managerAccessor = selectionManager;
  final delegateAccessor = keyboardDelegate;
  final refAccessor = ref;
  final scrollRefAccessor = scrollRef ?? ref;

  final shouldFocusWrapAccessor = shouldFocusWrap ?? () => false;
  final disallowEmptySelectionAccessor = disallowEmptySelection ?? () => false;
  final disallowSelectAllAccessor = disallowSelectAll ?? () => false;
  final disallowTypeAheadAccessor = disallowTypeAhead ?? () => false;
  final shouldUseVirtualFocusAccessor = shouldUseVirtualFocus ?? () => false;
  final allowsTabNavigationAccessor = allowsTabNavigation ?? () => false;
  final isVirtualizedAccessor = isVirtualized ?? () => false;
  final orientationAccessor = orientation ?? () => Orientation.vertical;
  final isRtlAccessor = isRtl ?? () => false;

  bool selectOnFocusDefault() =>
      managerAccessor().selectionBehavior() == SelectionBehavior.replace;
  final selectOnFocusAccessor = selectOnFocus ?? selectOnFocusDefault;

  var scrollPosTop = 0.0;
  var scrollPosLeft = 0.0;

  void onScroll() {
    if (isVirtualizedAccessor()) return;
    final scrollEl = scrollRefAccessor();
    if (scrollEl == null) return;
    scrollPosTop = scrollEl.scrollTop;
    scrollPosLeft = scrollEl.scrollLeft;
  }

  web.HTMLElement? _prevScrollEl;
  JSFunction? _jsScroll;

  void _detachScroll() {
    final el = _prevScrollEl;
    final fn = _jsScroll;
    if (el != null && fn != null) {
      el.removeEventListener("scroll", fn);
    }
    _prevScrollEl = null;
    _jsScroll = null;
  }

  createEffect(() {
    final el = scrollRefAccessor();
    final virtual = isVirtualizedAccessor();
    if (identical(el, _prevScrollEl)) return;
    _detachScroll();
    if (el == null || virtual) return;
    _prevScrollEl = el;
    _jsScroll = ((web.Event _) => onScroll()).toJS;
    el.addEventListener("scroll", _jsScroll!);
  });

  onCleanup(_detachScroll);

  // Type select mirrors Kobalte: delegate.getKeyForSearch drives focusedKey.
  final typeSelect = createTypeSelect(
    isDisabled: disallowTypeAheadAccessor,
    keyboardDelegate: delegateAccessor,
    selectionManager: managerAccessor,
  );
  onCleanup(() {
    // Timer cleanup is internal to createTypeSelect.
  });

  void onKeyDown(web.KeyboardEvent e) {
    typeSelect.typeSelectHandlers.onKeyDown(e);

    if (e.altKey && e.key == "Tab") {
      e.preventDefault();
    }

    final root = refAccessor();
    if (root == null) return;
    final target = e.target;
    if (target is web.Node && !root.contains(target)) return;

    final manager = managerAccessor();
    final delegate = delegateAccessor();
    final focusedKey = manager.focusedKey();
    final focusWrap = shouldFocusWrapAccessor();
    final isVertical = orientationAccessor() == Orientation.vertical;

    void navigateToKey(String? nextKey) {
      if (nextKey == null) return;
      manager.setFocusedKey(nextKey);
      if (e.shiftKey && manager.selectionMode() == SelectionMode.multiple) {
        manager.extendSelection(nextKey);
      } else if (selectOnFocusAccessor() && !isNonContiguousSelectionModifier(e)) {
        manager.replaceSelection(nextKey);
      }
    }

    if ((isVertical && e.key == "ArrowDown") || (!isVertical && e.key == "ArrowRight")) {
      e.preventDefault();
      String? nextKey;
      if (focusedKey != null) {
        nextKey = delegate.getKeyBelow(focusedKey);
      } else {
        nextKey = delegate.getFirstKey();
      }
      if (nextKey == null && focusWrap) {
        nextKey = delegate.getFirstKey(focusedKey);
      }
      navigateToKey(nextKey);
      return;
    }

    if ((isVertical && e.key == "ArrowUp") || (!isVertical && e.key == "ArrowLeft")) {
      e.preventDefault();
      String? nextKey;
      if (focusedKey != null) {
        nextKey = delegate.getKeyAbove(focusedKey);
      } else {
        nextKey = delegate.getLastKey();
      }
      if (nextKey == null && focusWrap) {
        nextKey = delegate.getLastKey(focusedKey);
      }
      navigateToKey(nextKey);
      return;
    }

    if ((isVertical && e.key == "ArrowLeft") || (!isVertical && e.key == "ArrowUp")) {
      e.preventDefault();
      final rtl = isRtlAccessor();
      String? nextKey;
      if (focusedKey != null) {
        nextKey = delegate.getKeyLeftOf(focusedKey);
      } else {
        nextKey = rtl ? delegate.getFirstKey() : delegate.getLastKey();
      }
      navigateToKey(nextKey);
      return;
    }

    if ((isVertical && e.key == "ArrowRight") || (!isVertical && e.key == "ArrowDown")) {
      e.preventDefault();
      final rtl = isRtlAccessor();
      String? nextKey;
      if (focusedKey != null) {
        nextKey = delegate.getKeyRightOf(focusedKey);
      } else {
        nextKey = rtl ? delegate.getLastKey() : delegate.getFirstKey();
      }
      navigateToKey(nextKey);
      return;
    }

    switch (e.key) {
      case "Home":
        e.preventDefault();
        final firstKey = delegate.getFirstKey(focusedKey, isCtrlKeyPressed(e));
        if (firstKey != null) {
          manager.setFocusedKey(firstKey);
          if (isCtrlKeyPressed(e) &&
              e.shiftKey &&
              manager.selectionMode() == SelectionMode.multiple) {
            manager.extendSelection(firstKey);
          } else if (selectOnFocusAccessor()) {
            manager.replaceSelection(firstKey);
          }
        }
        break;
      case "End":
        e.preventDefault();
        final lastKey = delegate.getLastKey(focusedKey, isCtrlKeyPressed(e));
        if (lastKey != null) {
          manager.setFocusedKey(lastKey);
          if (isCtrlKeyPressed(e) &&
              e.shiftKey &&
              manager.selectionMode() == SelectionMode.multiple) {
            manager.extendSelection(lastKey);
          } else if (selectOnFocusAccessor()) {
            manager.replaceSelection(lastKey);
          }
        }
        break;
      case "PageDown":
        if (focusedKey != null) {
          e.preventDefault();
          navigateToKey(delegate.getKeyPageBelow(focusedKey));
        }
        break;
      case "PageUp":
        if (focusedKey != null) {
          e.preventDefault();
          navigateToKey(delegate.getKeyPageAbove(focusedKey));
        }
        break;
      case "a":
        if (isCtrlKeyPressed(e) &&
            manager.selectionMode() == SelectionMode.multiple &&
            disallowSelectAllAccessor() != true) {
          e.preventDefault();
          manager.selectAll();
        }
        break;
      case "Escape":
        if (!e.defaultPrevented) {
          e.preventDefault();
          if (!disallowEmptySelectionAccessor()) {
            manager.clearSelection();
          }
        }
        break;
      case "Tab":
        if (!allowsTabNavigationAccessor()) {
          if (e.shiftKey) {
            root.focus();
          } else {
            // Focus the last tabbable element in the collection so default tabbing continues from there.
            final nodes = root.querySelectorAll(
              'a[href],button,input,select,textarea,[tabindex]:not([tabindex="-1"])',
            );
            web.HTMLElement? next;
            for (var i = 0; i < nodes.length; i++) {
              final n = nodes.item(i);
              if (n is! web.HTMLElement) continue;
              if (n.tabIndex < 0) continue;
              final disabled = (n is web.HTMLButtonElement && n.disabled) ||
                  (n is web.HTMLInputElement && n.disabled) ||
                  (n is web.HTMLSelectElement && n.disabled) ||
                  (n is web.HTMLTextAreaElement && n.disabled);
              if (disabled) continue;
              next = n;
            }
            final active = web.document.activeElement;
            if (next != null &&
                !(active is web.Node && next.contains(active))) {
              focusWithoutScrolling(next);
            }
          }
        }
        break;
    }
  }

  void onFocusIn(web.FocusEvent e) {
    final manager = managerAccessor();
    final delegate = delegateAccessor();

    if (manager.isFocused()) {
      final currentTarget = e.currentTarget;
      final target = e.target;
      if (currentTarget is web.Node && target is web.Node) {
        if (!currentTarget.contains(target)) {
          manager.setFocused(false);
        }
      }
      return;
    }

    final currentTarget = e.currentTarget;
    final target = e.target;
    if (currentTarget is web.Node && target is web.Node) {
      if (!currentTarget.contains(target)) return;
    }

    manager.setFocused(true);

    if (manager.focusedKey() == null) {
      void navigateToFirstKey(String? k) {
        if (k == null) return;
        manager.setFocusedKey(k);
        if (selectOnFocusAccessor()) {
          manager.replaceSelection(k);
        }
      }

      final related = e.relatedTarget;
      if (related is web.Node && currentTarget is web.Node) {
        final pos = currentTarget.compareDocumentPosition(related);
        // Node.DOCUMENT_POSITION_FOLLOWING === 4
        if ((pos & 4) != 0) {
          navigateToFirstKey(manager.lastSelectedKey() ?? delegate.getLastKey());
          return;
        }
      }
      navigateToFirstKey(manager.firstSelectedKey() ?? delegate.getFirstKey());
      return;
    }

    if (!isVirtualizedAccessor()) {
      final scrollEl = scrollRefAccessor();
      if (scrollEl != null) {
        scrollEl.scrollTop = scrollPosTop;
        scrollEl.scrollLeft = scrollPosLeft;
        final focusedKey = manager.focusedKey();
        if (focusedKey != null) {
          final node =
              scrollEl.querySelector('[data-key="$focusedKey"]') as web.HTMLElement?;
          if (node != null) {
            focusWithoutScrolling(node);
            scrollIntoViewWithin(scrollEl, node);
          }
        }
      }
    }
  }

  void onFocusOut(web.FocusEvent e) {
    final manager = managerAccessor();
    final currentTarget = e.currentTarget;
    final related = e.relatedTarget;
    if (currentTarget is web.Node && related is web.Node) {
      if (!currentTarget.contains(related)) {
        manager.setFocused(false);
      }
      return;
    }
    manager.setFocused(false);
  }

  void onMouseDown(web.MouseEvent e) {
    // Prevent focus going to the collection when clicking on the scrollbar.
    final scrollEl = scrollRefAccessor();
    if (scrollEl != null && identical(scrollEl, e.target)) {
      e.preventDefault();
    }
  }

  void tryAutoFocus() {
    final strategy = autoFocus?.call();
    if (strategy == null) return;

    final manager = managerAccessor();
    final delegate = delegateAccessor();

    String? focusedKey;
    if (strategy == FocusStrategy.first) {
      focusedKey = delegate.getFirstKey();
    } else if (strategy == FocusStrategy.last) {
      focusedKey = delegate.getLastKey();
    }

    final selectedKeys = manager.selectedKeys();
    if (selectedKeys.isNotEmpty) {
      // Pick the first selected key in visual order when possible.
      focusedKey = manager.firstSelectedKey() ?? selectedKeys.first;
    }

    manager.setFocused(true);
    manager.setFocusedKey(focusedKey);

    final root = refAccessor();
    if (root != null &&
        focusedKey == null &&
        !shouldUseVirtualFocusAccessor()) {
      focusWithoutScrolling(root);
    }
  }

  void scheduleAutoFocusWhenConnected() {
    final root = refAccessor();
    if (root == null) return;
    if (!root.isConnected) {
      scheduleMicrotask(scheduleAutoFocusWhenConnected);
      return;
    }
    if (deferAutoFocus?.call() == true) {
      Timer(const Duration(milliseconds: 0), tryAutoFocus);
    } else {
      tryAutoFocus();
    }
  }

  scheduleMicrotask(scheduleAutoFocusWhenConnected);

  // Scroll focused item into view when focusedKey changes.
  createEffect(() {
    final scrollEl = scrollRefAccessor();
    final focusedKey = managerAccessor().focusedKey();
    final virtual = isVirtualizedAccessor();

    if (focusedKey == null) return;

    if (virtual) {
      scrollToKey?.call(focusedKey);
      return;
    }

    if (scrollEl == null) return;
    final node =
        scrollEl.querySelector('[data-key="$focusedKey"]') as web.HTMLElement?;
    if (node != null) scrollIntoViewWithin(scrollEl, node);
  });

  final tabIndexMemo = createMemo<int?>(() {
    // In virtual focus mode, the collection itself should stay programmatically
    // focusable (e.g. Select listbox), but should not be tabbable by default.
    if (shouldUseVirtualFocusAccessor()) return -1;
    return managerAccessor().focusedKey() == null ? 0 : -1;
  });

  return SelectableCollectionResult(
    tabIndex: () => tabIndexMemo.value,
    onKeyDown: onKeyDown,
    onMouseDown: onMouseDown,
    onFocusIn: onFocusIn,
    onFocusOut: onFocusOut,
  );
}

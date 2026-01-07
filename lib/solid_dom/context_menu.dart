import "dart:async";
import "dart:js_util" as js_util;

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./focus_scope.dart";
import "./menu.dart";
import "./solid_dom.dart";
import "./selection/utils.dart";

String _documentDirection() {
  try {
    final html = web.document.documentElement;
    final dir = html?.getAttribute("dir") ?? web.document.dir;
    return (dir ?? "").toLowerCase() == "rtl" ? "rtl" : "ltr";
  } catch (_) {
    return "ltr";
  }
}

double _mouseClientX(web.MouseEvent e) {
  try {
    final v = js_util.getProperty(e, "clientX");
    return (v as num).toDouble();
  } catch (_) {
    return 0;
  }
}

double _mouseClientY(web.MouseEvent e) {
  try {
    final v = js_util.getProperty(e, "clientY");
    return (v as num).toDouble();
  } catch (_) {
    return 0;
  }
}

double _pointerClientX(web.PointerEvent e) {
  try {
    final v = js_util.getProperty(e, "clientX");
    return (v as num).toDouble();
  } catch (_) {
    return 0;
  }
}

double _pointerClientY(web.PointerEvent e) {
  try {
    final v = js_util.getProperty(e, "clientY");
    return (v as num).toDouble();
  } catch (_) {
    return 0;
  }
}

bool _isTouchOrPen(web.PointerEvent e) =>
    e.pointerType == "touch" || e.pointerType == "pen";

/// ContextMenu wrapper (Kobalte-style) built on [Menu].
///
/// Opens at the pointer location on right click (`contextmenu`) and on touch
/// long-press (~700ms).
web.DocumentFragment ContextMenu({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required web.Element target,
  required MenuBuilder builder,
  bool disabled = false,
  void Function(String reason)? onClose,
  void Function(FocusScopeAutoFocusEvent event)? onOpenAutoFocus,
  void Function(FocusScopeAutoFocusEvent event)? onCloseAutoFocus,
  int exitMs = 120,
  String? portalId,
}) {
  final anchor = web.HTMLDivElement()
    ..setAttribute("data-solid-contextmenu-anchor", "1");
  anchor.style
    ..position = "fixed"
    ..left = "0"
    ..top = "0"
    ..width = "0"
    ..height = "0"
    ..pointerEvents = "none";

  // Ensure the anchor is connected so Popper can compute its rect.
  web.document.body?.appendChild(anchor);
  onCleanup(() {
    try {
      anchor.remove();
    } catch (_) {}
  });

  if (target is web.HTMLElement) {
    // Prevent iOS context menu from appearing on long press.
    try {
      target.style.setProperty("-webkit-touch-callout", "none");
    } catch (_) {}
  }

  var lastX = 0.0;
  var lastY = 0.0;

  void setAnchorAt(double x, double y) {
    lastX = x;
    lastY = y;
    anchor.style.left = "${x.toStringAsFixed(0)}px";
    anchor.style.top = "${y.toStringAsFixed(0)}px";
  }

  Timer? longPressTimer;
  void clearLongPress() {
    longPressTimer?.cancel();
    longPressTimer = null;
  }

  // Keep a pointer to the latest mounted menu element so we can focus it when
  // opening via contextmenu while already open.
  web.HTMLElement? currentMenuEl;

  final wrappedBuilder = (MenuCloseController close) {
    final built = builder(close);
    currentMenuEl = built.element;
    return built;
  };

  var nextOpenShouldAutoFocus = true;

  void openAt(double x, double y, {required bool focusMenu}) {
    setAnchorAt(x, y);
    if (open()) {
      if (focusMenu && currentMenuEl != null) {
        focusWithoutScrolling(currentMenuEl!);
      }
      return;
    }
    setOpen(true);
  }

  // Right click.
  void onContextMenu(web.Event e) {
    if (disabled) return;
    if (e is! web.MouseEvent) return;
    clearLongPress();
    e.preventDefault();
    e.stopPropagation();
    nextOpenShouldAutoFocus = true;
    openAt(_mouseClientX(e), _mouseClientY(e), focusMenu: true);
  }

  void onPointerDown(web.Event e) {
    if (disabled) return;
    if (e is! web.PointerEvent) return;
    if (!_isTouchOrPen(e)) return;
    clearLongPress();
    setAnchorAt(_pointerClientX(e), _pointerClientY(e));
    longPressTimer = Timer(const Duration(milliseconds: 700), () {
      // Kobalte opens with focusStrategy=false for long press.
      nextOpenShouldAutoFocus = false;
      openAt(lastX, lastY, focusMenu: false);
    });
  }

  void onPointerMove(web.Event e) {
    if (disabled) return;
    if (e is! web.PointerEvent) return;
    if (_isTouchOrPen(e)) clearLongPress();
  }

  void onPointerCancel(web.Event e) {
    if (disabled) return;
    if (e is! web.PointerEvent) return;
    if (_isTouchOrPen(e)) clearLongPress();
  }

  void onPointerUp(web.Event e) {
    if (disabled) return;
    if (e is! web.PointerEvent) return;
    if (_isTouchOrPen(e)) clearLongPress();
  }

  on(target, "contextmenu", onContextMenu);
  on(target, "pointerdown", onPointerDown);
  on(target, "pointermove", onPointerMove);
  on(target, "pointercancel", onPointerCancel);
  on(target, "pointerup", onPointerUp);
  onCleanup(clearLongPress);

  // Default placement mirrors Kobalte: rtl -> left-start, else right-start.
  final placement = _documentDirection() == "rtl" ? "left-start" : "right-start";

  return Menu(
    open: open,
    setOpen: setOpen,
    anchor: anchor,
    builder: wrappedBuilder,
    restoreFocusTo: target is web.HTMLElement ? target as web.HTMLElement : null,
    onClose: onClose,
    onOpenAutoFocus: (e) {
      onOpenAutoFocus?.call(e);
      if (!nextOpenShouldAutoFocus) {
        e.preventDefault();
      }
      nextOpenShouldAutoFocus = true;
    },
    onCloseAutoFocus: onCloseAutoFocus,
    exitMs: exitMs,
    placement: placement,
    offset: 2,
    viewportPadding: 8,
    flip: true,
    modal: false,
    portalId: portalId,
  );
}

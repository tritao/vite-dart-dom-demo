import "dart:async";
import "dart:js_interop";
import "dart:js_util" as js_util;

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./solid_dom.dart";

final class FloatingHandle {
  FloatingHandle._(this._dispose);
  final void Function() _dispose;
  void dispose() => _dispose();
}

void _setPx(web.HTMLElement el, String prop, double value) {
  el.style.setProperty(prop, "${value.toStringAsFixed(2)}px");
}

double _clampSafe(double value, double min, double max) {
  if (max < min) return min;
  return value.clamp(min, max);
}

void _positionFixed({
  required web.Element anchor,
  required web.HTMLElement floating,
  required String placement,
  required double offset,
  required double viewportPadding,
  required bool flip,
}) {
  final a = anchor.getBoundingClientRect();
  final f = floating.getBoundingClientRect();

  final viewportWidth = web.window.innerWidth.toDouble();
  final viewportHeight = web.window.innerHeight.toDouble();

  String effective = placement;
  if (flip) {
    if (placement.startsWith("bottom") &&
        a.bottom + offset + f.height > viewportHeight) {
      effective = placement.replaceFirst("bottom", "top");
    } else if (placement.startsWith("top") && a.top - offset - f.height < 0) {
      effective = placement.replaceFirst("top", "bottom");
    } else if (placement.startsWith("right") &&
        a.right + offset + f.width > viewportWidth) {
      effective = placement.replaceFirst("right", "left");
    } else if (placement.startsWith("left") && a.left - offset - f.width < 0) {
      effective = placement.replaceFirst("left", "right");
    }
  }

  final parts = effective.split("-");
  final side = parts.first;
  final align = parts.length > 1 ? parts[1] : "center";

  double left = 0;
  double top = 0;

  double alignX() {
    switch (align) {
      case "start":
        return a.left;
      case "end":
        return a.right - f.width;
      default:
        return a.left + (a.width - f.width) / 2;
    }
  }

  double alignY() {
    switch (align) {
      case "start":
        return a.top;
      case "end":
        return a.bottom - f.height;
      default:
        return a.top + (a.height - f.height) / 2;
    }
  }

  switch (side) {
    case "top":
      left = alignX();
      top = a.top - f.height - offset;
      break;
    case "right":
      left = a.right + offset;
      top = alignY();
      break;
    case "left":
      left = a.left - f.width - offset;
      top = alignY();
      break;
    case "bottom":
    default:
      left = alignX();
      top = a.bottom + offset;
      break;
  }

  left = _clampSafe(
      left, viewportPadding, viewportWidth - f.width - viewportPadding);
  top = _clampSafe(
      top, viewportPadding, viewportHeight - f.height - viewportPadding);

  floating.style.position = "fixed";
  _setPx(floating, "left", left);
  _setPx(floating, "top", top);
}

void _ensureOverlayZIndex(web.HTMLElement el) {
  // Keep overlays (popover/select/menu/tooltip) above modal dialogs by default.
  // Do not override explicit z-index styling.
  try {
    if (el.style.zIndex.isNotEmpty) return;
    final computed = web.window.getComputedStyle(el).zIndex;
    if (computed.isNotEmpty && computed != "auto") return;
    el.style.zIndex = "1001";
  } catch (_) {
    if (el.style.zIndex.isEmpty) el.style.zIndex = "1001";
  }
}

FloatingHandle floatToAnchor({
  required web.Element anchor,
  required web.HTMLElement floating,
  String placement = "bottom-start",
  double offset = 8,
  double viewportPadding = 8,
  bool flip = true,
  bool sameWidth = false,
  bool fitViewport = false,
  bool updateOnAnimationFrame = false,
  bool updateOnScrollParents = true,
  bool preferFloatingUi = true,
}) {
  var disposed = false;

  _ensureOverlayZIndex(floating);

  Object? jsHandle;
  void disposeJsHandle() {
    final h = jsHandle;
    jsHandle = null;
    if (h == null) return;
    try {
      js_util.callMethod(h, "dispose", const []);
    } catch (_) {}
  }

  if (preferFloatingUi) {
    try {
      final global = js_util.globalThis;
      if (js_util.hasProperty(global, "__solidFloatToAnchor")) {
        jsHandle = js_util.callMethod(
          global,
          "__solidFloatToAnchor",
          [
            anchor,
            floating,
            js_util.jsify({
              "placement": placement,
              "offset": offset,
              "viewportPadding": viewportPadding,
              "flip": flip,
              "sameWidth": sameWidth,
              "fitViewport": fitViewport,
              "updateOnAnimationFrame": updateOnAnimationFrame,
            }),
          ],
        );
      }
    } catch (_) {
      jsHandle = null;
    }
  }

  if (jsHandle != null) {
    void dispose() {
      disposed = true;
      disposeJsHandle();
    }

    onCleanup(dispose);
    return FloatingHandle._(dispose);
  }

  void compute() {
    if (disposed) return;
    if (!floating.isConnected) return;
    if (sameWidth) {
      try {
        if (floating.style.boxSizing.isEmpty) {
          floating.style.boxSizing = "border-box";
        }
        final rect = anchor.getBoundingClientRect();
        _setPx(floating, "width", rect.width);
      } catch (_) {}
    }
    if (fitViewport) {
      try {
        if (floating.style.boxSizing.isEmpty) {
          floating.style.boxSizing = "border-box";
        }
        _setPx(floating, "max-width", web.window.innerWidth.toDouble() - viewportPadding * 2);
        _setPx(floating, "max-height", web.window.innerHeight.toDouble() - viewportPadding * 2);
      } catch (_) {}
    }
    _positionFixed(
      anchor: anchor,
      floating: floating,
      placement: placement,
      offset: offset,
      viewportPadding: viewportPadding,
      flip: flip,
    );
  }

  void computeWhenConnected() {
    if (disposed) return;
    if (!floating.isConnected) {
      scheduleMicrotask(computeWhenConnected);
      return;
    }
    compute();
  }

  scheduleMicrotask(computeWhenConnected);
  on(web.window, "scroll", (_) => compute());
  on(web.window, "resize", (_) => compute());

  if (updateOnScrollParents && anchor.isConnected) {
    web.Node? current = anchor;
    while (current != null) {
      if (current is web.HTMLElement) {
        try {
          // Heuristic: if it can scroll now, listen to scroll.
          if (current.scrollHeight > current.clientHeight ||
              current.scrollWidth > current.clientWidth) {
            on(current, "scroll", (_) => compute());
          }
        } catch (_) {
          // Some host objects can throw when probing layout metrics.
        }
      }
      current = current.parentNode;
    }
  }

  if (updateOnAnimationFrame) {
    late final JSFunction jsLoop;
    void rafLoop(num _) {
      if (disposed) return;
      compute();
      web.window.requestAnimationFrame(jsLoop);
    }

    jsLoop = (rafLoop).toJS;
    web.window.requestAnimationFrame(jsLoop);
  }

  void dispose() {
    disposed = true;
    disposeJsHandle();
  }

  onCleanup(dispose);
  return FloatingHandle._(dispose);
}

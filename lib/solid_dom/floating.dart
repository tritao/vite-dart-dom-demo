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
  required double shift,
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

  // Approximate Kobalte's "shift" (skidding) behavior: apply shift on the
  // cross-axis relative to the placement side.
  if (shift != 0) {
    if (side == "top" || side == "bottom") {
      left += shift;
    } else if (side == "left" || side == "right") {
      top += shift;
    }
  }

  left = _clampSafe(
      left, viewportPadding, viewportWidth - f.width - viewportPadding);
  top = _clampSafe(
      top, viewportPadding, viewportHeight - f.height - viewportPadding);

  floating.style.position = "fixed";
  floating.style.left = "0";
  floating.style.top = "0";
  final x = left.roundToDouble();
  final y = top.roundToDouble();
  floating.style.transform = "translate3d(${x.toStringAsFixed(0)}px, ${y.toStringAsFixed(0)}px, 0)";
  try {
    floating.setAttribute("data-solid-placement", effective);
    floating.style.setProperty("--solid-popper-current-placement", effective);
  } catch (_) {}
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
  double shift = 0,
  double viewportPadding = 8,
  bool flip = true,
  bool slide = true,
  bool overlap = false,
  bool sameWidth = false,
  bool fitViewport = false,
  bool hideWhenDetached = false,
  double detachedPadding = 0,
  web.HTMLElement? arrow,
  double arrowPadding = 4,
  bool updateOnAnimationFrame = false,
  bool updateOnScrollParents = true,
  bool preferFloatingUi = true,
}) {
  var disposed = false;

  _ensureOverlayZIndex(floating);

  // Avoid 1-frame "tear" where the element paints in-flow before we apply fixed
  // positioning/transform. Keep it off-screen until the first positioning pass
  // completes (visibility:hidden can interfere with focus).
  try {
    if (floating.getAttribute("data-solid-popper-pending") == null) {
      floating.setAttribute("data-solid-popper-pending", "1");
    }
    floating.style.position = "fixed";
    floating.style.top = "0";
    floating.style.left = "0";
    if (floating.style.transform.isEmpty) {
      floating.style.transform = "translate3d(-100000px, -100000px, 0)";
    }
  } catch (_) {}

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
        final opts = js_util.newObject();
        js_util.setProperty(opts, "placement", placement);
        js_util.setProperty(opts, "offset", offset);
        js_util.setProperty(opts, "shift", shift);
        js_util.setProperty(opts, "viewportPadding", viewportPadding);
        js_util.setProperty(opts, "flip", flip);
        js_util.setProperty(opts, "slide", slide);
        js_util.setProperty(opts, "overlap", overlap);
        js_util.setProperty(opts, "sameWidth", sameWidth);
        js_util.setProperty(opts, "fitViewport", fitViewport);
        js_util.setProperty(opts, "hideWhenDetached", hideWhenDetached);
        js_util.setProperty(opts, "detachedPadding", detachedPadding);
        js_util.setProperty(opts, "updateOnAnimationFrame", updateOnAnimationFrame);
        js_util.setProperty(opts, "arrowPadding", arrowPadding);
        if (arrow != null) js_util.setProperty(opts, "arrow", arrow);
        jsHandle = js_util.callMethod(
          global,
          "__solidFloatToAnchor",
          [
            anchor,
            floating,
            opts,
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

  void finalizeFirstPaint() {
    try {
      if (floating.getAttribute("data-solid-popper-pending") != null) {
        floating.removeAttribute("data-solid-popper-pending");
      }
    } catch (_) {}
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
      shift: shift,
      viewportPadding: viewportPadding,
      flip: flip,
    );
    if (hideWhenDetached) {
      try {
        final r = anchor.getBoundingClientRect();
        final hidden = r.bottom <= detachedPadding ||
            r.right <= detachedPadding ||
            r.top >= web.window.innerHeight.toDouble() - detachedPadding ||
            r.left >= web.window.innerWidth.toDouble() - detachedPadding ||
            (anchor is web.HTMLElement && anchor.style.display == "none");
        floating.style.visibility = hidden ? "hidden" : "visible";
      } catch (_) {}
    }
    finalizeFirstPaint();
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

import "package:web/web.dart" as web;

import "./floating.dart";

/// Shared positioning helper used by Popover/Tooltip/Menu/Select/Combobox.
///
/// Mirrors Kobalte's PopperRoot defaults by delegating to [floatToAnchor] and
/// auto-detecting an arrow element when present.
FloatingHandle attachPopper({
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
  final resolvedArrow = arrow ??
      (() {
        try {
          final el = floating.querySelector("[data-solidus-popper-arrow]");
          return el is web.HTMLElement ? el : null;
        } catch (_) {
          return null;
        }
      })();

  return floatToAnchor(
    anchor: anchor,
    floating: floating,
    placement: placement,
    offset: offset,
    shift: shift,
    viewportPadding: viewportPadding,
    flip: flip,
    slide: slide,
    overlap: overlap,
    sameWidth: sameWidth,
    fitViewport: fitViewport,
    hideWhenDetached: hideWhenDetached,
    detachedPadding: detachedPadding,
    arrow: resolvedArrow,
    arrowPadding: arrowPadding,
    updateOnAnimationFrame: updateOnAnimationFrame,
    updateOnScrollParents: updateOnScrollParents,
    preferFloatingUi: preferFloatingUi,
  );
}

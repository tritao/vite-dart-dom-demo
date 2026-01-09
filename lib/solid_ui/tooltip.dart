import "package:web/web.dart" as web;

import "../solid_dom/core/tooltip.dart";

/// Styled Tooltip (Solidus UI skin).
///
/// For the unstyled primitive, use `createTooltip` from `solid_dom`.
web.DocumentFragment Tooltip({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required web.Element trigger,
  required TooltipBuilder builder,
  void Function(String reason)? onClose,
  String placement = "top",
  double offset = 6,
  double shift = 0,
  double viewportPadding = 8,
  bool flip = true,
  bool slide = true,
  bool overlap = false,
  bool hideWhenDetached = false,
  double detachedPadding = 0,
  double arrowPadding = 4,
  bool interactive = false,
  int openDelayMs = 500,
  int closeDelayMs = 150,
  int exitMs = 80,
  String? portalId,
}) {
  return createTooltip(
    open: open,
    setOpen: setOpen,
    trigger: trigger,
    builder: builder,
    onClose: onClose,
    placement: placement,
    offset: offset,
    shift: shift,
    viewportPadding: viewportPadding,
    flip: flip,
    slide: slide,
    overlap: overlap,
    hideWhenDetached: hideWhenDetached,
    detachedPadding: detachedPadding,
    arrowPadding: arrowPadding,
    interactive: interactive,
    openDelayMs: openDelayMs,
    closeDelayMs: closeDelayMs,
    exitMs: exitMs,
    portalId: portalId,
  );
}


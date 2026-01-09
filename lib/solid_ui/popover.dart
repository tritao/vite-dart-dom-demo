import "package:web/web.dart" as web;

import "../solid_dom/core/popover.dart";
import "../solid_dom/focus_scope.dart";

/// Styled Popover (Solidus UI skin).
///
/// For the unstyled primitive, use `createPopover` from `solid_dom`.
web.DocumentFragment Popover({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required PopoverBuilder builder,
  void Function(String reason)? onClose,
  int exitMs = 120,
  web.HTMLElement? initialFocus,
  bool trapFocus = false,
  void Function(FocusScopeAutoFocusEvent event)? onOpenAutoFocus,
  void Function(FocusScopeAutoFocusEvent event)? onCloseAutoFocus,
  web.Element? anchor,
  String placement = "bottom-start",
  double offset = 8,
  double viewportPadding = 8,
  bool flip = true,
  double shift = 0,
  bool slide = true,
  bool overlap = false,
  bool hideWhenDetached = false,
  double detachedPadding = 0,
  double arrowPadding = 4,
  String role = "dialog",
  String? portalId,
}) {
  return createPopover(
    open: open,
    setOpen: setOpen,
    builder: builder,
    onClose: onClose,
    exitMs: exitMs,
    initialFocus: initialFocus,
    trapFocus: trapFocus,
    onOpenAutoFocus: onOpenAutoFocus,
    onCloseAutoFocus: onCloseAutoFocus,
    anchor: anchor,
    placement: placement,
    offset: offset,
    viewportPadding: viewportPadding,
    flip: flip,
    shift: shift,
    slide: slide,
    overlap: overlap,
    hideWhenDetached: hideWhenDetached,
    detachedPadding: detachedPadding,
    arrowPadding: arrowPadding,
    role: role,
    portalId: portalId,
  );
}


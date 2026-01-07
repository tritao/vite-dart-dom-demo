import "package:web/web.dart" as web;

import "./focus_scope.dart";
import "./menu.dart";

/// Public DropdownMenu wrapper (Kobalte naming).
///
/// This currently forwards to [Menu] with DropdownMenu-friendly defaults.
web.DocumentFragment DropdownMenu({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required web.Element anchor,
  required DropdownMenuBuilder builder,
  void Function(String reason)? onClose,
  void Function(FocusScopeAutoFocusEvent event)? onOpenAutoFocus,
  void Function(FocusScopeAutoFocusEvent event)? onCloseAutoFocus,
  int exitMs = 120,
  String placement = "bottom-start",
  double offset = 4,
  double viewportPadding = 8,
  bool flip = true,
  bool modal = false,
  String? portalId,
}) {
  return Menu(
    open: open,
    setOpen: setOpen,
    anchor: anchor,
    builder: builder,
    onClose: onClose,
    onOpenAutoFocus: onOpenAutoFocus,
    onCloseAutoFocus: onCloseAutoFocus,
    exitMs: exitMs,
    placement: placement,
    offset: offset,
    viewportPadding: viewportPadding,
    flip: flip,
    modal: modal,
    portalId: portalId,
  );
}


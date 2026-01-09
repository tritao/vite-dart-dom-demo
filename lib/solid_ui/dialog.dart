import "package:web/web.dart" as web;

import "../solid_dom/core/dialog.dart";
import "../solid_dom/focus_scope.dart";

/// Styled Dialog (Solidus UI skin).
///
/// For the unstyled primitive, use `createDialog` from `solid_dom`.
web.DocumentFragment Dialog({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required DialogBuilder builder,
  void Function(String reason)? onClose,
  bool modal = true,
  bool backdrop = false,
  String? backdropId,
  String? backdropClassName,
  int exitMs = 120,
  web.HTMLElement? initialFocus,
  bool restoreFocus = true,
  void Function(FocusScopeAutoFocusEvent event)? onOpenAutoFocus,
  void Function(FocusScopeAutoFocusEvent event)? onCloseAutoFocus,
  String? labelledBy,
  String? describedBy,
  String role = "dialog",
  String? portalId,
}) {
  return createDialog(
    open: open,
    setOpen: setOpen,
    builder: builder,
    onClose: onClose,
    modal: modal,
    backdrop: backdrop,
    backdropId: backdropId,
    backdropClassName: backdropClassName,
    exitMs: exitMs,
    initialFocus: initialFocus,
    restoreFocus: restoreFocus,
    onOpenAutoFocus: onOpenAutoFocus,
    onCloseAutoFocus: onCloseAutoFocus,
    labelledBy: labelledBy,
    describedBy: describedBy,
    role: role,
    portalId: portalId,
  );
}


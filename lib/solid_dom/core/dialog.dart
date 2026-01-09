import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "../focus_scope.dart";
import "../overlay.dart";
import "../presence.dart";
import "../solid_dom.dart";

typedef DialogBuilder = web.HTMLElement Function(void Function() close);

web.DocumentFragment createDialog({
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
  return Presence(
    when: open,
    exitMs: exitMs,
    children: () => Portal(
      id: portalId,
      children: () {
        void close([String reason = "close"]) {
          onClose?.call(reason);
          setOpen(false);
        }

        final dialog = builder(close);
        dialog.setAttribute("role", role);
        dialog.setAttribute("data-solid-dialog-content", "1");
        if (modal) dialog.setAttribute("aria-modal", "true");
        if (labelledBy != null) {
          dialog.setAttribute("aria-labelledby", labelledBy);
        }
        if (describedBy != null) {
          dialog.setAttribute("aria-describedby", describedBy);
        }
        dialog.tabIndex = -1;

        final usesWrapper = modal || backdrop;
        final wrapper = web.HTMLDivElement()
          ..setAttribute("data-solid-dialog-wrapper", "1");

        web.HTMLElement? backdropEl;
        if (backdrop) {
          final el = web.HTMLDivElement()
            ..setAttribute("data-solid-backdrop", "1");
          if (backdropId != null) el.id = backdropId;
          if (backdropClassName != null) el.className = backdropClassName;
          backdropEl = el;
        }
        if (usesWrapper) {
          if (backdropEl != null) wrapper.appendChild(backdropEl);
          wrapper.appendChild(dialog);
        }

        dismissableLayer(
          dialog,
          stackElement: usesWrapper ? wrapper : dialog,
          disableOutsidePointerEvents: modal,
          dismissOnFocusOutside: false,
          onDismiss: (reason) => close(reason),
          preventClickThrough: true,
        );
        if (modal) {
          focusScope(
            dialog,
            trapFocus: true,
            initialFocus: initialFocus,
            restoreFocus: restoreFocus,
            onMountAutoFocus: onOpenAutoFocus,
            onUnmountAutoFocus: onCloseAutoFocus,
          );
        } else if (initialFocus != null) {
          scheduleMicrotask(() {
            try {
              initialFocus.focus();
            } catch (_) {}
          });
        }
        if (modal) {
          scrollLock();
          ariaHideOthers(dialog);
        }

        if (modal || backdropEl != null) return wrapper;
        return dialog;
      },
    ),
  );
}

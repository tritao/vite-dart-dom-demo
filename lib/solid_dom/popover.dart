import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./floating.dart";
import "./focus_scope.dart";
import "./overlay.dart";
import "./presence.dart";
import "./solid_dom.dart";

typedef PopoverBuilder = web.HTMLElement Function(void Function() close);

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

        final popover = builder(close);
        popover.setAttribute("role", role);
        popover.tabIndex = -1;

        if (anchor != null) {
          final arrow = popover.querySelector("[data-solid-popper-arrow]");
          floatToAnchor(
            anchor: anchor,
            floating: popover,
            placement: placement,
            offset: offset,
            viewportPadding: viewportPadding,
            flip: flip,
            shift: shift,
            slide: slide,
            overlap: overlap,
            hideWhenDetached: hideWhenDetached,
            detachedPadding: detachedPadding,
            arrow: arrow is web.HTMLElement ? arrow : null,
            arrowPadding: arrowPadding,
          );
        }

        dismissableLayer(
          popover,
          excludedElements: anchor == null
              ? null
              : <web.Element? Function()>[
                  () => anchor,
                ],
          onDismiss: (reason) => close(reason),
        );
        focusScope(
          popover,
          trapFocus: trapFocus,
          autoFocus: trapFocus || initialFocus != null,
          initialFocus: initialFocus,
          onMountAutoFocus: onOpenAutoFocus,
          onUnmountAutoFocus: onCloseAutoFocus,
        );

        return popover;
      },
    ),
  );
}

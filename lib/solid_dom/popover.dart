import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./floating.dart";
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
  web.Element? anchor,
  String placement = "bottom-start",
  double offset = 8,
  String role = "dialog",
  String? portalId,
}) {
  return Presence(
    when: open,
    exitMs: exitMs,
    children: () => Portal(
      id: portalId,
      children: () {
        final previousActive = web.document.activeElement;

        void close([String reason = "close"]) {
          onClose?.call(reason);
          setOpen(false);
        }

        final popover = builder(close);
        popover.setAttribute("role", role);
        popover.tabIndex = -1;

        if (anchor != null) {
          floatToAnchor(
            anchor: anchor,
            floating: popover,
            placement: placement,
            offset: offset,
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
        if (trapFocus) focusTrap(popover, initialFocus: initialFocus);
        if (!trapFocus && initialFocus != null) {
          scheduleMicrotask(() {
            try {
              initialFocus.focus();
            } catch (_) {}
          });
        }

        onCleanup(() {
          if (previousActive is web.HTMLElement) {
            try {
              previousActive.focus();
            } catch (_) {}
          }
        });

        return popover;
      },
    ),
  );
}

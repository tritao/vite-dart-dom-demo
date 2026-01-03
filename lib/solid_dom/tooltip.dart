import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./floating.dart";
import "./overlay.dart";
import "./presence.dart";
import "./solid_dom.dart";

typedef TooltipBuilder = web.HTMLElement Function(void Function([String reason]) close);

int _tooltipIdCounter = 0;

String _nextTooltipId() {
  _tooltipIdCounter++;
  return "solid-tooltip-$_tooltipIdCounter";
}

String _mergeDescribedBy(String? existing, String id) {
  if (existing == null || existing.trim().isEmpty) return id;
  final parts = existing.split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toSet();
  parts.add(id);
  return parts.join(" ");
}

String? _removeDescribedBy(String? existing, String id) {
  if (existing == null || existing.trim().isEmpty) return null;
  final parts = existing.split(RegExp(r"\s+")).where((p) => p.isNotEmpty && p != id).toList();
  if (parts.isEmpty) return null;
  return parts.join(" ");
}

web.DocumentFragment Tooltip({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required web.Element trigger,
  required TooltipBuilder builder,
  void Function(String reason)? onClose,
  String placement = "top",
  double offset = 6,
  double viewportPadding = 8,
  bool flip = true,
  bool interactive = false,
  int openDelayMs = 500,
  int closeDelayMs = 150,
  int exitMs = 80,
  String? portalId,
}) {
  Timer? openTimer;
  Timer? closeTimer;
  String closeReason = "close";

  void cancelTimers() {
    openTimer?.cancel();
    closeTimer?.cancel();
    openTimer = null;
    closeTimer = null;
  }

  void openNow([String reason = "open"]) {
    closeReason = reason;
    cancelTimers();
    setOpen(true);
  }

  void closeNow([String reason = "close"]) {
    closeReason = reason;
    cancelTimers();
    onClose?.call(reason);
    setOpen(false);
  }

  void scheduleOpen([String reason = "hover"]) {
    closeReason = reason;
    closeTimer?.cancel();
    closeTimer = null;
    if (open()) return;
    openTimer?.cancel();
    openTimer = Timer(Duration(milliseconds: openDelayMs), () => openNow(reason));
  }

  void scheduleClose([String reason = "leave"]) {
    closeReason = reason;
    openTimer?.cancel();
    openTimer = null;
    if (!open()) return;
    closeTimer?.cancel();
    closeTimer = Timer(Duration(milliseconds: closeDelayMs), () => closeNow(reason));
  }

  on(trigger, "pointerenter", (_) => scheduleOpen("hover"));
  on(trigger, "pointerleave", (_) => scheduleClose("leave"));
  on(trigger, "focusin", (_) => openNow("focus"));
  on(trigger, "focusout", (_) => scheduleClose("blur"));
  on(trigger, "pointerdown", (_) => closeNow("pointerdown"));
  on(trigger, "keydown", (e) {
    if (e is! web.KeyboardEvent) return;
    if (e.key == "Escape") {
      e.preventDefault();
      closeNow("escape");
    }
  });

  onCleanup(cancelTimers);

  return Presence(
    when: open,
    exitMs: exitMs,
    children: () => Portal(
      id: portalId,
      children: () {
        final el = builder(closeNow);
        el.setAttribute("role", "tooltip");
        el.style.position = "fixed";
        if (!interactive) el.style.pointerEvents = "none";

        final tooltipId = el.id.isNotEmpty ? el.id : _nextTooltipId();
        el.id = tooltipId;

        floatToAnchor(
          anchor: trigger,
          floating: el,
          placement: placement,
          offset: offset,
          viewportPadding: viewportPadding,
          flip: flip,
          updateOnScrollParents: true,
        );

        final prevDescribedBy = trigger.getAttribute("aria-describedby");
        trigger.setAttribute(
          "aria-describedby",
          _mergeDescribedBy(prevDescribedBy, tooltipId),
        );
        onCleanup(() {
          final current = trigger.getAttribute("aria-describedby");
          final next = _removeDescribedBy(current, tooltipId);
          if (next == null) {
            trigger.removeAttribute("aria-describedby");
          } else {
            trigger.setAttribute("aria-describedby", next);
          }
        });

        // Close when the user interacts elsewhere or presses Escape.
        dismissableLayer(
          el,
          onDismiss: (reason) => closeNow(reason),
          dismissOnFocusOutside: true,
          bypassTopMostLayerCheck: true,
        );

        if (interactive) {
          on(el, "pointerenter", (_) {
            cancelTimers();
          });
          on(el, "pointerleave", (_) => scheduleClose("leave"));
        }

        return el;
      },
    ),
  );
}

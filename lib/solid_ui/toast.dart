import "package:web/web.dart" as web;

import "../solid_dom/core/toast.dart";
import "../solid_dom/solid_dom.dart";

final class Toaster {
  Toaster(this.controller);

  final ToastController controller;

  List<ToastEntry> get toasts => controller.toasts;

  int show(String message, {int? durationMs}) =>
      controller.show(message, durationMs: durationMs);

  void dismiss(int id, {String reason = "dismiss"}) =>
      controller.dismiss(id, reason: reason);

  void remove(int id) => controller.remove(id);

  web.DocumentFragment view({
    String portalId = "toast-portal-container",
    String viewportId = "toast-viewport",
  }) {
    return controller.view(
      portalId: portalId,
      viewportId: viewportId,
      viewportClassName: "toastViewport",
      toastBuilder: _toastUiBuilder,
    );
  }
}

Toaster createToaster({
  int exitMs = 120,
  int defaultDurationMs = 2500,
}) {
  final controller = createToastController(
    exitMs: exitMs,
    defaultDurationMs: defaultDurationMs,
  );
  return Toaster(controller);
}

web.HTMLElement _toastUiBuilder(
  ToastEntry toast,
  void Function([String reason]) dismiss,
) {
  final card = web.HTMLDivElement()
    ..id = "toast-${toast.id}"
    ..className = "card"
    ..setAttribute("role", "status");

  final textEl = web.HTMLParagraphElement()..textContent = toast.message;
  card.appendChild(textEl);

  final close = web.HTMLButtonElement()
    ..type = "button"
    ..className = "btn secondary"
    ..textContent = "Dismiss";
  on(close, "click", (_) => dismiss("button"));
  card.appendChild(close);

  return card;
}

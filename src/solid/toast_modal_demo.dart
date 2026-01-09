import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

import "./demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidToastModalDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "toast-modal-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "toast-modal"));

    final toaster = createToaster(exitMs: 120, defaultDurationMs: 8000);
    final modalOpen = createSignal(false);
    final outsideClicks = createSignal(0);

    root.appendChild(
      web.HTMLHeadingElement.h1()..textContent = "Solid Toast + Modal Demo",
    );

    root.appendChild(
      solidDemoHelp(
        title: "What this tests",
        bullets: const [
          "When a modal dialog is open, outside pointer events are blocked.",
          "Toasts are marked as top-layer and must remain clickable.",
          "Clicking toast controls must not dismiss the modal.",
        ],
      ),
    );

    final openModal = web.HTMLButtonElement()
      ..id = "toast-modal-open"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Open modal";
    on(openModal, "click", (_) => modalOpen.value = true);
    root.appendChild(openModal);

    final outside = web.HTMLButtonElement()
      ..id = "toast-modal-outside"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Outside click counter";
    on(outside, "click", (_) => outsideClicks.value++);
    root.appendChild(outside);

    final status = web.HTMLParagraphElement()
      ..id = "toast-modal-status"
      ..className = "muted";
    status.appendChild(
      text(() => "Outside clicks: ${outsideClicks.value}"),
    );
    root.appendChild(status);

    root.appendChild(toaster.view(portalId: "toast-modal-portal", viewportId: "toast-viewport"));

    root.appendChild(
      Dialog(
        open: () => modalOpen.value,
        setOpen: (next) => modalOpen.value = next,
        backdrop: true,
        backdropId: "toast-modal-backdrop",
        portalId: "toast-modal-dialog-portal",
        onClose: (_) => modalOpen.value = false,
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "toast-modal-panel"
            ..className = "card";
          panel.appendChild(
            web.HTMLHeadingElement.h2()..textContent = "Modal",
          );

          final showToast = web.HTMLButtonElement()
            ..id = "toast-modal-show-toast"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Show toast";
          on(showToast, "click", (_) => toaster.show("Toast from modal"));

          final closeBtn = web.HTMLButtonElement()
            ..id = "toast-modal-close"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Close";
          on(closeBtn, "click", (_) => close());

          final row = web.HTMLDivElement()..className = "row";
          row.appendChild(showToast);
          row.appendChild(closeBtn);
          panel.appendChild(row);

          return panel;
        },
      ),
    );

    return root;
  });
}

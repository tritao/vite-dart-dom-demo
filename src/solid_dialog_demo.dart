import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

void mountSolidDialogDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "dialog-root"
      ..className = "container";

    final open = createSignal(false);
    final nestedOpen = createSignal(false);
    final lastDismiss = createSignal("none");
    final outsideClicks = createSignal(0);

    root.appendChild(
        web.HTMLHeadingElement.h1()..textContent = "Solid Dialog Demo");

    final trigger = web.HTMLButtonElement()
      ..id = "dialog-trigger"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Open dialog";
    on(trigger, "click", (_) => open.value = true);
    root.appendChild(trigger);

    final status = web.HTMLParagraphElement()
      ..id = "dialog-status"
      ..className = "muted";
    status.appendChild(text(() =>
        "Dismiss: ${lastDismiss.value} • Outside clicks: ${outsideClicks.value}"));
    root.appendChild(status);

    final outsideAction = web.HTMLButtonElement()
      ..id = "dialog-outside-action"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Outside action (increments)";
    on(outsideAction, "click", (_) => outsideClicks.value++);
    root.appendChild(outsideAction);

    final titleId = "dialog-title";
    final descId = "dialog-desc";

    root.appendChild(
      Dialog(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        backdrop: true,
        backdropId: "dialog-backdrop",
        labelledBy: titleId,
        describedBy: descId,
        onClose: (reason) => lastDismiss.value = reason,
        portalId: "dialog-portal",
        builder: (close) {
          final dialog = web.HTMLDivElement()
            ..id = "dialog-panel"
            ..className = "card";

          dialog.appendChild(web.HTMLHeadingElement.h2()
            ..id = titleId
            ..textContent = "Dialog");
          dialog.appendChild(web.HTMLParagraphElement()
            ..id = descId
            ..textContent = "Press Escape or click outside to dismiss.");

          final closeBtn = web.HTMLButtonElement()
            ..id = "dialog-close"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Close";
          on(closeBtn, "click", (_) {
            lastDismiss.value = "close";
            close();
          });
          dialog.appendChild(closeBtn);

          final nestedTrigger = web.HTMLButtonElement()
            ..id = "dialog-nested-trigger"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Open nested";
          on(nestedTrigger, "click", (_) => nestedOpen.value = true);
          dialog.appendChild(nestedTrigger);

          dialog.appendChild(
            Dialog(
              open: () => nestedOpen.value,
              setOpen: (next) => nestedOpen.value = next,
              backdrop: true,
              backdropId: "dialog-nested-backdrop",
              portalId: "dialog-nested-portal",
              onClose: (reason) => lastDismiss.value = "nested:$reason",
              builder: (nestedClose) {
                final nested = web.HTMLDivElement()
                  ..id = "dialog-nested-panel"
                  ..className = "card";
                nested.appendChild(
                    web.HTMLHeadingElement.h2()..textContent = "Nested");
                final nestedCloseBtn = web.HTMLButtonElement()
                  ..id = "dialog-nested-close"
                  ..type = "button"
                  ..className = "btn secondary"
                  ..textContent = "Close nested";
                on(nestedCloseBtn, "click", (_) {
                  lastDismiss.value = "nested:close";
                  nestedClose();
                });
                nested.appendChild(nestedCloseBtn);
                return nested;
              },
            ),
          );

          return dialog;
        },
      ),
    );

    return root;
  });
}

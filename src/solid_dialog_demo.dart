import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

void mountSolidDialogDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "dialog-root"
      ..className = "container";

    final open = createSignal(false);
    final noBackdropOpen = createSignal(false);
    final hooksOpen = createSignal(false);
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

    final noBackdropTrigger = web.HTMLButtonElement()
      ..id = "dialog-trigger-nobackdrop"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Open dialog (no backdrop)";
    on(noBackdropTrigger, "click", (_) => noBackdropOpen.value = true);
    root.appendChild(noBackdropTrigger);

    final hooksTrigger = web.HTMLButtonElement()
      ..id = "dialog-hooks-trigger"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Open dialog (autofocus hooks)";
    on(hooksTrigger, "click", (_) => hooksOpen.value = true);
    root.appendChild(hooksTrigger);

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

    root.appendChild(
      Dialog(
        open: () => noBackdropOpen.value,
        setOpen: (next) => noBackdropOpen.value = next,
        backdrop: false,
        labelledBy: "dialog-nobackdrop-title",
        describedBy: "dialog-nobackdrop-desc",
        onClose: (reason) => lastDismiss.value = "nobackdrop:$reason",
        portalId: "dialog-nobackdrop-portal",
        builder: (close) {
          final dialog = web.HTMLDivElement()
            ..id = "dialog-nobackdrop-panel"
            ..className = "card";

          dialog.appendChild(web.HTMLHeadingElement.h2()
            ..id = "dialog-nobackdrop-title"
            ..textContent = "Dialog (no backdrop)");
          dialog.appendChild(web.HTMLParagraphElement()
            ..id = "dialog-nobackdrop-desc"
            ..textContent = "Modal dialog without a backdrop element.");

          final closeBtn = web.HTMLButtonElement()
            ..id = "dialog-nobackdrop-close"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Close";
          on(closeBtn, "click", (_) {
            lastDismiss.value = "nobackdrop:close";
            close();
          });
          dialog.appendChild(closeBtn);
          return dialog;
        },
      ),
    );

    web.HTMLButtonElement? hooksSecondary;
    root.appendChild(
      Dialog(
        open: () => hooksOpen.value,
        setOpen: (next) => hooksOpen.value = next,
        backdrop: true,
        backdropId: "dialog-hooks-backdrop",
        onClose: (reason) => lastDismiss.value = "hooks:$reason",
        onOpenAutoFocus: (e) {
          e.preventDefault();
          scheduleMicrotask(() {
            try {
              hooksSecondary?.focus();
            } catch (_) {}
          });
        },
        onCloseAutoFocus: (e) {
          e.preventDefault();
          scheduleMicrotask(() {
            try {
              outsideAction.focus();
            } catch (_) {}
          });
        },
        portalId: "dialog-hooks-portal",
        builder: (close) {
          final dialog = web.HTMLDivElement()
            ..id = "dialog-hooks-panel"
            ..className = "card";
          dialog.appendChild(web.HTMLHeadingElement.h2()
            ..id = "dialog-hooks-title"
            ..textContent = "Dialog (hooks)");
          dialog.appendChild(web.HTMLParagraphElement()
            ..textContent = "Uses onOpenAutoFocus/onCloseAutoFocus overrides.");

          hooksSecondary = web.HTMLButtonElement()
            ..id = "dialog-hooks-secondary"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Secondary (should receive focus)";
          dialog.appendChild(hooksSecondary!);

          final closeBtn = web.HTMLButtonElement()
            ..id = "dialog-hooks-close"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Close";
          on(closeBtn, "click", (_) {
            lastDismiss.value = "hooks:close";
            close();
          });
          dialog.appendChild(closeBtn);

          return dialog;
        },
      ),
    );

    return root;
  });
}

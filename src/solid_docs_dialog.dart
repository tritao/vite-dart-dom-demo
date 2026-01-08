import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_docs_components.dart";
import "./solid_docs_data.dart";
import "./solid_docs_shell.dart";

void mountSolidDocsDialog(web.Element mount) {
  render(mount, () {
    final entry = findDocsEntry("dialog");

    final open = createSignal(false);
    final lastClose = createSignal("none");

    final titleId = "docs-dialog-title";
    final descId = "docs-dialog-desc";

    final openBtn = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Open dialog";
    on(openBtn, "click", (_) => open.value = true);

    final example = docSection(
      title: "Basic example",
      children: [
        web.HTMLParagraphElement()
          ..className = "muted"
          ..textContent =
              "A modal dialog that traps focus, closes on Escape/outside click, and restores focus to the trigger.",
        web.HTMLDivElement()
          ..className = "row"
          ..appendChild(openBtn)
          ..appendChild(
            web.HTMLAnchorElement()
              ..href = entry?.labHref ?? "/?solid=dialog"
              ..className = "btn secondary"
              ..textContent = "Open lab",
          ),
        web.HTMLParagraphElement()
          ..className = "muted"
          ..appendChild(text(() => "Last close reason: ${lastClose.value}")),
        Dialog(
          open: () => open.value,
          setOpen: (next) => open.value = next,
          modal: true,
          backdrop: true,
          labelledBy: titleId,
          describedBy: descId,
          onClose: (reason) => lastClose.value = reason,
          portalId: "docs-dialog-portal",
          builder: (close) {
            final panel = web.HTMLDivElement()
              ..className = "card"
              ..style.maxWidth = "520px";

            panel.appendChild(web.HTMLHeadingElement.h2()
              ..id = titleId
              ..textContent = "Dialog title");
            panel.appendChild(web.HTMLParagraphElement()
              ..id = descId
              ..className = "muted"
              ..textContent =
                  "Tab should stay inside. Escape or click outside to dismiss.");

            final actions = web.HTMLDivElement()..className = "row";
            final closeBtn = web.HTMLButtonElement()
              ..type = "button"
              ..className = "btn secondary"
              ..textContent = "Close";
            on(closeBtn, "click", (_) {
              lastClose.value = "close";
              close();
            });
            actions.appendChild(closeBtn);
            panel.appendChild(actions);
            return panel;
          },
        ),
      ],
    );

    final a11y = docSection(
      title: "Semantics & keyboard",
      children: [
        web.HTMLUListElement()
          ..appendChild(web.HTMLLIElement()
            ..textContent = "Use aria-labelledby/aria-describedby for name/description.")
          ..appendChild(web.HTMLLIElement()
            ..textContent =
                "Modal dialogs should trap focus and restore focus to the trigger on close.")
          ..appendChild(web.HTMLLIElement()
            ..textContent =
                "Escape closes; outside-click closes (unless you opt out in your usage)."),
        docTable(const [
          ["Key", "Behavior"],
          ["Tab / Shift+Tab", "Cycles within the dialog (modal)."],
          ["Escape", "Closes the dialog."],
        ]),
      ],
    );

    final api = docSection(
      title: "API (Dart)",
      children: [
        docTable(const [
          ["Prop", "Notes"],
          ["open()", "Signal getter controlling visibility."],
          ["setOpen(next)", "Signal setter; called on dismiss/close."],
          ["builder(close)", "Builds dialog content; call close(reason?) to dismiss."],
          ["modal", "When true: trap focus + aria-hide + scroll-lock + disable outside pointer events."],
          ["backdrop", "When true: renders a backdrop element behind the panel."],
          ["labelledBy / describedBy", "Sets aria-labelledby/aria-describedby."],
          ["onClose(reason)", "Called with close reason (escape/outside/close/etc)."],
          ["initialFocus / restoreFocus", "Focus control hooks."],
          ["onOpenAutoFocus / onCloseAutoFocus", "Preventable autofocus events."],
        ]),
      ],
    );

    final snippet = docSection(
      title: "Minimal snippet",
      children: [
        docCode(r'''
final open = createSignal(false);

final trigger = web.HTMLButtonElement()
  ..type = "button"
  ..className = "btn primary"
  ..textContent = "Open dialog";
on(trigger, "click", (_) => open.value = true);

root.appendChild(trigger);
root.appendChild(
  Dialog(
    open: () => open.value,
    setOpen: (next) => open.value = next,
    modal: true,
    backdrop: true,
    labelledBy: "dlg-title",
    describedBy: "dlg-desc",
    builder: (close) {
      final panel = web.HTMLDivElement()..className = "card";
      panel.appendChild(web.HTMLHeadingElement.h2()
        ..id = "dlg-title"
        ..textContent = "Dialog");
      panel.appendChild(web.HTMLParagraphElement()
        ..id = "dlg-desc"
        ..textContent = "…");
      final closeBtn = web.HTMLButtonElement()
        ..type = "button"
        ..className = "btn secondary"
        ..textContent = "Close";
      on(closeBtn, "click", (_) => close());
      panel.appendChild(closeBtn);
      return panel;
    },
  ),
);
'''),
      ],
    );

    return docsShell(
      activeKey: "dialog",
      title: "Dialog",
      children: [
        web.HTMLParagraphElement()
          ..className = "muted"
          ..textContent =
              "A modal or non-modal overlay for focused user interaction. Mirrors Kobalte-style behavior (focus trapping, dismiss, stacking).",
        example,
        snippet,
        api,
        a11y,
      ],
    );
  });
}

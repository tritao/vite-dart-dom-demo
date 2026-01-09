import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom/solid_dom.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsDialogBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final open = createSignal(false);
    final lastClose = createSignal("none");

    final titleId = "docs-dialog-basic-title";
    final descId = "docs-dialog-basic-desc";

    final row = web.HTMLDivElement()..className = "row";
    final btn = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Open dialog";
    on(btn, "click", (_) => open.value = true);
    row.appendChild(btn);

    final status = web.HTMLParagraphElement()
      ..className = "muted";
    status.appendChild(text(() => "Last close: ${lastClose.value}"));
    row.appendChild(status);

    final root = web.HTMLDivElement();
    root.appendChild(row);

    root.appendChild(
      Dialog(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        modal: true,
        backdrop: true,
        labelledBy: titleId,
        describedBy: descId,
        onClose: (reason) => lastClose.value = reason,
        portalId: "docs-dialog-basic-portal",
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
                "Tab stays inside. Escape or click outside to dismiss.");

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
    );

    return root;
  });
  // #doc:endregion snippet
}

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom/solid_dom.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsPopoverBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final open = createSignal(false);
    final lastClose = createSignal("none");

    final trigger = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Toggle popover";

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "Last close: ${lastClose.value}"));

    final root = web.HTMLDivElement()..className = "row";
    root.appendChild(trigger);
    root.appendChild(status);

    on(trigger, "click", (_) => open.value = !open.value);

    root.appendChild(
      Popover(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        anchor: trigger,
        portalId: "docs-popover-basic-portal",
        onClose: (reason) => lastClose.value = reason,
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..className = "card"
            ..style.maxWidth = "360px";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent = "This is a popover panel.");

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

    return root;
  });
  // #doc:endregion snippet
}

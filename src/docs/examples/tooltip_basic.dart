import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsTooltipBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final open = createSignal(false);
    final lastClose = createSignal("none");

    final trigger = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Hover or focus me";

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "Last close: ${lastClose.value}"));

    final root = web.HTMLDivElement()..className = "row";
    root.appendChild(trigger);
    root.appendChild(status);

    root.appendChild(
      Tooltip(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        trigger: trigger,
        portalId: "docs-tooltip-basic-portal",
        onClose: (reason) => lastClose.value = reason,
        builder: (close) {
          final tip = web.HTMLDivElement()
            ..className = "card"
            ..style.padding = "8px 10px"
            ..style.fontSize = "12px";
          tip.appendChild(web.Text("Tooltip text"));
          return tip;
        },
      ),
    );

    return root;
  });
  // #doc:endregion snippet
}

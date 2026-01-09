import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsSwitchBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final checked = createSignal(false);

    final sw = Switch(
      checked: () => checked.value,
      setChecked: (next) => checked.value = next,
      ariaLabel: "Enable feature",
    );

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "Checked: ${checked.value}"));

    final root = web.HTMLDivElement()..className = "row";
    root.appendChild(sw);
    root.appendChild(status);
    return root;
  });
  // #doc:endregion snippet
}

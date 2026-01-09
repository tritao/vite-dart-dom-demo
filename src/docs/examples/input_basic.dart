import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsInputBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final value = createSignal("");
    final disabled = createSignal(false);

    final input = Input(
      id: "docs-input-basic",
      placeholder: "Type here…",
      value: () => value.value,
      setValue: (next) => value.value = next,
      disabled: () => disabled.value,
      ariaLabel: "Example input",
    );

    final toggle = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn secondary";
    toggle.appendChild(text(
      () => disabled.value ? "Enable input" : "Disable input",
    ));
    on(toggle, "click", (_) => disabled.value = !disabled.value);

    final root = web.HTMLDivElement()..className = "row";
    root.appendChild(input);
    root.appendChild(toggle);
    root.appendChild(web.HTMLParagraphElement()
      ..className = "muted"
      ..appendChild(text(() => "value=\"${value.value}\"")));
    return root;
  });
  // #doc:endregion snippet
}

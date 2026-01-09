import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsFieldsetBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final disabled = createSignal(false);

    final toggle = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Toggle disabled";
    on(toggle, "click", (_) => disabled.value = !disabled.value);

    final fieldset = Fieldset(
      legend: "Shipping",
      children: () => [
        FormField(
          id: "docs-fieldset-name",
          label: () => "Name",
          control: Input(placeholder: "Ada Lovelace", ariaLabel: "Name"),
        ),
        web.HTMLDivElement()..style.height = "10px",
        FormField(
          id: "docs-fieldset-city",
          label: () => "City",
          control: Input(placeholder: "London", ariaLabel: "City"),
        ),
      ],
    );

    final root = web.HTMLDivElement();
    root.appendChild(toggle);
    root.appendChild(web.HTMLDivElement()..style.height = "10px");
    root.appendChild(fieldset);

    createRenderEffect(() {
      fieldset.disabled = disabled.value;
    });

    return root;
  });
  // #doc:endregion snippet
}

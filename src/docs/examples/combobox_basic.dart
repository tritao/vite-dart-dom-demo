import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsComboboxBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final open = createSignal(false);
    final value = createSignal<String?>(null);

    const opts = [
      ComboboxOption(value: "one", label: "One"),
      ComboboxOption(value: "two", label: "Two"),
      ComboboxOption(value: "three", label: "Three"),
      ComboboxOption(value: "four", label: "Four", disabled: true),
      ComboboxOption(value: "five", label: "Five"),
    ];

    final input = web.HTMLInputElement()
      ..type = "text"
      ..className = "input"
      ..placeholder = "Type to filter…";

    final anchor = web.HTMLDivElement()..className = "row";
    anchor.appendChild(input);

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "Value: ${value.value ?? "none"}"));

    final root = web.HTMLDivElement();
    root.appendChild(anchor);
    root.appendChild(status);

    root.appendChild(
      Combobox<String>(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        anchor: anchor,
        input: input,
        portalId: "docs-combobox-basic-portal",
        options: () => opts,
        value: () => value.value,
        setValue: (next) => value.value = next,
        closeOnSelection: true,
      ),
    );

    return root;
  });
  // #doc:endregion snippet
}


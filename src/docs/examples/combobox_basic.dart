import "dart:js_interop";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
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
      ..id = "docs-combobox-basic-input"
      ..type = "text"
      ..className = "input"
      ..placeholder = "Type to filter…";

    final trigger = web.HTMLButtonElement()
      ..id = "docs-combobox-basic-trigger"
      ..className = "comboTrigger"
      ..innerHTML = (r'''
<svg viewBox="0 0 24 24" aria-hidden="true" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m7 15 5 5 5-5" />
  <path d="m7 9 5-5 5 5" />
</svg>
''').toJS;

    final anchor = web.HTMLDivElement()..className = "comboControl";
    anchor.appendChild(input);
    anchor.appendChild(trigger);

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
        triggerButton: trigger,
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

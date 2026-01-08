import "dart:js_interop";

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
      ..id = "docs-combobox-basic-input"
      ..type = "text"
      ..className = "input"
      ..placeholder = "Type to filter…";

    final trigger = web.HTMLButtonElement()
      ..id = "docs-combobox-basic-trigger"
      ..className = "comboTrigger"
      ..innerHTML = (r'''
<svg viewBox="0 0 24 24" aria-hidden="true" width="18" height="18">
  <path fill="currentColor" d="M8.3 9.3a1 1 0 0 1 1.4 0L12 11.6l2.3-2.3a1 1 0 1 1 1.4 1.4l-3 3a1 1 0 0 1-1.4 0l-3-3a1 1 0 0 1 0-1.4zm7.4 5.4a1 1 0 0 1-1.4 0L12 12.4l-2.3 2.3a1 1 0 1 1-1.4-1.4l3-3a1 1 0 0 1 1.4 0l3 3a1 1 0 0 1 0 1.4z"/>
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

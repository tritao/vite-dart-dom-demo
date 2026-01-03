import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

void mountSolidSelectDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "select-root"
      ..className = "container";

    final open = createSignal(false);
    final selected = createSignal<String?>(null);
    final lastEvent = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Select Demo");

    final status = web.HTMLParagraphElement()
      ..id = "select-status"
      ..className = "muted";
    status.appendChild(text(() => "Value: ${selected.value ?? "none"} • Last: ${lastEvent.value}"));
    root.appendChild(status);

    final trigger = web.HTMLButtonElement()
      ..id = "select-trigger"
      ..type = "button"
      ..className = "btn primary";
    trigger.appendChild(text(() => selected.value ?? "Choose a framework"));
    root.appendChild(trigger);

    final after = web.HTMLButtonElement()
      ..id = "select-after"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "After";
    root.appendChild(after);

    final opts = <SelectOption<String>>[
      const SelectOption(value: "Solid", label: "Solid"),
      const SelectOption(value: "React", label: "React"),
      const SelectOption(value: "Svelte", label: "Svelte"),
      const SelectOption(value: "Vue", label: "Vue", disabled: true),
      const SelectOption(value: "Dart", label: "Dart"),
    ];

    root.appendChild(
      Select<String>(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        trigger: trigger,
        options: () => opts,
        value: () => selected.value,
        setValue: (next) => selected.value = next,
        portalId: "select-portal",
        listboxId: "select-listbox",
        placement: "bottom-start",
        offset: 8,
        onClose: (reason) => lastEvent.value = reason,
      ),
    );

    return root;
  });
}

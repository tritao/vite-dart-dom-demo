import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsSelectBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final open = createSignal(false);
    final value = createSignal<String?>(null);
    final lastClose = createSignal("none");

    const opts = [
      SelectOption(value: "solid", label: "Solid"),
      SelectOption(value: "react", label: "React"),
      SelectOption(value: "svelte", label: "Svelte"),
      SelectOption(value: "vue", label: "Vue", disabled: true),
      SelectOption(value: "dart", label: "Dart"),
    ];

    String labelFor(String? v) {
      if (v == null) return "Select…";
      for (final o in opts) {
        if (o.value == v) return o.label;
      }
      return "Select…";
    }

    final control = buildSelectControl(
      label: () => labelFor(value.value),
      className: "btn primary",
      ariaLabel: "Select framework",
    );
    final trigger = control.trigger;

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "Close: ${lastClose.value}"));

    final root = web.HTMLDivElement()..className = "row";
    root.appendChild(trigger);
    root.appendChild(status);

    root.appendChild(
      Select<String>(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        trigger: trigger,
        portalId: "docs-select-basic-portal",
        options: () => opts,
        value: () => value.value,
        setValue: (next) => value.value = next,
        onClose: (reason) => lastClose.value = reason,
      ),
    );

    return root;
  });
  // #doc:endregion snippet
}

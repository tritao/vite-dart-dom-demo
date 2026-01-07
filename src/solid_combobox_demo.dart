import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidComboboxDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "combobox-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "combobox"));

    final open = createSignal(false);
    final selected = createSignal<String?>(null);
    final lastEvent = createSignal("none");

    root.appendChild(
      web.HTMLHeadingElement.h1()..textContent = "Solid Combobox Demo",
    );

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Type to filter; Arrow keys change the active option while focus stays on the input.",
          "Enter selects; Escape closes (when open) or clears the input (when closed).",
          "Alt+ArrowDown opens the full list (\"show all\").",
          "Try the second example: it stays open and shows an empty state when there are no matches.",
        ],
      ),
    );

    final status = web.HTMLParagraphElement()
      ..id = "combobox-status"
      ..className = "muted";
    status.appendChild(
      text(() => "Value: ${selected.value ?? "none"} • Last: ${lastEvent.value}"),
    );
    root.appendChild(status);

    final control = web.HTMLDivElement()
      ..id = "combobox-control"
      ..className = "row";
    control.style.gap = "8px";
    control.style.alignItems = "center";

    final input = web.HTMLInputElement()
      ..id = "combobox-input"
      ..className = "input"
      ..placeholder = "Type to filter...";
    control.appendChild(input);

    final after = web.HTMLButtonElement()
      ..id = "combobox-after"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "After";
    control.appendChild(after);

    root.appendChild(control);

    root.appendChild(web.HTMLParagraphElement()
      ..className = "muted"
      ..textContent = "Default: closes when no results.");

    final opts = <ComboboxOption<String>>[
      const ComboboxOption(value: "One", label: "One"),
      const ComboboxOption(value: "Two", label: "Two"),
      const ComboboxOption(value: "Three", label: "Three"),
      const ComboboxOption(value: "Disabled", label: "Disabled", disabled: true),
      const ComboboxOption(value: "Dart", label: "Dart"),
      for (var i = 1; i <= 40; i++)
        ComboboxOption(value: "Extra $i", label: "Extra $i"),
    ];

    root.appendChild(
      Combobox<String>(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        anchor: control,
        input: input,
        options: () => opts,
        value: () => selected.value,
        setValue: (next) => selected.value = next,
        listboxId: "combobox-listbox",
        portalId: "combobox-portal",
        onClose: (reason) => lastEvent.value = reason,
        placement: "bottom-start",
        offset: 8,
      ),
    );

    root.appendChild(web.HTMLHRElement());

    final arrowOpen = createSignal(false);
    final arrowSelected = createSignal<String?>(null);
    final arrowLast = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h2()..textContent = "Combobox (popper arrow)");

    final arrowStatus = web.HTMLParagraphElement()
      ..id = "combobox-status-arrow"
      ..className = "muted";
    arrowStatus.appendChild(
      text(() =>
          "Value: ${arrowSelected.value ?? "none"} • Last: ${arrowLast.value}"),
    );
    root.appendChild(arrowStatus);

    final arrowControl = web.HTMLDivElement()
      ..id = "combobox-control-arrow"
      ..className = "row";
    arrowControl.style.gap = "8px";
    arrowControl.style.alignItems = "center";

    final arrowInput = web.HTMLInputElement()
      ..id = "combobox-input-arrow"
      ..className = "input"
      ..placeholder = "Type to open (arrow)...";
    arrowControl.appendChild(arrowInput);

    final arrowAfter = web.HTMLButtonElement()
      ..id = "combobox-after-arrow"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "After";
    arrowControl.appendChild(arrowAfter);

    root.appendChild(arrowControl);

    root.appendChild(
      Combobox<String>(
        open: () => arrowOpen.value,
        setOpen: (next) => arrowOpen.value = next,
        anchor: arrowControl,
        input: arrowInput,
        options: () => opts,
        value: () => arrowSelected.value,
        setValue: (next) => arrowSelected.value = next,
        listboxId: "combobox-listbox-arrow",
        portalId: "combobox-portal-arrow",
        onClose: (reason) => arrowLast.value = reason,
        placement: "bottom-start",
        offset: 8,
        showArrow: true,
      ),
    );

    root.appendChild(web.HTMLHRElement());

    final emptyOpen = createSignal(false);
    final emptySelected = createSignal<String?>(null);
    final emptyLast = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h2()
      ..textContent = "Combobox (keep open on empty)");

    final emptyStatus = web.HTMLParagraphElement()
      ..id = "combobox-status-empty"
      ..className = "muted";
    emptyStatus.appendChild(
      text(() =>
          "Value: ${emptySelected.value ?? "none"} • Last: ${emptyLast.value}"),
    );
    root.appendChild(emptyStatus);

    final emptyControl = web.HTMLDivElement()
      ..id = "combobox-control-empty"
      ..className = "row";
    emptyControl.style.gap = "8px";
    emptyControl.style.alignItems = "center";

    final emptyInput = web.HTMLInputElement()
      ..id = "combobox-input-empty"
      ..className = "input"
      ..placeholder = "Type to filter (keeps open on empty)...";
    emptyControl.appendChild(emptyInput);

    final emptyAfter = web.HTMLButtonElement()
      ..id = "combobox-after-empty"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "After";
    emptyControl.appendChild(emptyAfter);

    root.appendChild(emptyControl);

    root.appendChild(
      Combobox<String>(
        open: () => emptyOpen.value,
        setOpen: (next) => emptyOpen.value = next,
        anchor: emptyControl,
        input: emptyInput,
        options: () => opts,
        value: () => emptySelected.value,
        setValue: (next) => emptySelected.value = next,
        listboxId: "combobox-listbox-empty",
        portalId: "combobox-portal-empty",
        onClose: (reason) => emptyLast.value = reason,
        placement: "bottom-start",
        offset: 8,
        keepOpenOnEmpty: true,
        emptyText: "No matches.",
      ),
    );

    return root;
  });
}

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

import "./demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

web.HTMLElement _reactiveOptionBuilder(
  SelectOption<String> option, {
  required bool Function() selected,
  required bool Function() active,
}) {
  final el = web.HTMLDivElement()..className = "menuItem";

  final marker = web.HTMLSpanElement()
    ..setAttribute("data-marker", "1")
    ..style.display = "inline-block"
    ..style.minWidth = "52px";
  final label = web.HTMLSpanElement()..textContent = option.label;

  el.appendChild(marker);
  el.appendChild(label);

  createRenderEffect(() {
    final s = selected();
    final a = active();

    if (s) {
      el.setAttribute("data-selected-from-builder", "true");
    } else {
      el.removeAttribute("data-selected-from-builder");
    }

    if (a) {
      el.setAttribute("data-active-from-builder", "true");
    } else {
      el.removeAttribute("data-active-from-builder");
    }

    marker.textContent = "${a ? "▶" : " "} ${s ? "✓" : " "} ";
  });

  return el;
}

void mountSolidOptionBuilderDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "optionbuilder-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "optionbuilder"));

    root.appendChild(
      web.HTMLHeadingElement.h1()..textContent = "Solid OptionBuilder Demo",
    );

    root.appendChild(
      solidDemoHelp(
        title: "What this tests",
        bullets: const [
          "Listbox optionBuilder can react to selected/active state changes.",
          "Virtual focus: aria-activedescendant matches the active option.",
          "Disabled items are skipped for focus and selection.",
        ],
      ),
    );

    final selected = createSignal<String?>(null);
    final lastEvent = createSignal("none");

    final status = web.HTMLParagraphElement()
      ..id = "optionbuilder-status"
      ..className = "muted";
    status.appendChild(
      text(() => "Value: ${selected.value ?? "none"} • Last: ${lastEvent.value}"),
    );
    root.appendChild(status);

    final options = <SelectOption<String>>[
      const SelectOption(value: "Solid", label: "Solid"),
      const SelectOption(value: "React", label: "React"),
      const SelectOption(value: "Disabled", label: "Disabled", disabled: true),
      const SelectOption(value: "Svelte", label: "Svelte"),
      const SelectOption(value: "Vue", label: "Vue"),
      const SelectOption(value: "Dart", label: "Dart"),
    ];

    root.appendChild(web.HTMLHeadingElement.h2()..textContent = "Standard listbox");

    final handle = createListbox<String, SelectOption<String>>(
      id: "optionbuilder-listbox",
      options: () => options,
      selected: () => selected.value,
      onSelect: (opt, _) {
        selected.value = opt.value;
        lastEvent.value = "select";
      },
      onClearSelection: () {
        selected.value = null;
        lastEvent.value = "clear";
      },
      optionBuilderReactive: _reactiveOptionBuilder,
    );
    handle.element.style.maxHeight = "220px";
    root.appendChild(handle.element);

    root.appendChild(web.HTMLHRElement());
    root.appendChild(web.HTMLHeadingElement.h2()..textContent = "Virtual focus listbox");

    final vfInput = web.HTMLInputElement()
      ..id = "optionbuilder-virtual-input"
      ..className = "input"
      ..placeholder = "Use ArrowUp/ArrowDown…";
    vfInput.setAttribute("aria-controls", "optionbuilder-virtual-listbox");
    root.appendChild(vfInput);

    final vfSelected = createSignal<String?>(null);
    final vfStatus = web.HTMLParagraphElement()
      ..id = "optionbuilder-virtual-status"
      ..className = "muted";
    vfStatus.appendChild(text(() => "Value: ${vfSelected.value ?? "none"}"));
    root.appendChild(vfStatus);

    final vfHandle = createListbox<String, SelectOption<String>>(
      id: "optionbuilder-virtual-listbox",
      options: () => options,
      selected: () => vfSelected.value,
      shouldUseVirtualFocus: true,
      enableKeyboardNavigation: false,
      onSelect: (opt, _) {
        vfSelected.value = opt.value;
        lastEvent.value = "select-virtual";
      },
      onClearSelection: () {
        vfSelected.value = null;
        lastEvent.value = "clear-virtual";
      },
      optionBuilderReactive: _reactiveOptionBuilder,
    );
    vfHandle.element.style.maxHeight = "180px";
    root.appendChild(vfHandle.element);

    attr(vfInput, "aria-activedescendant", () => vfHandle.activeId());

    on(vfInput, "keydown", (e) {
      if (e is! web.KeyboardEvent) return;
      switch (e.key) {
        case "ArrowDown":
          e.preventDefault();
          vfHandle.moveActive(1);
          return;
        case "ArrowUp":
          e.preventDefault();
          vfHandle.moveActive(-1);
          return;
        case "Home":
          e.preventDefault();
          vfHandle.setActiveIndex(0);
          return;
        case "End":
          e.preventDefault();
          vfHandle.setActiveIndex(999999);
          return;
        case "Enter":
          e.preventDefault();
          vfHandle.selectActive();
          return;
      }
    });

    return root;
  });
}

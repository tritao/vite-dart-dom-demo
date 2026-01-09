import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

import "./demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidListboxDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "listbox-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "listbox"));

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Listbox Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Use Arrow keys/Home/End/PageUp/PageDown in the listbox.",
          "Disabled items are skipped for keyboard focus and hover focus.",
          "In the virtual focus example, focus stays on the input and aria-activedescendant points at the active option.",
        ],
      ),
    );

    final selected = createSignal<String?>(null);
    final lastEvent = createSignal("none");

    final status = web.HTMLParagraphElement()
      ..id = "listbox-status"
      ..className = "muted";
    status.appendChild(
      text(() => "Value: ${selected.value ?? "none"} • Last: ${lastEvent.value}"),
    );
    root.appendChild(status);

    root.appendChild(web.HTMLHeadingElement.h2()..textContent = "Sectioned listbox");

    final sectioned = <ListboxSection<String, SelectOption<String>>>[
      ListboxSection(
        label: "Frameworks",
        id: "frameworks",
        options: <SelectOption<String>>[
          const SelectOption(value: "Dart", label: "Dart"),
          const SelectOption(value: "Flutter", label: "Flutter"),
          const SelectOption(value: "Solid", label: "Solid"),
          const SelectOption(value: "Vue", label: "Vue", disabled: true),
          ...List.generate(
            12,
            (i) => SelectOption(value: "Framework-$i", label: "Framework $i"),
          ),
        ],
      ),
      ListboxSection(
        label: "Fruits",
        id: "fruits",
        options: List.generate(
          18,
          (i) => SelectOption(value: "Fruit-$i", label: "Fruit $i"),
        ),
      ),
      ListboxSection(
        label: "Animals",
        id: "animals",
        options: List.generate(
          18,
          (i) => SelectOption(
            value: "Animal-$i",
            label: "Animal $i",
            disabled: i == 3 || i == 11,
          ),
        ),
      ),
    ];

    final sectionHandle = createListbox<String, SelectOption<String>>(
      id: "listbox-sections",
      sections: () => sectioned,
      selected: () => selected.value,
      onSelect: (opt, _) {
        selected.value = opt.value;
        lastEvent.value = "select";
      },
      onClearSelection: () {
        selected.value = null;
        lastEvent.value = "clear";
      },
    );

    sectionHandle.element.style.maxHeight = "220px";

    root.appendChild(sectionHandle.element);

    root.appendChild(web.HTMLHRElement());
    root.appendChild(web.HTMLHeadingElement.h2()..textContent = "Virtual focus listbox");

    root.appendChild(web.HTMLParagraphElement()
      ..className = "muted"
      ..textContent =
          "Keyboard focus stays on the input; aria-activedescendant points at the active option.");

    final vfControl = web.HTMLDivElement()..className = "row";
    vfControl.style.gap = "8px";
    vfControl.style.alignItems = "center";

    final vfInput = web.HTMLInputElement()
      ..id = "listbox-virtual-input"
      ..className = "input"
      ..placeholder = "Use ArrowUp/ArrowDown...";

    vfInput.setAttribute("aria-controls", "listbox-virtual");

    vfControl.appendChild(vfInput);
    root.appendChild(vfControl);

    final vfSelected = createSignal<String?>(null);
    final vfActive = createSignal("none");

    final vfStatus = web.HTMLParagraphElement()
      ..id = "listbox-virtual-status"
      ..className = "muted";
    vfStatus.appendChild(text(() =>
        "Value: ${vfSelected.value ?? "none"} • Active: ${vfActive.value}"));
    root.appendChild(vfStatus);

    final vfOptions = <SelectOption<String>>[
      const SelectOption(value: "One", label: "One"),
      const SelectOption(value: "Two", label: "Two"),
      const SelectOption(value: "Three", label: "Three"),
      const SelectOption(value: "Disabled", label: "Disabled", disabled: true),
      const SelectOption(value: "Dart", label: "Dart"),
    ];

    final vfHandle = createListbox<String, SelectOption<String>>(
      id: "listbox-virtual",
      options: () => vfOptions,
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
    );

    attr(vfInput, "aria-activedescendant", () => vfHandle.activeId());

    vfHandle.element.style.maxHeight = "180px";
    root.appendChild(vfHandle.element);

    createRenderEffect(() {
      vfActive.value = vfHandle.activeId() ?? "none";
    });

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

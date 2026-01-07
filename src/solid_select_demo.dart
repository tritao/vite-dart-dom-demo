import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidSelectDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "select-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "select"));

    final open = createSignal(false);
    final selected = createSignal<String?>(null);
    final lastEvent = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Select Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Open with click/Enter/ArrowDown; navigate with Arrow keys (disabled is skipped).",
          "Hover moves the active option (mouse-only); focus stays on the listbox (virtual focus).",
          "Escape closes and restores focus; Tab closes and moves focus to \"After\".",
          "Click outside to dismiss (reason shows below).",
        ],
      ),
    );

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
    final after = web.HTMLButtonElement()
      ..id = "select-after"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "After";

    final row = web.HTMLDivElement()..className = "row";
    row.appendChild(trigger);
    row.appendChild(after);
    root.appendChild(row);

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

    root.appendChild(web.HTMLHRElement());

    final longOpen = createSignal(false);
    final longSelected = createSignal<String?>(null);
    final longLast = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h2()
      ..textContent = "Select (long list / fit viewport)");

    final longStatus = web.HTMLParagraphElement()
      ..id = "select-status-long"
      ..className = "muted";
    longStatus.appendChild(
      text(() =>
          "Value: ${longSelected.value ?? "none"} • Last: ${longLast.value}"),
    );
    root.appendChild(longStatus);

    final longTrigger = web.HTMLButtonElement()
      ..id = "select-trigger-long"
      ..type = "button"
      ..className = "btn secondary";
    longTrigger.appendChild(text(() => longSelected.value ?? "Choose (long list)"));

    final longAfter = web.HTMLButtonElement()
      ..id = "select-after-long"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "After";

    final longRow = web.HTMLDivElement()..className = "row";
    longRow.appendChild(longTrigger);
    longRow.appendChild(longAfter);
    root.appendChild(longRow);

    final longOpts = <SelectOption<String>>[
      const SelectOption(value: "Solid", label: "Solid"),
      const SelectOption(value: "React", label: "React"),
      const SelectOption(value: "Svelte", label: "Svelte"),
      const SelectOption(value: "Vue", label: "Vue", disabled: true),
      const SelectOption(value: "Dart", label: "Dart"),
      for (var i = 1; i <= 60; i++)
        SelectOption(value: "Extra $i", label: "Extra $i"),
    ];

    root.appendChild(
      Select<String>(
        open: () => longOpen.value,
        setOpen: (next) => longOpen.value = next,
        trigger: longTrigger,
        options: () => longOpts,
        value: () => longSelected.value,
        setValue: (next) => longSelected.value = next,
        portalId: "select-portal-long",
        listboxId: "select-listbox-long",
        placement: "bottom-start",
        offset: 8,
        onClose: (reason) => longLast.value = reason,
      ),
    );

    return root;
  });
}

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final v in a) {
    if (!b.contains(v)) return false;
  }
  return true;
}

void mountSolidAccordionDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "accordion-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "accordion"));

    final multiple = createSignal(false);
    final collapsible = createSignal(true);
    final expanded = createSignal<Set<String>>(
      {"a"},
      equals: _setEquals,
    );

    root.appendChild(
      web.HTMLHeadingElement.h1()..textContent = "Solid Accordion Demo",
    );

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Tab to a trigger, then use ArrowUp/ArrowDown/Home/End to move focus.",
          "Enter/Space toggles the focused item (disabled is skipped).",
          "Single mode: opening one closes the others; Multiple allows many.",
          "Tab moves into the open panel content (input), Shift+Tab returns.",
        ],
      ),
    );

    final controls = web.HTMLDivElement()..className = "row";

    web.HTMLButtonElement pill(
      String label, {
      required String id,
      required void Function() onClick,
    }) {
      final el = web.HTMLButtonElement()
        ..id = id
        ..type = "button"
        ..className = "btn secondary"
        ..textContent = label;
      on(el, "click", (_) => onClick());
      return el;
    }

    controls.appendChild(
      pill(
        "Mode: single",
        id: "accordion-mode-single",
        onClick: () {
          multiple.value = false;
          final current = expanded.value;
          if (current.length > 1) {
            expanded.value = {current.first};
          }
          if (current.isEmpty && !collapsible.value) {
            expanded.value = {"a"};
          }
        },
      ),
    );
    controls.appendChild(
      pill(
        "Mode: multiple",
        id: "accordion-mode-multiple",
        onClick: () => multiple.value = true,
      ),
    );
    controls.appendChild(
      pill(
        "Collapsible: on",
        id: "accordion-collapsible-on",
        onClick: () {
          collapsible.value = true;
        },
      ),
    );
    controls.appendChild(
      pill(
        "Collapsible: off",
        id: "accordion-collapsible-off",
        onClick: () {
          collapsible.value = false;
          if (expanded.value.isEmpty) expanded.value = {"a"};
        },
      ),
    );
    root.appendChild(controls);

    final status = web.HTMLParagraphElement()
      ..id = "accordion-status"
      ..className = "muted";
    status.appendChild(
      text(
        () =>
            "Expanded: ${expanded.value.join(", ")} • Mode: ${multiple.value ? "multiple" : "single"} • Collapsible: ${collapsible.value ? "on" : "off"}",
      ),
    );
    root.appendChild(status);

    web.HTMLButtonElement trigger(String key, String label, {bool disabled = false}) {
      final el = web.HTMLButtonElement()
        ..id = "accordion-trigger-$key"
        ..type = "button"
        ..className = "accordionTrigger"
        ..textContent = label;
      el.disabled = disabled;
      return el;
    }

    web.HTMLElement panel(String key, String title, String body) {
      final el = web.HTMLDivElement()
        ..id = "accordion-panel-$key"
        ..className = "card";
      el.appendChild(web.HTMLParagraphElement()..textContent = body);
      final input = web.HTMLInputElement()
        ..id = "accordion-panel-$key-input"
        ..className = "input"
        ..placeholder = "Focusable input in $title";
      el.appendChild(input);
      return el;
    }

    final accordion = Accordion(
      id: "accordion-demo",
      ariaLabel: "Accordion demo",
      multiple: () => multiple.value,
      collapsible: () => collapsible.value,
      expandedKeys: () => expanded.value,
      setExpandedKeys: (next) => expanded.value = next,
      items: [
        AccordionItem(
          key: "a",
          trigger: trigger("a", "Account"),
          content: panel(
            "a",
            "Account",
            "Account section content. Open/close with Enter/Space.",
          ),
          textValue: "Account",
        ),
        AccordionItem(
          key: "b",
          trigger: trigger("b", "Password"),
          content: panel(
            "b",
            "Password",
            "Password section content. Arrow keys move focus between triggers.",
          ),
          textValue: "Password",
        ),
        AccordionItem(
          key: "c",
          trigger: trigger("c", "Billing (disabled)", disabled: true),
          content: panel(
            "c",
            "Billing",
            "Disabled section (should not be focusable/toggleable).",
          ),
          disabled: true,
          textValue: "Billing",
        ),
      ],
    );
    root.appendChild(accordion);

    return root;
  });
}

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsAccordionBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final expanded = createSignal<Set<String>>({"a"});

    AccordionItem item(String key, String label, String body) {
      final trigger = web.HTMLButtonElement()
        ..type = "button"
        ..className = "btn secondary"
        ..textContent = label;
      final panel = web.HTMLDivElement()
        ..className = "muted"
        ..style.padding = "10px 0"
        ..textContent = body;
      return AccordionItem(key: key, trigger: trigger, content: panel);
    }

    final acc = Accordion(
      items: [
        item("a", "What is this?", "A minimal accordion example."),
        item("b", "Keyboard?", "Arrow keys move between headers."),
        item("c", "Can I open more than one?", "Set multiple: true for multi-expand."),
      ],
      expandedKeys: () => expanded.value,
      setExpandedKeys: (next) => expanded.value = next,
      multiple: () => false,
      collapsible: () => true,
    );

    return acc;
  });
  // #doc:endregion snippet
}


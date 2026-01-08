import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsRuntimeDomBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final items = createSignal<List<String>>(["Solid", "React"]);

    final row = web.HTMLDivElement()..className = "row";
    final add = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Add item";
    on(add, "click", (_) {
      final next = [...items.value];
      next.add("Item ${next.length + 1}");
      items.value = next;
    });
    row.appendChild(add);

    final clear = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Clear";
    on(clear, "click", (_) => items.value = const []);
    row.appendChild(clear);

    final count = web.HTMLParagraphElement()..className = "muted";
    count.appendChild(text(() => "count=${items.value.length}"));
    row.appendChild(count);

    final list = web.HTMLUListElement()..className = "list";
    list.appendChild(insert(list, () {
      return [
        for (final item in items.value)
          (web.HTMLLIElement()..textContent = item),
      ];
    }));

    final root = web.HTMLDivElement();
    root.appendChild(row);
    root.appendChild(list);
    return root;
  });
  // #doc:endregion snippet
}


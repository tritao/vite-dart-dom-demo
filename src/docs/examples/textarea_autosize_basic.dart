import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsTextareaAutosizeBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final v = createSignal("Type multiple lines…");
    final el = Textarea(
      value: () => v.value,
      setValue: (next) => v.value = next,
      rows: 2,
      autosize: true,
      maxHeightPx: 180,
      ariaLabel: "Autosize textarea",
    );

    final root = web.HTMLDivElement();
    root.appendChild(el);
    root.appendChild(web.HTMLParagraphElement()
      ..className = "muted"
      ..appendChild(text(() => "${v.value.length} chars")));
    return root;
  });
  // #doc:endregion snippet
}

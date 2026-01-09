import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsTextareaBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final value = createSignal("Hello from Solidus.");

    final el = Textarea(
      placeholder: "Write something…",
      rows: 4,
      value: () => value.value,
      setValue: (next) => value.value = next,
      ariaLabel: "Message",
    );

    final root = web.HTMLDivElement();
    root.appendChild(el);
    root.appendChild(web.HTMLParagraphElement()
      ..className = "muted"
      ..appendChild(text(() => "${value.value.length} chars")));
    return root;
  });
  // #doc:endregion snippet
}


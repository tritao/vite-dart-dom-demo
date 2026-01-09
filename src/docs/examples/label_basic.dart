import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsLabelBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    const id = "docs-label-basic";

    final root = web.HTMLDivElement()..className = "row";
    root.appendChild(
      FormField(
        id: "docs-label-field",
        label: () => "Name",
        description: () => "A label associated via for/id.",
        control: Input(id: id, placeholder: "Ada Lovelace"),
      ),
    );
    return root;
  });
  // #doc:endregion snippet
}


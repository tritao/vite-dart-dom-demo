import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsToastBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final toaster = createToaster(defaultDurationMs: 3000);
    var counter = 0;

    final btn = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Show toast";
    on(btn, "click", (_) {
      counter += 1;
      toaster.show("Toast #$counter");
    });

    final root = web.HTMLDivElement()..className = "row";
    root.appendChild(btn);
    root.appendChild(
      toaster.view(
        portalId: "docs-toast-basic-portal",
        viewportId: "docs-toast-basic-viewport",
      ),
    );
    return root;
  });
  // #doc:endregion snippet
}

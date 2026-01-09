import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsBreadcrumbsBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final crumbs = Breadcrumbs(
      items: [
        BreadcrumbItem(label: "Docs", href: "?docs=index"),
        BreadcrumbItem(label: "UI", href: "?docs=button"),
        BreadcrumbItem(label: "Breadcrumbs", current: true),
      ],
    );

    final root = web.HTMLDivElement()..className = "stack";
    root.appendChild(crumbs);
    root.appendChild(web.HTMLParagraphElement()
      ..className = "muted"
      ..textContent = "Use this for hierarchical navigation.");
    return root;
  });
  // #doc:endregion snippet
}

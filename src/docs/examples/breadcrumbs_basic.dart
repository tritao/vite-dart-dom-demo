import "package:solidus/solidus.dart";
import "package:solidus/solidus_ui.dart";
import "package:web/web.dart" as web;

Dispose mountDocsBreadcrumbsBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final crumbs = Breadcrumbs(
      items: [
        BreadcrumbItem(label: "Docs", href: "#/"),
        BreadcrumbItem(label: "UI", href: "#/button"),
        BreadcrumbItem(label: "Breadcrumbs", current: true),
      ],
    );

    return stack(children: [
      crumbs,
      p("Use this for hierarchical navigation.", className: "muted"),
    ]);
  });
  // #doc:endregion snippet
}

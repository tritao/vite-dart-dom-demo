import "package:web/web.dart" as web;

final class BreadcrumbItem {
  BreadcrumbItem({
    required this.label,
    this.href,
    this.current = false,
  });

  final String label;
  final String? href;
  final bool current;
}

/// Breadcrumbs primitive (shadcn-ish).
///
/// - Uses `<nav aria-label="breadcrumb">` + `<ol>`.
/// - The current page is rendered as a `<span aria-current="page">`.
web.HTMLElement Breadcrumbs({
  required Iterable<BreadcrumbItem> items,
  String ariaLabel = "breadcrumb",
  String rootClassName = "breadcrumbs",
  String listClassName = "breadcrumbList",
  String itemClassName = "breadcrumbItem",
  String linkClassName = "breadcrumbLink",
  String pageClassName = "breadcrumbPage",
  String separatorClassName = "breadcrumbSeparator",
  String separatorText = "/",
}) {
  final nav = web.HTMLDivElement()
    ..className = rootClassName
    ..setAttribute("role", "navigation")
    ..setAttribute("aria-label", ariaLabel);

  final ol = web.HTMLOListElement()..className = listClassName;
  nav.appendChild(ol);

  final list = items.toList(growable: false);
  for (var i = 0; i < list.length; i++) {
    final it = list[i];

    final li = web.HTMLLIElement()..className = itemClassName;

    if (it.current || it.href == null || it.href!.isEmpty) {
      final span = web.HTMLSpanElement()
        ..className = pageClassName
        ..textContent = it.label;
      if (it.current) span.setAttribute("aria-current", "page");
      li.appendChild(span);
    } else {
      final a = web.HTMLAnchorElement()
        ..className = linkClassName
        ..href = it.href!
        ..textContent = it.label;
      li.appendChild(a);
    }

    ol.appendChild(li);

    if (i != list.length - 1) {
      final sep = web.HTMLLIElement()
        ..className = separatorClassName
        ..setAttribute("aria-hidden", "true")
        ..textContent = separatorText;
      ol.appendChild(sep);
    }
  }

  return nav;
}

import "package:web/web.dart" as web;

web.HTMLElement solidDocsNav({required String active}) {
  final nav = web.HTMLDivElement()
    ..className = "solid-demo-nav"
    ..setAttribute("role", "navigation")
    ..setAttribute("aria-label", "Solid docs navigation");

  web.HTMLElement link(String label, String href, {bool current = false}) {
    final a = web.HTMLAnchorElement()
      ..href = href
      ..textContent = label
      ..className = "btn secondary";
    if (current) a.setAttribute("aria-current", "page");
    return a;
  }

  final row = web.HTMLDivElement()..className = "solid-demo-nav-row";
  row.appendChild(link("← Back", "/", current: false));
  row.appendChild(link("Docs", "/?docs=1", current: active == "docs"));
  row.appendChild(link("Labs", "/?solid=catalog", current: active == "labs"));
  nav.appendChild(row);
  return nav;
}


import "package:web/web.dart" as web;

web.HTMLElement solidDemoNav({required String active}) {
  final nav = web.HTMLDivElement()
    ..className = "solid-demo-nav"
    ..setAttribute("role", "navigation")
    ..setAttribute("aria-label", "Solid demos navigation");

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
  row.appendChild(link("Menu", "/?solid=menu", current: active == "menu"));
  row.appendChild(link("Dialog", "/?solid=dialog", current: active == "dialog"));
  row.appendChild(link("Popover", "/?solid=popover", current: active == "popover"));
  row.appendChild(link("Tooltip", "/?solid=tooltip", current: active == "tooltip"));
  row.appendChild(link("Select", "/?solid=select", current: active == "select"));
  row.appendChild(link("Listbox", "/?solid=listbox", current: active == "listbox"));
  row.appendChild(
    link("Combobox", "/?solid=combobox", current: active == "combobox"),
  );
  row.appendChild(
    link("Selection", "/?solid=selection", current: active == "selection"),
  );
  row.appendChild(link("Toast", "/?solid=toast", current: active == "toast"));
  row.appendChild(link("Roving", "/?solid=roving", current: active == "roving"));
  row.appendChild(link("Overlay", "/?solid=overlay", current: active == "overlay"));
  row.appendChild(
    link("Wordproc", "/?solid=wordproc", current: active == "wordproc"),
  );
  row.appendChild(link("Solid DOM", "/?solid=1", current: active == "solid-dom"));

  nav.appendChild(row);
  return nav;
}


import "package:web/web.dart" as web;

web.HTMLElement solidDemoNav({required String active}) {
  // In embed mode (used by the catalog page), hide the per-demo nav to avoid
  // nested navigation inside iframes.
  final search = web.window.location.search;
  final query = search.startsWith("?") ? search.substring(1) : search;
  final params = Uri.splitQueryString(query);
  final embed = params["embed"] == "1" || params["embed"] == "true";
  if (embed) {
    return web.HTMLDivElement()..style.display = "none";
  }

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
  row.appendChild(link("Catalog", "/?solid=catalog", current: active == "catalog"));
  row.appendChild(
    link(
      "DropdownMenu",
      "/?solid=dropdownmenu",
      current: active == "dropdownmenu",
    ),
  );
  row.appendChild(link("Menubar", "/?solid=menubar", current: active == "menubar"));
  row.appendChild(
    link("ContextMenu", "/?solid=contextmenu", current: active == "contextmenu"),
  );
  row.appendChild(link("Dialog", "/?solid=dialog", current: active == "dialog"));
  row.appendChild(link("Popover", "/?solid=popover", current: active == "popover"));
  row.appendChild(link("Tooltip", "/?solid=tooltip", current: active == "tooltip"));
  row.appendChild(link("Select", "/?solid=select", current: active == "select"));
  row.appendChild(link("Listbox", "/?solid=listbox", current: active == "listbox"));
  row.appendChild(
    link("Combobox", "/?solid=combobox", current: active == "combobox"),
  );
  row.appendChild(link("Tabs", "/?solid=tabs", current: active == "tabs"));
  row.appendChild(
    link("Accordion", "/?solid=accordion", current: active == "accordion"),
  );
  row.appendChild(link("Switch", "/?solid=switch", current: active == "switch"));
  row.appendChild(
    link("Selection", "/?solid=selection", current: active == "selection"),
  );
  row.appendChild(link("Toast", "/?solid=toast", current: active == "toast"));
  row.appendChild(
    link("Toast+Modal", "/?solid=toast-modal", current: active == "toast-modal"),
  );
  row.appendChild(
    link(
      "OptionBuilder",
      "/?solid=optionbuilder",
      current: active == "optionbuilder",
    ),
  );
  row.appendChild(link("Roving", "/?solid=roving", current: active == "roving"));
  row.appendChild(link("Overlay", "/?solid=overlay", current: active == "overlay"));
  row.appendChild(
    link("Nesting", "/?solid=nesting", current: active == "nesting"),
  );
  row.appendChild(
    link("Wordproc", "/?solid=wordproc", current: active == "wordproc"),
  );
  row.appendChild(link("Solid DOM", "/?solid=1", current: active == "solid-dom"));

  nav.appendChild(row);
  return nav;
}

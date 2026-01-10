import "package:web/web.dart" as web;

web.HTMLElement labsDemoNav({required String active}) {
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
    ..className = "labs-demo-nav"
    ..setAttribute("role", "navigation")
    ..setAttribute("aria-label", "Labs navigation");

  web.HTMLElement link(String label, String href, {bool current = false}) {
    final a = web.HTMLAnchorElement()
      ..href = href
      ..textContent = label
      ..className = "btn secondary";
    if (current) a.setAttribute("aria-current", "page");
    return a;
  }

  final row = web.HTMLDivElement()..className = "labs-demo-nav-row";
  row.appendChild(link("← Back", "./", current: false));
  row.appendChild(link("Docs", "?docs=1", current: false));
  row.appendChild(link("Catalog", "?lab=catalog", current: active == "catalog"));
  row.appendChild(
    link(
      "DropdownMenu",
      "?lab=dropdownmenu",
      current: active == "dropdownmenu",
    ),
  );
  row.appendChild(link("Menubar", "?lab=menubar", current: active == "menubar"));
  row.appendChild(
    link("ContextMenu", "?lab=contextmenu", current: active == "contextmenu"),
  );
  row.appendChild(link("Dialog", "?lab=dialog", current: active == "dialog"));
  row.appendChild(link("Popover", "?lab=popover", current: active == "popover"));
  row.appendChild(link("Tooltip", "?lab=tooltip", current: active == "tooltip"));
  row.appendChild(link("Select", "?lab=select", current: active == "select"));
  row.appendChild(link("Listbox", "?lab=listbox", current: active == "listbox"));
  row.appendChild(
    link("Combobox", "?lab=combobox", current: active == "combobox"),
  );
  row.appendChild(link("Tabs", "?lab=tabs", current: active == "tabs"));
  row.appendChild(
    link("Accordion", "?lab=accordion", current: active == "accordion"),
  );
  row.appendChild(link("Switch", "?lab=switch", current: active == "switch"));
  row.appendChild(
    link("Selection", "?lab=selection", current: active == "selection"),
  );
  row.appendChild(link("Toast", "?lab=toast", current: active == "toast"));
  row.appendChild(
    link("Toast+Modal", "?lab=toast-modal", current: active == "toast-modal"),
  );
  row.appendChild(
    link(
      "OptionBuilder",
      "?lab=optionbuilder",
      current: active == "optionbuilder",
    ),
  );
  row.appendChild(link("Roving", "?lab=roving", current: active == "roving"));
  row.appendChild(link("Overlay", "?lab=overlay", current: active == "overlay"));
  row.appendChild(
    link("Nesting", "?lab=nesting", current: active == "nesting"),
  );
  row.appendChild(
    link("Wordproc", "wordproc.html", current: active == "wordproc"),
  );
  row.appendChild(link("DOM", "?lab=dom", current: active == "dom"));

  nav.appendChild(row);
  return nav;
}

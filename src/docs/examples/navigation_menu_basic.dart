import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_ui.dart";
import "package:web/web.dart" as web;

web.HTMLElement _panel(String title, List<({String label, String desc})> links) {
  final root = web.HTMLDivElement();
  root.appendChild(web.HTMLHeadingElement.h3()..textContent = title);

  final grid = web.HTMLDivElement()..className = "navigationMenuGrid";
  for (final l in links) {
    final a = web.HTMLButtonElement()
      ..className = "navigationMenuLink"
      ..type = "button";
    a.appendChild(web.HTMLDivElement()..textContent = l.label);
    a.appendChild(web.HTMLDivElement()
      ..className = "muted"
      ..style.fontSize = "12px"
      ..textContent = l.desc);
    grid.appendChild(a);
  }
  root.appendChild(grid);
  return root;
}

Dispose mountDocsNavigationMenuBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    web.HTMLButtonElement trigger(String text) =>
        web.HTMLButtonElement()..type = "button"..textContent = text;

    final menu = NavigationMenu(
      items: [
        NavigationMenuItem(
          key: "getting-started",
          trigger: trigger("Getting started"),
          content: _panel(
            "Getting started",
            [
              (label: "Introduction", desc: "What Solidus is."),
              (label: "Overlay", desc: "Overlay/focus/aria behavior."),
              (label: "Popper", desc: "Positioning fundamentals."),
              (label: "Dialog", desc: "Modal and non-modal dialogs."),
            ],
          ),
        ),
        NavigationMenuItem(
          key: "components",
          trigger: trigger("Components"),
          content: _panel(
            "Components",
            [
              (label: "Button", desc: "Shadcn-like variants."),
              (label: "DropdownMenu", desc: "Menus + submenus."),
              (label: "Select", desc: "Select + listbox."),
              (label: "Tabs", desc: "Keyboard accessible tabs."),
            ],
          ),
        ),
        NavigationMenuItem(
          key: "community",
          trigger: trigger("Community"),
          content: _panel(
            "Community",
            [
              (label: "GitHub", desc: "Source code and issues."),
              (label: "Labs", desc: "Edge cases and scenarios."),
            ],
          ),
        ),
      ],
    )..setAttribute("data-test", "nav-menu");

    final note = web.HTMLParagraphElement()
      ..className = "muted"
      ..textContent = "Hover or click triggers to open panels. Escape closes.";

    final root = web.HTMLDivElement()..className = "stack";
    root.appendChild(menu);
    root.appendChild(note);
    return root;
  });
  // #doc:endregion snippet
}

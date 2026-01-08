import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "package:dart_web_test/demo/solid_docs_nav.dart";
import "./solid_docs_data.dart";

web.HTMLElement docsSidebar({required String activeKey}) {
  final sidebar = web.HTMLDivElement()..className = "docsSidebar";

  final home = web.HTMLAnchorElement()
    ..href = "/?docs=1"
    ..className = "btn secondary docsLink"
    ..textContent = "Docs home";
  if (activeKey == "docs") home.setAttribute("data-active", "true");
  sidebar.appendChild(home);

  for (final group in docsGroups) {
    final title = web.HTMLParagraphElement()
      ..className = "docsGroupTitle muted"
      ..textContent = group.label;
    sidebar.appendChild(title);

    for (final entry in group.entries) {
      final a = web.HTMLAnchorElement()
        ..href = "/?docs=${entry.key}"
        ..className = "btn secondary docsLink"
        ..textContent = entry.label;
      createRenderEffect(() {
        if (activeKey == entry.key) {
          a.setAttribute("data-active", "true");
          a.setAttribute("aria-current", "page");
        } else {
          a.removeAttribute("data-active");
          a.removeAttribute("aria-current");
        }
      });
      sidebar.appendChild(a);
    }
  }

  return sidebar;
}

web.HTMLElement docsShell({
  required String activeKey,
  required String title,
  required List<web.Node> children,
}) {
  final root = web.HTMLDivElement()
    ..id = "docs-root"
    ..className = "container containerWide";

  root.appendChild(solidDocsNav(active: "docs"));

  root.appendChild(web.HTMLHeadingElement.h1()..textContent = title);

  final layout = web.HTMLDivElement()..className = "docsLayout";
  layout.appendChild(docsSidebar(activeKey: activeKey));

  final main = web.HTMLDivElement()..className = "docsMain";
  for (final child in children) {
    main.appendChild(child);
  }
  layout.appendChild(main);
  root.appendChild(layout);

  return root;
}


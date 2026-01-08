import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_docs_components.dart";
import "./solid_docs_data.dart";
import "./solid_docs_shell.dart";

void mountSolidDocsIndex(web.Element mount) {
  render(mount, () {
    final intro = docSection(
      title: "How this is organized",
      children: [
        web.HTMLParagraphElement()
          ..className = "muted"
          ..textContent =
              "Docs are the clean, consumer-facing examples. Labs are the edge-case/conformance harness with Playwright coverage.",
        web.HTMLUListElement()
          ..appendChild(web.HTMLLIElement()
            ..textContent = "Start with Foundations; everything builds on those primitives.")
          ..appendChild(web.HTMLLIElement()
            ..textContent = "Each component page links to its lab page for deeper behavior testing."),
      ],
    );

    final groups = <web.Node>[];
    for (final group in docsGroups) {
      final wrap = web.HTMLDivElement()..className = "docGroup";
      wrap.appendChild(web.HTMLHeadingElement.h3()..textContent = group.label);

      final row = web.HTMLDivElement()..className = "row";
      for (final entry in group.entries) {
        final a = web.HTMLAnchorElement()
          ..href = "/?docs=${entry.key}"
          ..className = "btn secondary"
          ..textContent = entry.label;
        row.appendChild(a);
      }
      wrap.appendChild(row);
      groups.add(wrap);
    }

    return docsShell(
      activeKey: "docs",
      title: "Solid UI Docs",
      children: [
        intro,
        docSection(
          title: "Components",
          children: [
            web.HTMLParagraphElement()
              ..className = "muted"
              ..textContent =
                  "Pick a component from the sidebar (or the groups below). Each page aims to show minimal usage without conformance controls.",
            ...groups,
          ],
        ),
      ],
    );
  });
}

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_docs_components.dart";
import "./solid_docs_data.dart";
import "./solid_docs_dialog.dart";
import "./solid_docs_index.dart";
import "./solid_docs_shell.dart";

void mountSolidDocs(web.Element mount, String? page) {
  if (page == null || page == "1") {
    mountSolidDocsIndex(mount);
    return;
  }
  if (page == "dialog") {
    mountSolidDocsDialog(mount);
    return;
  }

  mountSolidDocsStub(mount, page);
}

void mountSolidDocsStub(web.Element mount, String key) {
  render(mount, () {
    final entry = findDocsEntry(key);
    final title = entry?.label ?? key;
    final labHref = entry?.labHref;

    return docsShell(
      activeKey: entry?.key ?? "docs",
      title: title,
      children: [
        docSection(
          title: "Coming soon",
          children: [
            web.HTMLParagraphElement()
              ..className = "muted"
              ..textContent =
                  "This docs page isn't written yet. Use the lab/conformance page to explore behavior in the meantime.",
            if (labHref != null)
              web.HTMLAnchorElement()
                ..href = labHref
                ..className = "btn secondary"
                ..textContent = "Open lab",
          ],
        ),
      ],
    );
  });
}

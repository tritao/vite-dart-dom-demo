import "dart:async";
import "dart:convert";
import "dart:js_interop";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:http/http.dart" as http;
import "package:web/web.dart" as web;

import "package:dart_web_test/demo/solid_docs_nav.dart";
import "./solid_docs_examples.dart";

final class DocsManifestPage {
  DocsManifestPage({
    required this.slug,
    required this.title,
    required this.group,
    required this.order,
    required this.description,
    required this.labHref,
    required this.status,
    required this.tags,
  });

  final String slug;
  final String title;
  final String group;
  final int order;
  final String? description;
  final String? labHref;
  final String status;
  final List<String> tags;

  static DocsManifestPage fromJson(Map<String, Object?> json) {
    final tags = json["tags"];
    return DocsManifestPage(
      slug: (json["slug"] as String?) ?? "",
      title: (json["title"] as String?) ?? "",
      group: (json["group"] as String?) ?? "Docs",
      order: (json["order"] as int?) ?? 1000,
      description: json["description"] as String?,
      labHref: json["labHref"] as String?,
      status: (json["status"] as String?) ?? "draft",
      tags: tags is List ? [for (final v in tags) if (v is String) v] : const [],
    );
  }
}

final class DocsManifestGroup {
  DocsManifestGroup({required this.label, required this.pages});

  final String label;
  final List<DocsManifestPage> pages;
}

final class DocsManifest {
  DocsManifest({required this.groups, required this.bySlug});

  final List<DocsManifestGroup> groups;
  final Map<String, DocsManifestPage> bySlug;
}

Future<DocsManifest> _fetchManifest() async {
  final res = await http.get(Uri.parse("/assets/docs/manifest.json"));
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw StateError("Failed to load docs manifest (${res.statusCode}).");
  }
  final decoded = jsonDecode(res.body);
  if (decoded is! Map) throw StateError("Invalid manifest JSON.");

  final groups = <DocsManifestGroup>[];
  final bySlug = <String, DocsManifestPage>{};

  final rawGroups = decoded["groups"];
  if (rawGroups is List) {
    for (final g in rawGroups) {
      if (g is! Map) continue;
      final label = g["label"];
      final pages = <DocsManifestPage>[];
      final rawPages = g["pages"];
      if (rawPages is List) {
        for (final p in rawPages) {
          if (p is! Map) continue;
          final page = DocsManifestPage.fromJson((p as Map).cast<String, Object?>());
          if (page.slug.isEmpty) continue;
          pages.add(page);
          bySlug[page.slug] = page;
        }
      }
      pages.sort((a, b) {
        final o = a.order.compareTo(b.order);
        if (o != 0) return o;
        return a.title.compareTo(b.title);
      });
      groups.add(
        DocsManifestGroup(
          label: label is String ? label : "Docs",
          pages: pages,
        ),
      );
    }
  }

  groups.sort((a, b) => a.label.compareTo(b.label));
  return DocsManifest(groups: groups, bySlug: bySlug);
}

Future<String> _fetchPageHtml(String slug) async {
  final res = await http.get(Uri.parse("/assets/docs/pages/$slug.html"));
  if (res.statusCode < 200 || res.statusCode >= 300) {
    return "<p class=\"muted\">Missing docs page: <code>${_escapeHtml(slug)}</code></p>";
  }
  return res.body;
}

String _escapeHtml(String input) {
  return input
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
}

void mountSolidDocs(web.Element mount, String? page) {
  render(mount, () {
    final slug = (page == null || page == "1") ? "index" : page;

    final root = web.HTMLDivElement()
      ..id = "docs-root"
      ..className = "container containerWide";

    root.appendChild(solidDocsNav(active: "docs"));

    final layout = web.HTMLDivElement()..className = "docsLayout";
    final sidebar = web.HTMLDivElement()..className = "docsSidebar";
    final main = web.HTMLDivElement()..className = "docsMain";

    layout.appendChild(sidebar);
    layout.appendChild(main);
    root.appendChild(layout);

    final manifest = createResource(_fetchManifest);
    final pageHtml = createResourceWithSource(() => slug, _fetchPageHtml);

    final title = web.HTMLHeadingElement.h1()
      ..id = "docs-title"
      ..textContent = "Docs";
    main.appendChild(title);

    final content = web.HTMLDivElement()
      ..id = "docs-content"
      ..className = "docsContent";
    main.appendChild(content);

    final mounted = <Dispose>[];
    void cleanupMounted() {
      for (final d in mounted) {
        try {
          d();
        } catch (_) {}
      }
      mounted.clear();
    }

    onCleanup(cleanupMounted);

    createRenderEffect(() {
      sidebar.textContent = "";

      final home = web.HTMLAnchorElement()
        ..href = "/?docs=1"
        ..className = "btn secondary docsLink"
        ..textContent = "Docs home";
      if (slug == "index") {
        home.setAttribute("data-active", "true");
        home.setAttribute("aria-current", "page");
      }
      sidebar.appendChild(home);

      if (manifest.loading) {
        sidebar.appendChild(web.HTMLParagraphElement()
          ..className = "muted"
          ..textContent = "Loading…");
        return;
      }
      if (manifest.error != null) {
        sidebar.appendChild(web.HTMLParagraphElement()
          ..className = "muted"
          ..textContent = "Docs manifest failed to load.");
        sidebar.appendChild(web.HTMLAnchorElement()
          ..href = "/?solid=catalog"
          ..className = "btn secondary docsLink"
          ..textContent = "Open labs");
        return;
      }

      final m = manifest.value;
      if (m == null) return;

      for (final group in m.groups) {
        final groupTitle = web.HTMLParagraphElement()
          ..className = "docsGroupTitle muted"
          ..textContent = group.label;
        sidebar.appendChild(groupTitle);

        for (final p in group.pages) {
          if (p.slug == "index") continue;
          final a = web.HTMLAnchorElement()
            ..href = "/?docs=${p.slug}"
            ..className = "btn secondary docsLink"
            ..textContent = p.title;
          if (slug == p.slug) {
            a.setAttribute("data-active", "true");
            a.setAttribute("aria-current", "page");
          }
          sidebar.appendChild(a);
        }
      }
    });

    createRenderEffect(() {
      cleanupMounted();
      content.textContent = "";

      if (pageHtml.loading) {
        content.appendChild(web.HTMLParagraphElement()
          ..className = "muted"
          ..textContent = "Loading…");
        return;
      }

      final html = pageHtml.value;
      if (html == null) return;

      content.innerHTML = html.toJS;

      scheduleMicrotask(() {
        final m = manifest.value;
        final meta = m?.bySlug[slug];
        title.textContent = meta?.title ?? (slug == "index" ? "Solid UI Docs" : slug);

        final mounts = content.querySelectorAll("[data-doc-demo]");
        for (var i = 0; i < mounts.length; i++) {
          final node = mounts.item(i);
          if (node is! web.Element) continue;
          final id = node.getAttribute("data-doc-demo");
          if (id == null || id.isEmpty) continue;
          final mountDemo = docsDemos[id];
          if (mountDemo == null) continue;
          try {
            mounted.add(mountDemo(node));
          } catch (_) {}
        }
      });
    });

    return root;
  });
}

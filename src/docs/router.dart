import "dart:async";
import "dart:convert";
import "dart:js_interop";

import "package:solidus/solidus.dart";
import "package:solidus/solidus_dom.dart";
import "package:solidus/dom_ui/router.dart" as router;
import "package:solidus/dom_ui/theme.dart" as theme;
import "package:http/http.dart" as http;
import "package:web/web.dart" as web;

import "package:solidus/docs/nav.dart";
import "./demos.dart";
import "./props.dart";

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
  final res = await http.get(Uri.parse("assets/docs/manifest.json"));
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw StateError("Failed to load docs manifest (${res.statusCode}).");
  }
  final decoded = jsonDecode(utf8.decode(res.bodyBytes));
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

  const orderedGroups = <String>[
    "Docs",
    "Forms",
    "UI",
    "Runtime",
    "Navigation",
    "Overlays & Menus",
    "Selection",
    "Foundations",
  ];
  final rank = <String, int>{
    for (var i = 0; i < orderedGroups.length; i++) orderedGroups[i]: i,
  };
  groups.sort((a, b) {
    final ra = rank[a.label] ?? 999;
    final rb = rank[b.label] ?? 999;
    final r = ra.compareTo(rb);
    if (r != 0) return r;
    return a.label.compareTo(b.label);
  });
  return DocsManifest(groups: groups, bySlug: bySlug);
}

Future<String> _fetchPageHtml(String slug) async {
  final res = await http.get(Uri.parse("assets/docs/pages/$slug.html"));
  if (res.statusCode < 200 || res.statusCode >= 300) {
    return "<p class=\"muted\">Missing docs page: <code>${_escapeHtml(slug)}</code></p>";
  }
  return utf8.decode(res.bodyBytes);
}

Future<Map<String, DocsPropsSpec>> _fetchProps() async {
  final res = await http.get(Uri.parse("assets/docs/props.json"));
  if (res.statusCode < 200 || res.statusCode >= 300) {
    return const {};
  }
  final decoded = jsonDecode(utf8.decode(res.bodyBytes));
  return parseDocsPropsJson(decoded);
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
    final slug = createSignal(router.normalizeDocsSlug(page));

    final root = web.HTMLDivElement()..id = "docs-root";

    final topbar = solidusDocsNav(active: "docs");
    root.appendChild(topbar);

    final container = web.HTMLDivElement()
      ..className = "container containerWide docsContainer";
    root.appendChild(container);

    final layout = web.HTMLDivElement()..className = "docsLayout";
    final sidebar = web.HTMLDivElement()..className = "docsSidebar";
    final main = web.HTMLDivElement()..className = "docsMain";

    layout.appendChild(sidebar);
    layout.appendChild(main);
    container.appendChild(layout);

    final manifest = createResource(_fetchManifest);
    final pageHtml = createResourceWithSource(() => slug.value, _fetchPageHtml);
    final propsData = createResource(_fetchProps);

    final searchQuery = createSignal("");
    final themeMode = createSignal(theme.getThemePreference());
    final accentMode = createSignal(theme.getAccentPreference());
    final radiusMode = createSignal(theme.getRadiusPreference());

    final searchEl = topbar.querySelector("#docs-search");
    if (searchEl is web.HTMLInputElement) {
      on(searchEl, "input", (_) {
        searchQuery.value = searchEl.value;
      });
      on(searchEl, "keydown", (e) {
        if (e is! web.KeyboardEvent) return;
        if (e.key == "Escape") {
          searchEl.value = "";
          searchQuery.value = "";
        }
      });
    }

    final themeBtn = topbar.querySelector("#docs-theme");
    if (themeBtn is web.HTMLButtonElement) {
      void applyMode(String mode) {
        theme.setThemePreference(mode);
        theme.applyThemePreference(mode);
        themeMode.value = mode;
      }

      applyMode(themeMode.value);

      on(themeBtn, "click", (_) {
        final current = themeMode.value;
        final next = current == "system"
            ? "light"
            : current == "light"
                ? "dark"
                : "system";
        applyMode(next);
      });

      createRenderEffect(() {
        final m = themeMode.value;
        themeBtn.setAttribute("data-mode", m);
        final label = "Theme: $m (click to change)";
        themeBtn.setAttribute("aria-label", label);
        themeBtn.title = label;
      });
    }

    final accentSel = topbar.querySelector("#docs-accent");
    if (accentSel is web.HTMLSelectElement) {
      void applyAccent(String accent) {
        theme.setAccentPreference(accent);
        theme.applyAccentPreference(accent);
        accentMode.value = accent;
      }

      applyAccent(accentMode.value);
      accentSel.value = accentMode.value;

      on(accentSel, "change", (_) {
        applyAccent(accentSel.value);
      });
    }

    final radiusSel = topbar.querySelector("#docs-radius");
    if (radiusSel is web.HTMLSelectElement) {
      void applyRadius(String radius) {
        theme.setRadiusPreference(radius);
        theme.applyRadiusPreference(radius);
        radiusMode.value = radius;
      }

      applyRadius(radiusMode.value);
      radiusSel.value = radiusMode.value;

      on(radiusSel, "change", (_) {
        applyRadius(radiusSel.value);
      });
    }

    // Client-side docs navigation: intercept `?docs=...` clicks and drive URL +
    // state with pushState. This avoids full reloads and keeps the manifest
    // resource warm, removing the sidebar "Loading…" flash on page changes.
    on(root, "click", (e) {
      if (e is! web.MouseEvent) return;
      if (e.defaultPrevented) return;
      if (e.button != 0) return;
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;

      final target = e.target;
      if (target is! web.Element) return;

      final closest = target.closest("a");
      if (closest is! web.HTMLAnchorElement) return;
      if (closest.target == "_blank") return;

      final href = closest.getAttribute("href");
      if (href == null || href.isEmpty) return;

      // Only handle local query-string links; let external/absolute URLs behave
      // normally.
      Uri uri;
      try {
        uri = Uri.parse(href);
      } catch (_) {
        return;
      }
      if (uri.hasScheme || uri.host.isNotEmpty) return;

      final nextDocs = uri.queryParameters["docs"];
      if (nextDocs == null) return;

      e.preventDefault();
      router.setQueryParam("docs", nextDocs, replace: false);
      slug.value = router.normalizeDocsSlug(nextDocs);
    });

    // Back/forward support within docs.
    final stopPop = router.listenPopState((_) {
      slug.value = router.normalizeDocsSlug(router.getQueryParam("docs"));
    });
    onCleanup(stopPop);

    final title = web.HTMLHeadingElement.h1()
      ..id = "docs-title"
      ..textContent = "Docs";
    main.appendChild(title);

    final content = web.HTMLDivElement()
      ..id = "docs-content"
      ..className = "docsContent";
    main.appendChild(content);

    final mounted = <Dispose>[];
    final propMounts = createSignal<List<web.Element>>(const []);
    void cleanupMounted() {
      for (final d in mounted) {
        try {
          d();
        } catch (_) {}
      }
      mounted.clear();
    }

    onCleanup(cleanupMounted);

    void hydrateProps() {
      final mounts = propMounts.value;
      if (mounts.isEmpty) return;

      final propsMap = propsData.value ?? const <String, DocsPropsSpec>{};
      final loading = propsData.loading;

      for (final node in mounts) {
        final name = node.getAttribute("data-doc-props");
        if (name == null || name.isEmpty) continue;
        final spec = propsMap[name];
        if (spec == null) {
          node.textContent = loading ? "Loading…" : "Unknown props: $name";
          continue;
        }
        node.textContent = "";
        node.appendChild(renderDocsPropsTable(spec));
      }
    }

    createRenderEffect(() {
      sidebar.textContent = "";

      final q = searchQuery.value.trim().toLowerCase();

      final home = web.HTMLAnchorElement()
        ..href = "?docs=1"
        ..className = "docsNavLink"
        ..textContent = "Docs home";
      if (slug.value == "index") {
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
          ..href = "?lab=catalog"
          ..className = "docsNavLink"
          ..textContent = "Open labs");
        return;
      }

      final m = manifest.value;
      if (m == null) return;

      var matchesAny = false;
      for (final group in m.groups) {
        final visiblePages = <DocsManifestPage>[];
        for (final p in group.pages) {
          if (p.slug == "index") continue;
          if (q.isEmpty) {
            visiblePages.add(p);
            continue;
          }
          final title = p.title.toLowerCase();
          if (title.contains(q)) {
            visiblePages.add(p);
            continue;
          }
          if (p.tags.any((t) => t.toLowerCase().contains(q))) {
            visiblePages.add(p);
            continue;
          }
        }

        if (visiblePages.isEmpty) continue;
        matchesAny = true;

        final groupTitle = web.HTMLParagraphElement()
          ..className = "docsGroupTitle muted"
          ..textContent = group.label;
        sidebar.appendChild(groupTitle);

        for (final p in visiblePages) {
          final a = web.HTMLAnchorElement()
            ..href = "?docs=${p.slug}"
            ..className = "docsNavLink"
            ..textContent = p.title;
          if (slug.value == p.slug) {
            a.setAttribute("data-active", "true");
            a.setAttribute("aria-current", "page");
          }
          sidebar.appendChild(a);
        }
      }

      if (q.isNotEmpty && !matchesAny) {
        sidebar.appendChild(web.HTMLParagraphElement()
          ..className = "muted"
          ..textContent = "No matches.");
      }
    });

    // Keep the props placeholders reactive: page HTML may render before props.json
    // loads; hydrate once the resource resolves.
    createRenderEffect(hydrateProps);

    // Keep the title reactive to both slug and manifest availability.
    createRenderEffect(() {
      final m = manifest.value;
      final currentSlug = slug.value;
      final meta = m?.bySlug[currentSlug];
      title.textContent =
          meta?.title ?? (currentSlug == "index" ? "Solidus Docs" : currentSlug);
    });

    createRenderEffect(() {
      cleanupMounted();
      content.textContent = "";
      propMounts.value = const [];

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

        // Record prop mounts for reactive hydration on slow props.json loads.
        final nextPropMounts = <web.Element>[];
        final propNodes = content.querySelectorAll("[data-doc-props]");
        for (var i = 0; i < propNodes.length; i++) {
          final node = propNodes.item(i);
          if (node is web.Element) nextPropMounts.add(node);
        }
        propMounts.value = nextPropMounts;
        hydrateProps();
      });
    });

    return root;
  });
}

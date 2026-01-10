import "package:solidus/solidus.dart";
import "package:solidus/solidus_dom.dart";
import "package:web/web.dart" as web;

import "./demo_help.dart";
import "package:solidus/demo/labs_demo_nav.dart";

final class _CatalogEntry {
  const _CatalogEntry({
    required this.key,
    required this.label,
    required this.href,
    required this.debugScript,
  });

  final String key;
  final String label;
  final String href;
  final String debugScript;
}

void mountLabsCatalogDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "catalog-root"
      ..className = "container containerWide";

    root.appendChild(labsDemoNav(active: "catalog"));

    final entries = const <_CatalogEntry>[
      _CatalogEntry(
        key: "dropdownmenu",
        label: "DropdownMenu",
        href: "?lab=dropdownmenu",
        debugScript: "npm run debug:labs-dropdownmenu",
      ),
      _CatalogEntry(
        key: "menubar",
        label: "Menubar",
        href: "?lab=menubar",
        debugScript: "npm run debug:labs-menubar",
      ),
      _CatalogEntry(
        key: "contextmenu",
        label: "ContextMenu",
        href: "?lab=contextmenu",
        debugScript: "npm run debug:labs-contextmenu",
      ),
      _CatalogEntry(
        key: "dialog",
        label: "Dialog",
        href: "?lab=dialog",
        debugScript: "npm run debug:labs-dialog",
      ),
      _CatalogEntry(
        key: "popover",
        label: "Popover",
        href: "?lab=popover",
        debugScript: "npm run debug:labs-popover",
      ),
      _CatalogEntry(
        key: "tooltip",
        label: "Tooltip",
        href: "?lab=tooltip",
        debugScript: "npm run debug:labs-tooltip",
      ),
      _CatalogEntry(
        key: "select",
        label: "Select",
        href: "?lab=select",
        debugScript: "npm run debug:labs-select",
      ),
      _CatalogEntry(
        key: "listbox",
        label: "Listbox",
        href: "?lab=listbox",
        debugScript: "npm run debug:labs-listbox",
      ),
      _CatalogEntry(
        key: "combobox",
        label: "Combobox",
        href: "?lab=combobox",
        debugScript: "npm run debug:labs-combobox",
      ),
      _CatalogEntry(
        key: "tabs",
        label: "Tabs",
        href: "?lab=tabs",
        debugScript: "npm run debug:labs-tabs",
      ),
      _CatalogEntry(
        key: "accordion",
        label: "Accordion",
        href: "?lab=accordion",
        debugScript: "npm run debug:labs-accordion",
      ),
      _CatalogEntry(
        key: "switch",
        label: "Switch",
        href: "?lab=switch",
        debugScript: "npm run debug:labs-switch",
      ),
      _CatalogEntry(
        key: "selection",
        label: "Selection (core)",
        href: "?lab=selection",
        debugScript: "npm run debug:labs-selection",
      ),
      _CatalogEntry(
        key: "toast",
        label: "Toast",
        href: "?lab=toast",
        debugScript: "npm run debug:labs-toast",
      ),
      _CatalogEntry(
        key: "toast-modal",
        label: "Toast+Modal",
        href: "?lab=toast-modal",
        debugScript: "npm run debug:labs-toast-modal",
      ),
      _CatalogEntry(
        key: "roving",
        label: "Roving",
        href: "?lab=roving",
        debugScript: "npm run debug:labs-roving",
      ),
      _CatalogEntry(
        key: "overlay",
        label: "Overlay",
        href: "?lab=overlay",
        debugScript: "npm run debug:labs-overlay",
      ),
      _CatalogEntry(
        key: "nesting",
        label: "Nesting",
        href: "?lab=nesting",
        debugScript: "npm run debug:labs-nesting",
      ),
      _CatalogEntry(
        key: "optionbuilder",
        label: "OptionBuilder",
        href: "?lab=optionbuilder",
        debugScript: "npm run debug:labs-optionbuilder",
      ),
      _CatalogEntry(
        key: "dom",
        label: "DOM",
        href: "?lab=dom",
        debugScript: "npm run debug:labs-dom",
      ),
    ];

    String initialKey() {
      final search = web.window.location.search;
      final query = search.startsWith("?") ? search.substring(1) : search;
      final params = Uri.splitQueryString(query);
      final demo = params["demo"];
      if (demo == null) return "dropdownmenu";
      for (final e in entries) {
        if (e.key == demo) return demo;
      }
      return "dropdownmenu";
    }

    final filter = createSignal("");
    final selected = createSignal<String>(initialKey());

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solidus Catalog");
    root.appendChild(
      labsDemoHelp(
        title: "What this is",
        bullets: const [
          "A single page to browse component demos without getting \"stuck\" on separate routes.",
          "Each demo is embedded (nav hidden) and still has its own standalone URL for deep links/tests.",
        ],
      ),
    );

    final layout = web.HTMLDivElement()..className = "catalogLayout";
    final sidebar = web.HTMLDivElement()..className = "catalogSidebar";
    final main = web.HTMLDivElement()..className = "catalogMain";

    final input = web.HTMLInputElement()
      ..id = "catalog-filter"
      ..className = "input"
      ..placeholder = "Filter components…";
    on(input, "input", (_) => filter.value = input.value);
    sidebar.appendChild(input);

    final list = web.HTMLDivElement()..className = "catalogList";
    sidebar.appendChild(list);

    final buttons = <String, web.HTMLButtonElement>{};
    for (final e in entries) {
      final btn = web.HTMLButtonElement()
        ..type = "button"
        ..className = "catalogItem btn secondary"
        ..textContent = e.label;
      on(btn, "click", (_) {
        selected.value = e.key;
        try {
          final url = Uri.parse(web.window.location.href);
          final next = url.replace(queryParameters: {
            ...url.queryParameters,
            "lab": "catalog",
            "demo": e.key,
          });
          web.window.history.replaceState(null, "", next.toString());
        } catch (_) {}
      });
      buttons[e.key] = btn;
      list.appendChild(btn);
    }

    createRenderEffect(() {
      final q = filter.value.trim().toLowerCase();
      final active = selected.value;
      for (final e in entries) {
        final btn = buttons[e.key];
        if (btn == null) continue;
        final matches = q.isEmpty || e.label.toLowerCase().contains(q);
        btn.style.display = matches ? "" : "none";
        if (active == e.key) {
          btn.setAttribute("data-active", "true");
        } else {
          btn.removeAttribute("data-active");
        }
      }
    });

    final header = web.HTMLDivElement()..className = "catalogHeader";
    final title = web.HTMLHeadingElement.h2()
      ..id = "catalog-title"
      ..textContent = "";
    header.appendChild(title);

    final actions = web.HTMLDivElement()..className = "catalogActions";
    final openLink = web.HTMLAnchorElement()
      ..id = "catalog-open-standalone"
      ..className = "btn secondary"
      ..textContent = "Open standalone";
    actions.appendChild(openLink);

    final cmd = web.document.createElement("pre") as web.HTMLPreElement
      ..id = "catalog-debug-cmd"
      ..className = "catalogCmd";
    actions.appendChild(cmd);

    header.appendChild(actions);
    main.appendChild(header);

    final frame = web.HTMLIFrameElement()
      ..id = "catalog-frame"
      ..className = "catalogFrame";
    main.appendChild(frame);

    createRenderEffect(() {
      final key = selected.value;
      final entry = entries.firstWhere((e) => e.key == key, orElse: () => entries.first);
      title.textContent = entry.label;
      openLink.href = entry.href;
      cmd.textContent = entry.debugScript;

      final embedded = Uri.parse(entry.href).replace(queryParameters: {
        ...Uri.parse(entry.href).queryParameters,
        "embed": "1",
      });
      frame.src = embedded.toString();
    });

    layout.appendChild(sidebar);
    layout.appendChild(main);
    root.appendChild(layout);

    return root;
  });
}

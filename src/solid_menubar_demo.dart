import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidMenubarDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "menubar-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "menubar"));

    final openKey = createSignal<String?>(null);
    final lastClose = createSignal("none");
    final lastAction = createSignal("none");
    final outsideClicks = createSignal(0);

    final wrapLines = createSignal(false);
    final theme = createSignal("light");

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Menubar Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Tab into the menubar; use ArrowLeft/ArrowRight (roving tabIndex).",
          "Press Enter/Space/ArrowDown on a trigger to open its menu.",
          "With a menu open: ArrowLeft/ArrowRight switches to adjacent menus.",
          "Escape closes and restores focus to the trigger; Enter selects.",
          "Hover a different trigger while open to switch menus (mouse-only).",
        ],
      ),
    );

    final outsideAction = web.HTMLButtonElement()
      ..id = "menubar-outside-action"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Outside action (increments)";
    on(outsideAction, "click", (_) => outsideClicks.value++);

    final status = web.HTMLParagraphElement()
      ..id = "menubar-status"
      ..className = "muted";
    status.appendChild(
      text(
        () =>
            "Action: ${lastAction.value} • Close: ${lastClose.value} • Outside clicks: ${outsideClicks.value}",
      ),
    );

    web.HTMLButtonElement trigger(String id, String label) {
      return web.HTMLButtonElement()
        ..id = id
        ..type = "button"
        ..className = "btn secondary menubarTrigger"
        ..textContent = label;
    }

    web.HTMLButtonElement item(String id, String label, {bool disabled = false}) {
      final el = web.HTMLButtonElement()
        ..id = id
        ..type = "button"
        ..className = "menuItem"
        ..textContent = label;
      el.disabled = disabled;
      return el;
    }

    MenuContent fileMenu(MenuCloseController close) {
      final menu = web.HTMLDivElement()
        ..id = "menubar-file-content"
        ..className = "card menu";

      final newEl = item("menubar-file-new", "New");
      final openEl = item("menubar-file-open", "Open…");
      final exportEl = item("menubar-file-export", "Export ▸");
      final quitEl = item("menubar-file-quit", "Quit");

      final items = <MenuItem>[
        MenuItem(
          element: newEl,
          key: "menubar-file-new",
          onSelect: () => lastAction.value = "File → New",
        ),
        MenuItem(
          element: openEl,
          key: "menubar-file-open",
          onSelect: () => lastAction.value = "File → Open",
        ),
        MenuItem(
          element: exportEl,
          key: "menubar-file-export",
          kind: MenuItemKind.subTrigger,
          submenuBuilder: (subClose) {
            final sub = web.HTMLDivElement()
              ..id = "menubar-file-export-content"
              ..className = "card menu";

            final pdf = item("menubar-file-export-pdf", "PDF");
            final png = item("menubar-file-export-png", "PNG");

            sub.appendChild(pdf);
            sub.appendChild(png);

            return MenuContent(
              element: sub,
              items: [
                MenuItem(
                  element: pdf,
                  key: "menubar-file-export-pdf",
                  onSelect: () => lastAction.value = "File → Export → PDF",
                ),
                MenuItem(
                  element: png,
                  key: "menubar-file-export-png",
                  onSelect: () => lastAction.value = "File → Export → PNG",
                ),
              ],
            );
          },
        ),
        MenuItem(
          element: quitEl,
          key: "menubar-file-quit",
          onSelect: () {
            lastAction.value = "File → Quit";
            close.closeAll("select");
          },
        ),
      ];

      for (final it in items) {
        menu.appendChild(it.element);
      }

      return MenuContent(element: menu, items: items);
    }

    MenuContent editMenu(MenuCloseController close) {
      final menu = web.HTMLDivElement()
        ..id = "menubar-edit-content"
        ..className = "card menu";

      final cutEl = item("menubar-edit-cut", "Cut");
      final copyEl = item("menubar-edit-copy", "Copy");
      final pasteEl = item("menubar-edit-paste", "Paste", disabled: true);
      final wrapEl = item("menubar-edit-wrap", "Wrap lines");
      createRenderEffect(() {
        wrapEl.textContent = "Wrap lines: ${wrapLines.value ? "on" : "off"}";
      });

      final items = <MenuItem>[
        MenuItem(
          element: cutEl,
          key: "menubar-edit-cut",
          onSelect: () => lastAction.value = "Edit → Cut",
        ),
        MenuItem(
          element: copyEl,
          key: "menubar-edit-copy",
          onSelect: () => lastAction.value = "Edit → Copy",
        ),
        MenuItem(
          element: pasteEl,
          key: "menubar-edit-paste",
          onSelect: () => lastAction.value = "Edit → Paste",
        ),
        MenuItem(
          element: wrapEl,
          key: "menubar-edit-wrap",
          kind: MenuItemKind.checkbox,
          checked: () => wrapLines.value,
          onSelect: () {
            wrapLines.value = !wrapLines.value;
            lastAction.value = "Edit → Wrap lines";
          },
          closeOnSelect: false,
        ),
      ];

      for (final it in items) {
        menu.appendChild(it.element);
      }

      return MenuContent(element: menu, items: items);
    }

    MenuContent viewMenu(MenuCloseController close) {
      final menu = web.HTMLDivElement()
        ..id = "menubar-view-content"
        ..className = "card menu";

      final themeLight = item("menubar-view-theme-light", "Theme: light");
      final themeDark = item("menubar-view-theme-dark", "Theme: dark");

      final items = <MenuItem>[
        MenuItem(
          element: themeLight,
          key: "menubar-view-theme-light",
          kind: MenuItemKind.radio,
          checked: () => theme.value == "light",
          onSelect: () {
            theme.value = "light";
            lastAction.value = "View → Theme: light";
          },
          closeOnSelect: false,
        ),
        MenuItem(
          element: themeDark,
          key: "menubar-view-theme-dark",
          kind: MenuItemKind.radio,
          checked: () => theme.value == "dark",
          onSelect: () {
            theme.value = "dark";
            lastAction.value = "View → Theme: dark";
          },
          closeOnSelect: false,
        ),
      ];

      for (final it in items) {
        menu.appendChild(it.element);
      }

      return MenuContent(element: menu, items: items);
    }

    final fileTrigger = trigger("menubar-file-trigger", "File");
    final editTrigger = trigger("menubar-edit-trigger", "Edit");
    final viewTrigger = trigger("menubar-view-trigger", "View");

    root.appendChild(
      Menubar(
        openKey: () => openKey.value,
        setOpenKey: (next) => openKey.value = next,
        portalId: "menu-portal",
        onClose: (reason) => lastClose.value = reason,
        menus: [
          MenubarMenu(
            key: "file",
            trigger: fileTrigger,
            builder: fileMenu,
          ),
          MenubarMenu(
            key: "edit",
            trigger: editTrigger,
            builder: editMenu,
          ),
          MenubarMenu(
            key: "view",
            trigger: viewTrigger,
            builder: viewMenu,
          ),
        ],
      ),
    );

    root.appendChild(outsideAction);
    root.appendChild(status);

    return root;
  });
}

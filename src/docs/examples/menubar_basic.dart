import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsMenubarBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final openKey = createSignal<String?>(null);
    final lastAction = createSignal("none");

    MenuContent menu(String idPrefix, List<({String key, String label})> entries, MenuCloseController close) {
      final el = web.HTMLDivElement()
        ..id = idPrefix
        ..className = "card menu"
        ..style.minWidth = "200px";

      final items = <MenuItem>[];
      for (final entry in entries) {
        final btn = web.HTMLButtonElement()
          ..type = "button"
          ..className = "menuItem"
          ..textContent = entry.label;
        el.appendChild(btn);
        items.add(
          MenuItem(
            element: btn,
            key: entry.key,
            onSelect: () {
              lastAction.value = entry.label;
              close.closeAll("select");
            },
          ),
        );
      }
      return MenuContent(element: el, items: items);
    }

    final fileTrigger = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "File";
    final editTrigger = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Edit";

    final bar = Menubar(
      openKey: () => openKey.value,
      setOpenKey: (next) => openKey.value = next,
      portalId: "docs-menubar-basic-portal",
      menus: [
        MenubarMenu(
          key: "file",
          trigger: fileTrigger,
          builder: (close) => menu(
            "docs-menubar-file",
            const [
              (key: "new", label: "New file"),
              (key: "open", label: "Open…"),
            ],
            close,
          ),
        ),
        MenubarMenu(
          key: "edit",
          trigger: editTrigger,
          builder: (close) => menu(
            "docs-menubar-edit",
            const [
              (key: "undo", label: "Undo"),
              (key: "redo", label: "Redo"),
            ],
            close,
          ),
        ),
      ],
    );

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "Last action: ${lastAction.value}"));

    final root = web.HTMLDivElement();
    root.appendChild(bar);
    root.appendChild(status);
    return root;
  });
  // #doc:endregion snippet
}


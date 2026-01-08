import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsContextMenuBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final open = createSignal(false);
    final lastAction = createSignal("none");

    final target = web.HTMLDivElement()
      ..className = "card"
      ..style.padding = "14px"
      ..style.maxWidth = "420px";
    target.appendChild(web.Text("Right-click (or long-press) in this area."));

    MenuContent buildMenu(MenuCloseController close) {
      final menu = web.HTMLDivElement()
        ..className = "card menu"
        ..style.minWidth = "220px";

      final copy = web.HTMLButtonElement()
        ..type = "button"
        ..className = "menuItem"
        ..textContent = "Copy";
      final paste = web.HTMLButtonElement()
        ..type = "button"
        ..className = "menuItem"
        ..textContent = "Paste";

      menu.appendChild(copy);
      menu.appendChild(paste);

      return MenuContent(
        element: menu,
        items: [
          MenuItem(
            element: copy,
            key: "copy",
            onSelect: () {
              lastAction.value = "Copy";
              close.closeAll("select");
            },
          ),
          MenuItem(
            element: paste,
            key: "paste",
            onSelect: () {
              lastAction.value = "Paste";
              close.closeAll("select");
            },
          ),
        ],
      );
    }

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(text(() => "Last action: ${lastAction.value}"));

    final root = web.HTMLDivElement();
    root.appendChild(target);
    root.appendChild(status);

    root.appendChild(
      ContextMenu(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        target: target,
        portalId: "docs-contextmenu-basic-portal",
        builder: buildMenu,
      ),
    );

    return root;
  });
  // #doc:endregion snippet
}


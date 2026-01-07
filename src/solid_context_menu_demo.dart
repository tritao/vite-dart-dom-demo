import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidContextMenuDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "contextmenu-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "contextmenu"));

    final open = createSignal(false);
    final lastClose = createSignal("none");
    final lastAction = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h1()
      ..textContent = "Solid ContextMenu Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Right click (or long press) on the target area to open the context menu at the pointer.",
          "ArrowUp/ArrowDown navigates; Enter/Space selects.",
          "Escape closes and restores focus to the target.",
          "Click outside to dismiss.",
        ],
      ),
    );

    final target = web.HTMLDivElement()
      ..id = "contextmenu-target"
      ..className = "card"
      ..textContent = "Right click / long press here";
    target.style
      ..userSelect = "none"
      ..padding = "20px"
      ..minHeight = "140px"
      ..display = "flex"
      ..alignItems = "center"
      ..justifyContent = "center";
    // Make it focusable so we can test focus restoration.
    target.tabIndex = 0;
    root.appendChild(target);

    final status = web.HTMLParagraphElement()
      ..id = "contextmenu-status"
      ..className = "muted";
    status.appendChild(
      text(() => "Action: ${lastAction.value} • Close: ${lastClose.value}"),
    );
    root.appendChild(status);

    root.appendChild(
      ContextMenu(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        target: target,
        portalId: "contextmenu-portal",
        onClose: (reason) => lastClose.value = reason,
        builder: (close) {
          final menu = web.HTMLDivElement()
            ..id = "contextmenu-content"
            ..className = "card menu";

          web.HTMLButtonElement button(
            String label, {
            required String id,
            bool destructive = false,
            bool disabled = false,
          }) {
            final el = web.HTMLButtonElement()
              ..id = id
              ..type = "button"
              ..className = destructive ? "menuItem destructive" : "menuItem"
              ..textContent = label;
            el.disabled = disabled;
            return el;
          }

          final copy = button("Copy", id: "contextmenu-item-copy");
          final paste = button("Paste", id: "contextmenu-item-paste");
          final disabled = button(
            "Disabled",
            id: "contextmenu-item-disabled",
            disabled: true,
          );
          final del = button(
            "Delete",
            id: "contextmenu-item-delete",
            destructive: true,
          );

          menu
            ..appendChild(copy)
            ..appendChild(paste)
            ..appendChild(disabled)
            ..appendChild(del);

          return MenuContent(
            element: menu,
            items: [
              MenuItem(
                element: copy,
                key: "contextmenu-item-copy",
                onSelect: () => lastAction.value = "Copy",
              ),
              MenuItem(
                element: paste,
                key: "contextmenu-item-paste",
                onSelect: () => lastAction.value = "Paste",
              ),
              MenuItem(
                element: disabled,
                key: "contextmenu-item-disabled",
                onSelect: () => lastAction.value = "Disabled",
              ),
              MenuItem(
                element: del,
                key: "contextmenu-item-delete",
                onSelect: () => lastAction.value = "Delete",
              ),
            ],
          );
        },
      ),
    );

    return root;
  });
}


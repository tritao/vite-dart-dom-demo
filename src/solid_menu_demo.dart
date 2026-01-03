import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

void mountSolidMenuDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "menu-root"
      ..className = "container";

    final open = createSignal(false);
    final last = createSignal("none");

    root.appendChild(
        web.HTMLHeadingElement.h1()..textContent = "Solid Menu Demo");

    final trigger = web.HTMLButtonElement()
      ..id = "menu-trigger"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Open menu";
    on(trigger, "click", (_) => open.value = !open.value);
    root.appendChild(trigger);

    final status = web.HTMLParagraphElement()
      ..id = "menu-status"
      ..className = "muted";
    status.appendChild(text(() => "Close: ${last.value}"));
    root.appendChild(status);

    root.appendChild(
      DropdownMenu(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        anchor: trigger,
        portalId: "menu-portal",
        placement: "bottom-start",
        offset: 6,
        onClose: (reason) => last.value = reason,
        builder: (close) {
          final menu = web.HTMLDivElement()
            ..id = "menu-content"
            ..className = "card menu";

          web.HTMLButtonElement item(
            String label, {
            required String id,
            bool destructive = false,
          }) {
            final el = web.HTMLButtonElement()
              ..id = id
              ..type = "button"
              ..className = destructive ? "menuItem destructive" : "menuItem"
              ..textContent = label
              ..setAttribute("role", "menuitem");
            on(el, "click", (_) {
              last.value = "select:$label";
              close("select");
            });
            return el;
          }

          final items = <web.HTMLElement>[
            item("Profile", id: "menu-item-profile"),
            item("Billing", id: "menu-item-billing"),
            item("Settings", id: "menu-item-settings"),
            item("Log out", id: "menu-item-logout", destructive: true),
          ];

          for (final el in items) {
            menu.appendChild(el);
          }

          return MenuContent(element: menu, items: items);
        },
      ),
    );

    return root;
  });
}

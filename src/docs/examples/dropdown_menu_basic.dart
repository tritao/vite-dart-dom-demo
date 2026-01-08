import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsDropdownMenuBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final open = createSignal(false);
    final lastAction = createSignal("none");
    final lastClose = createSignal("none");

    final trigger = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Open menu";

    final status = web.HTMLParagraphElement()..className = "muted";
    status.appendChild(
      text(() => "Action: ${lastAction.value} • Close: ${lastClose.value}"),
    );

    final root = web.HTMLDivElement()..className = "row";
    root.appendChild(trigger);
    root.appendChild(status);

    on(trigger, "click", (_) => open.value = !open.value);

    root.appendChild(
      DropdownMenu(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        anchor: trigger,
        portalId: "docs-dropdownmenu-basic-portal",
        onClose: (reason) => lastClose.value = reason,
        builder: (close) {
          final menu = web.HTMLDivElement()
            ..className = "card menu"
            ..style.minWidth = "220px";

          web.HTMLButtonElement item(String label, {required String key, bool disabled = false}) {
            final el = web.HTMLButtonElement()
              ..type = "button"
              ..className = "menuItem"
              ..textContent = label
              ..disabled = disabled;
            el.id = "docs-dropdownmenu-item-$key";
            return el;
          }

          final profile = item("Profile", key: "profile");
          final settings = item("Settings", key: "settings");
          final disabled = item("Disabled", key: "disabled", disabled: true);

          menu.appendChild(profile);
          menu.appendChild(settings);
          menu.appendChild(disabled);

          return MenuContent(
            element: menu,
            items: [
              MenuItem(
                element: profile,
                key: "profile",
                onSelect: () => lastAction.value = "Profile",
              ),
              MenuItem(
                element: settings,
                key: "settings",
                onSelect: () => lastAction.value = "Settings",
              ),
              MenuItem(
                element: disabled,
                key: "disabled",
                disabled: () => true,
              ),
            ],
          );
        },
      ),
    );

    return root;
  });
  // #doc:endregion snippet
}


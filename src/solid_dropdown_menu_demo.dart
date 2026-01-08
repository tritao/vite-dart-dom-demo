import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidDropdownMenuDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "menu-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "dropdownmenu"));

    final open = createSignal(false);
    final lastClose = createSignal("none");
    final lastAction = createSignal("none");
    final outsideClicks = createSignal(0);
    final betaEnabled = createSignal(false);
    final theme = createSignal("light");

    root.appendChild(
        web.HTMLHeadingElement.h1()..textContent = "Solid DropdownMenu Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Open the menu and use ArrowUp/ArrowDown/Home/End to navigate.",
          "Press Enter to select an item; Escape closes and restores focus.",
          "Hover moves focus (mouse-only); disabled items should not focus/select.",
          "Submenu: hover the trigger or press ArrowRight to open; ArrowLeft closes it.",
          "Checkbox/radio items toggle without closing by default (Kobalte-like).",
          "Click/tap outside to dismiss (touch is deferred until click).",
        ],
      ),
    );

    final trigger = web.HTMLButtonElement()
      ..id = "menu-trigger"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Open menu";
    on(trigger, "click", (_) => open.value = !open.value);
    root.appendChild(trigger);

    final outsideAction = web.HTMLButtonElement()
      ..id = "menu-outside-action"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Outside action (increments)";
    on(outsideAction, "click", (_) => outsideClicks.value++);
    root.appendChild(outsideAction);

    final status = web.HTMLParagraphElement()
      ..id = "menu-status"
      ..className = "muted";
    status.appendChild(
      text(
        () =>
            "Action: ${lastAction.value} • Close: ${lastClose.value} • Outside clicks: ${outsideClicks.value}",
      ),
    );
    root.appendChild(status);

    root.appendChild(
      DropdownMenu(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        anchor: trigger,
        portalId: "menu-portal",
        placement: "bottom-start",
        offset: 6,
        onClose: (reason) => lastClose.value = reason,
        builder: (close) {
          final menu = web.HTMLDivElement()
            ..id = "menu-content"
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

          final itemProfileEl = button("Profile", id: "menu-item-profile");
          final itemBillingEl = button("Billing", id: "menu-item-billing");
          final itemDisabledEl =
              button("Disabled", id: "menu-item-disabled", disabled: true);
          final itemSettingsEl = button("Settings", id: "menu-item-settings");

          final itemBetaEl = button("Enable beta", id: "menu-item-beta");
          createRenderEffect(() {
            itemBetaEl.textContent =
                "Enable beta: ${betaEnabled.value ? "on" : "off"}";
          });

          final itemThemeLightEl = button("Theme: light", id: "menu-item-theme-light");
          final itemThemeDarkEl = button("Theme: dark", id: "menu-item-theme-dark");

          final subTriggerEl = button("More ▸", id: "menu-item-more");

          final itemLogoutEl = button(
            "Log out",
            id: "menu-item-logout",
            destructive: true,
          );

          final items = <MenuItem>[
            MenuItem(
              element: itemProfileEl,
              key: "menu-item-profile",
              onSelect: () => lastAction.value = "Profile",
            ),
            MenuItem(
              element: itemBillingEl,
              key: "menu-item-billing",
              onSelect: () => lastAction.value = "Billing",
            ),
            MenuItem(
              element: itemDisabledEl,
              key: "menu-item-disabled",
              onSelect: () => lastAction.value = "Disabled",
            ),
            MenuItem(
              element: itemSettingsEl,
              key: "menu-item-settings",
              onSelect: () => lastAction.value = "Settings",
            ),
            MenuItem(
              element: itemBetaEl,
              key: "menu-item-beta",
              kind: MenuItemKind.checkbox,
              checked: () => betaEnabled.value,
              onSelect: () {
                betaEnabled.value = !betaEnabled.value;
                lastAction.value =
                    "Beta: ${betaEnabled.value ? "on" : "off"}";
              },
              closeOnSelect: false,
            ),
            MenuItem(
              element: itemThemeLightEl,
              key: "menu-item-theme-light",
              kind: MenuItemKind.radio,
              checked: () => theme.value == "light",
              onSelect: () {
                theme.value = "light";
                lastAction.value = "Theme: light";
              },
              closeOnSelect: false,
            ),
            MenuItem(
              element: itemThemeDarkEl,
              key: "menu-item-theme-dark",
              kind: MenuItemKind.radio,
              checked: () => theme.value == "dark",
              onSelect: () {
                theme.value = "dark";
                lastAction.value = "Theme: dark";
              },
              closeOnSelect: false,
            ),
            MenuItem(
              element: subTriggerEl,
              key: "menu-item-more",
              kind: MenuItemKind.subTrigger,
              submenuBuilder: (subClose) {
                final sub = web.HTMLDivElement()
                  ..id = "menu-sub-content"
                  ..className = "card menu";

                final invite = button("Invite users", id: "menu-sub-invite");
                final beta = button("Sub beta toggle", id: "menu-sub-beta");
                createRenderEffect(() {
                  beta.textContent =
                      "Sub beta: ${betaEnabled.value ? "on" : "off"}";
                });

                sub.appendChild(invite);
                sub.appendChild(beta);

                return MenuContent(
                  element: sub,
                  items: [
                    MenuItem(
                      element: invite,
                      key: "menu-sub-invite",
                      onSelect: () => lastAction.value = "Invite users",
                    ),
                    MenuItem(
                      element: beta,
                      key: "menu-sub-beta",
                      kind: MenuItemKind.checkbox,
                      checked: () => betaEnabled.value,
                      onSelect: () {
                        betaEnabled.value = !betaEnabled.value;
                        lastAction.value =
                            "Sub beta: ${betaEnabled.value ? "on" : "off"}";
                      },
                      closeOnSelect: false,
                    ),
                  ],
                );
              },
            ),
            MenuItem(
              element: itemLogoutEl,
              key: "menu-item-logout",
              onSelect: () => lastAction.value = "Log out",
            ),
          ];

          for (final it in items) {
            menu.appendChild(it.element);
          }

          return MenuContent(element: menu, items: items);
        },
      ),
    );

    return root;
  });
}

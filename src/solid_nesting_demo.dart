import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidNestingDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "nesting-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "nesting"));

    final dialogOpen = createSignal(false);
    final popoverOpen = createSignal(false);
    final menuOpen = createSignal(false);
    final last = createSignal("none");

    root.appendChild(
      web.HTMLHeadingElement.h1()..textContent = "Solid Nesting Demo",
    );

    root.appendChild(
      solidDemoHelp(
        title: "What this tests",
        bullets: const [
          "Composition: dialog → popover → menu (three independent layers).",
          "Escape/outside click should dismiss only the topmost open layer.",
          "Focus should remain predictable as layers open/close.",
        ],
      ),
    );

    final openDialog = web.HTMLButtonElement()
      ..id = "nesting-dialog-trigger"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Open dialog";
    on(openDialog, "click", (_) => dialogOpen.value = true);
    root.appendChild(openDialog);

    final status = web.HTMLParagraphElement()
      ..id = "nesting-status"
      ..className = "muted";
    status.appendChild(text(() => "Last: ${last.value}"));
    root.appendChild(status);

    root.appendChild(
      Dialog(
        open: () => dialogOpen.value,
        setOpen: (next) => dialogOpen.value = next,
        backdrop: true,
        portalId: "nesting-dialog-portal",
        backdropId: "nesting-dialog-backdrop",
        onClose: (reason) {
          last.value = "dialog:$reason";
          dialogOpen.value = false;
          popoverOpen.value = false;
          menuOpen.value = false;
        },
        builder: (closeDialog) {
          final panel = web.HTMLDivElement()
            ..id = "nesting-dialog-panel"
            ..className = "card";

          panel.appendChild(
            web.HTMLHeadingElement.h2()..textContent = "Dialog",
          );

          final closeBtn = web.HTMLButtonElement()
            ..id = "nesting-dialog-close"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Close dialog";
          on(closeBtn, "click", (_) {
            last.value = "dialog:close";
            closeDialog();
          });

          final popoverTrigger = web.HTMLButtonElement()
            ..id = "nesting-popover-trigger"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Toggle popover";
          on(popoverTrigger, "click", (_) {
            popoverOpen.value = !popoverOpen.value;
            if (!popoverOpen.value) menuOpen.value = false;
          });

          final row = web.HTMLDivElement()..className = "row";
          row.appendChild(closeBtn);
          row.appendChild(popoverTrigger);
          panel.appendChild(row);

          panel.appendChild(
            Popover(
              open: () => popoverOpen.value,
              setOpen: (next) => popoverOpen.value = next,
              portalId: "nesting-popover-portal",
              anchor: popoverTrigger,
              placement: "bottom-start",
              offset: 6,
              onClose: (reason) {
                last.value = "popover:$reason";
                popoverOpen.value = false;
                menuOpen.value = false;
              },
              builder: (closePopover) {
                final pop = web.HTMLDivElement()
                  ..id = "nesting-popover-panel"
                  ..className = "card";
                pop.appendChild(web.HTMLParagraphElement()
                  ..textContent = "Popover content");

                final closePop = web.HTMLButtonElement()
                  ..id = "nesting-popover-close"
                  ..type = "button"
                  ..className = "btn secondary"
                  ..textContent = "Close popover";
                on(closePop, "click", (_) {
                  last.value = "popover:close";
                  closePopover();
                });

                final menuTrigger = web.HTMLButtonElement()
                  ..id = "nesting-menu-trigger"
                  ..type = "button"
                  ..className = "btn secondary"
                  ..textContent = "Toggle menu";
                on(menuTrigger, "click", (_) => menuOpen.value = !menuOpen.value);

                final popRow = web.HTMLDivElement()..className = "row";
                popRow.appendChild(closePop);
                popRow.appendChild(menuTrigger);
                pop.appendChild(popRow);

                pop.appendChild(
                  DropdownMenu(
                    open: () => menuOpen.value,
                    setOpen: (next) => menuOpen.value = next,
                    anchor: menuTrigger,
                    portalId: "nesting-menu-portal",
                    placement: "bottom-start",
                    offset: 6,
                    onClose: (reason) {
                      last.value = "menu:$reason";
                      menuOpen.value = false;
                    },
                    builder: (closeMenu) {
                      final menu = web.HTMLDivElement()
                        ..id = "nesting-menu-content"
                        ..className = "card menu";

                      web.HTMLButtonElement item(String label, {required String id}) {
                        final el = web.HTMLButtonElement()
                          ..id = id
                          ..type = "button"
                          ..className = "menuItem"
                          ..textContent = label;
                        return el;
                      }

                      final one = item("One", id: "nesting-menu-item-one");
                      final two = item("Two", id: "nesting-menu-item-two");
                      menu.appendChild(one);
                      menu.appendChild(two);
                      return MenuContent(
                        element: menu,
                        items: [
                          MenuItem(
                            element: one,
                            key: "nesting-menu-item-one",
                            onSelect: () => last.value = "menu:select:One",
                          ),
                          MenuItem(
                            element: two,
                            key: "nesting-menu-item-two",
                            onSelect: () => last.value = "menu:select:Two",
                          ),
                        ],
                      );
                    },
                  ),
                );

                return pop;
              },
            ),
          );

          return panel;
        },
      ),
    );

    return root;
  });
}

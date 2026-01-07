import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidRovingDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "roving-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "roving"));

    final show = createSignal(true);
    final active = createSignal(0);
    final cleanupCount = createSignal(0);

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Roving Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Tab into the group: only one item is tabbable (roving tabIndex).",
          "Use Arrow keys to move focus within the group.",
          "Toggle the group to validate cleanup and re-mount behavior.",
        ],
      ),
    );

    final toggle = web.HTMLButtonElement()
      ..id = "roving-toggle"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Toggle group";
    on(toggle, "click", (_) => show.value = !show.value);
    root.appendChild(toggle);

    final status = web.HTMLParagraphElement()
      ..id = "roving-status"
      ..className = "muted";
    status.appendChild(text(() => "Cleanup: ${cleanupCount.value}"));
    root.appendChild(status);

    root.appendChild(
      Show(
        when: () => show.value,
        fallback: () {
          final empty = web.HTMLParagraphElement()
            ..id = "roving-empty"
            ..textContent = "Group unmounted.";
          return empty;
        },
        children: () {
          final group = web.HTMLDivElement()
            ..id = "roving-group"
            ..className = "card";

          final a = web.HTMLButtonElement()
            ..id = "roving-a"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "A";
          final b = web.HTMLButtonElement()
            ..id = "roving-b"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "B";
          final c = web.HTMLButtonElement()
            ..id = "roving-c"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "C";
          final items = <web.HTMLElement>[a, b, c];

          for (var i = 0; i < items.length; i++) {
            final index = i;
            on(items[i], "focus", (_) => active.value = index);
          }

          rovingTabIndex(
            group,
            items: () => items,
            activeIndex: () => active.value,
            setActiveIndex: (next) => active.value = next,
          );
          onCleanup(() => cleanupCount.value++);

          group.appendChild(a);
          group.appendChild(b);
          group.appendChild(c);
          void focusWhenConnected() {
            if (!group.isConnected) {
              scheduleMicrotask(focusWhenConnected);
              return;
            }
            try {
              items[active.value.clamp(0, items.length - 1)].focus();
            } catch (_) {}
          }

          scheduleMicrotask(focusWhenConnected);

          return group;
        },
      ),
    );

    return root;
  });
}

import "dart:js_interop";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidDomDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "solid-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "solid-dom"));

    final count = createSignal<int>(0);
    final showExtra = createSignal<bool>(false);
    final extraMounted = createSignal<bool>(false);
    final docClicks = createSignal<int>(0);
    final items = createSignal<List<int>>(<int>[1, 2, 3]);
    final disposed = createSignal<int>(0);
    final nextId = createSignal<int>(4);
    final showPortal = createSignal<bool>(false);

    final title = web.HTMLHeadingElement.h1()..textContent = "Solid DOM Demo";
    root.appendChild(title);

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Click +1 and watch reactive text/attrs/classes/styles update.",
          "Toggle extra to validate mount/unmount + cleanup behavior.",
          "Reverse the keyed list and watch nodes move without re-creation.",
          "Toggle portal to validate rendering into a separate DOM subtree.",
        ],
      ),
    );

    final inc = web.HTMLButtonElement()
      ..id = "solid-inc"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "+1";
    on(inc, "click", (_) => count.value = count.value + 1);
    root.appendChild(inc);

    final countLine = web.HTMLParagraphElement()
      ..id = "solid-count"
      ..className = "big";
    countLine.appendChild(text(() => "${count.value}"));
    root.appendChild(countLine);

    final box = web.HTMLDivElement()
      ..id = "solid-box"
      ..className = "card";
    box.appendChild(web.HTMLHeadingElement.h2()..textContent = "Bindings");
    box.appendChild(
      web.HTMLParagraphElement()
        ..className = "muted"
        ..textContent = "attr/classList/style/prop track count",
    );
    attr(box, "data-count", () => "${count.value}");
    classList(box, () => count.value.isOdd ? const {"active": true} : const {});
    style(
      box,
      () => {
        "opacity": count.value.isOdd ? "1" : "0.7",
        if (count.value % 3 == 0)
          "outline": "2px solid rgba(124, 92, 255, 0.6)",
      },
    );
    root.appendChild(box);

    final toggle = web.HTMLButtonElement()
      ..id = "solid-toggle"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Toggle extra";
    on(toggle, "click", (_) => showExtra.value = !showExtra.value);
    root.appendChild(toggle);

    final reorder = web.HTMLButtonElement()
      ..id = "solid-reorder"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Reverse list";
    on(
      reorder,
      "click",
      (_) => items.value = items.value.reversed.toList(growable: false),
    );
    root.appendChild(reorder);

    final portalToggle = web.HTMLButtonElement()
      ..id = "solid-portal-toggle"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Toggle portal";
    on(portalToggle, "click", (_) => showPortal.value = !showPortal.value);
    root.appendChild(portalToggle);

    final status = web.HTMLParagraphElement()
      ..id = "solid-status"
      ..className = "muted";
    status.appendChild(
      text(() => "Extra mounted: ${extraMounted.value ? 'yes' : 'no'}"),
    );
    root.appendChild(status);

    final clicksLine = web.HTMLParagraphElement()
      ..id = "solid-doc-clicks"
      ..className = "muted";
    clicksLine.appendChild(text(() => "Doc clicks: ${docClicks.value}"));
    root.appendChild(clicksLine);

    final list = web.HTMLDivElement()
      ..id = "solid-list"
      ..className = "card";
    list.appendChild(web.HTMLHeadingElement.h2()..textContent = "Keyed For");
    final listMeta = web.HTMLParagraphElement()
      ..id = "solid-disposed"
      ..className = "muted";
    listMeta.appendChild(text(() => "Disposed: ${disposed.value}"));
    list.appendChild(listMeta);

    final remove2 = web.HTMLButtonElement()
      ..id = "solid-remove-2"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Remove item 2";
    on(remove2, "click", (_) {
      items.value = items.value.where((x) => x != 2).toList(growable: false);
    });
    list.appendChild(remove2);

    final add2 = web.HTMLButtonElement()
      ..id = "solid-add-2"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Add item 2";
    on(add2, "click", (_) {
      if (items.value.contains(2)) return;
      items.value = <int>[...items.value, 2];
    });
    list.appendChild(add2);

    final addNew = web.HTMLButtonElement()
      ..id = "solid-add-new"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Add new item";
    on(addNew, "click", (_) {
      final id = nextId.value;
      nextId.value = id + 1;
      items.value = <int>[...items.value, id];
    });
    list.appendChild(addNew);

    list.appendChild(
      For<int, int>(
        each: () => items.value,
        key: (v) => v,
        children: (v) {
          // Prove disposal happens on removal.
          onCleanup(() => disposed.value = disposed.value + 1);

          final el = web.HTMLDivElement()
            ..id = "solid-item-${v()}"
            ..className = "item";
          el.appendChild(text(() => "Item ${v()}"));
          return el;
        },
      ),
    );
    root.appendChild(list);

    root.appendChild(
      Show(
        when: () => showPortal.value,
        children: () => Portal(
          children: () {
            final el = web.HTMLDivElement()
              ..id = "solid-portal"
              ..className = "card";
            el.appendChild(web.HTMLHeadingElement.h2()..textContent = "Portal");
            el.appendChild(
              web.HTMLParagraphElement()
                ..className = "muted"
                ..textContent = "Mounted in document.body",
            );
            return el;
          },
        ),
      ),
    );

    root.appendChild(
      Show(
        when: () => showExtra.value,
        children: () {
          extraMounted.value = true;
          onCleanup(() => extraMounted.value = false);

          on(web.document, "click",
              (_) => docClicks.value = docClicks.value + 1);

          final extra = web.HTMLDivElement()
            ..id = "solid-extra"
            ..className = "card";
          extra.appendChild(web.HTMLHeadingElement.h2()..textContent = "Extra");
          extra.appendChild(
            web.HTMLParagraphElement()
              ..className = "muted"
              ..textContent =
                  "Toggling off should dispose this subtree and run cleanup.",
          );

          final disabledBtn = web.HTMLButtonElement()
            ..id = "solid-disabled"
            ..type = "button"
            ..className = "btn primary"
            ..textContent = "Disabled when count is even";
          prop<bool>((v) => disabledBtn.disabled = v, () => count.value.isEven);
          extra.appendChild(disabledBtn);

          return extra;
        },
      ),
    );

    return root;
  });
}

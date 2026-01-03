import "dart:js_interop";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

void mountSolidDomDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "solid-root"
      ..className = "container";

    final count = createSignal<int>(0);
    final showExtra = createSignal<bool>(false);
    final extraMounted = createSignal<bool>(false);

    final title = web.HTMLHeadingElement.h1()..textContent = "Solid DOM Demo";
    root.appendChild(title);

    final inc = web.HTMLButtonElement()
      ..id = "solid-inc"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "+1";
    inc.addEventListener(
      "click",
      ((web.Event _) => count.value = count.value + 1).toJS,
    );
    root.appendChild(inc);

    final countLine = web.HTMLParagraphElement()
      ..id = "solid-count"
      ..className = "big";
    countLine.appendChild(text(() => "${count.value}"));
    root.appendChild(countLine);

    final toggle = web.HTMLButtonElement()
      ..id = "solid-toggle"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Toggle extra";
    toggle.addEventListener(
      "click",
      ((web.Event _) => showExtra.value = !showExtra.value).toJS,
    );
    root.appendChild(toggle);

    final status = web.HTMLParagraphElement()
      ..id = "solid-status"
      ..className = "muted";
    status.appendChild(
      text(() => "Extra mounted: ${extraMounted.value ? 'yes' : 'no'}"),
    );
    root.appendChild(status);

    root.appendChild(
      Show(
        when: () => showExtra.value,
        children: () {
          extraMounted.value = true;
          onCleanup(() => extraMounted.value = false);

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
          return extra;
        },
      ),
    );

    return root;
  });
}

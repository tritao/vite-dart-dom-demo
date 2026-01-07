import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidToastDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "toast-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "toast"));

    final toaster = createToaster(exitMs: 120, defaultDurationMs: 1500);
    final count = createSignal(0);

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Toast Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Click \"Show toast\" multiple times to stack toasts.",
          "Toasts auto-dismiss after a short duration (and animate out).",
          "Dismiss buttons should remove a toast immediately.",
        ],
      ),
    );

    final trigger = web.HTMLButtonElement()
      ..id = "toast-trigger"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Show toast";
    on(trigger, "click", (_) {
      count.value++;
      toaster.show("Toast ${count.value}");
    });
    root.appendChild(trigger);

    root.appendChild(toaster.view());
    return root;
  });
}

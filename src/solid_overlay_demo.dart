import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidOverlayDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "overlay-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "overlay"));

    final open = createSignal<bool>(false);
    final lastDismiss = createSignal<String>("none");
    final underCount = createSignal<int>(0);

    final title = web.HTMLHeadingElement.h1()
      ..textContent = "Solid Overlay Demo";
    root.appendChild(title);

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Open the overlay, then press Tab/Shift+Tab (focus stays inside).",
          "Press Escape or click outside to dismiss.",
          "Try scrolling the page: scroll should be locked while open.",
          "Outside pointer events are disabled while open.",
        ],
      ),
    );

    final trigger = web.HTMLButtonElement()
      ..id = "overlay-trigger"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Open dialog";
    on(trigger, "click", (_) => open.value = true);
    final underBtn = web.HTMLButtonElement()
      ..id = "overlay-under-button"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Outside action (increments)";
    underBtn.style.position = "fixed";
    underBtn.style.left = "24px";
    underBtn.style.bottom = "24px";
    on(underBtn, "click", (_) => underCount.value++);

    final row = web.HTMLDivElement()..className = "row";
    row.appendChild(trigger);
    root.appendChild(row);
    root.appendChild(underBtn);

    final status = web.HTMLParagraphElement()
      ..id = "overlay-status"
      ..className = "muted";
    status.appendChild(
      text(
        () => "Dismiss: ${lastDismiss.value} • Outside clicks: ${underCount.value}",
      ),
    );
    root.appendChild(status);

    root.appendChild(
      Presence(
        when: () => open.value,
        exitMs: 50,
        children: () => Portal(
          id: "overlay-portal-container",
          children: () {
            final wrapper = web.HTMLDivElement()
              ..id = "overlay-wrapper";
            wrapper.style.position = "fixed";
            wrapper.style.inset = "0";
            wrapper.style.display = "flex";
            wrapper.style.alignItems = "center";
            wrapper.style.justifyContent = "center";
            wrapper.style.padding = "24px";
            wrapper.style.boxSizing = "border-box";

            final backdrop = web.HTMLDivElement()..id = "overlay-backdrop";
            backdrop.setAttribute("data-solid-backdrop", "1");
            backdrop.style.position = "fixed";
            backdrop.style.inset = "0";
            backdrop.style.background = "transparent";

            final dialog = web.HTMLDivElement()
              ..id = "overlay-dialog"
              ..className = "card";
            dialog.style.width = "min(520px, 100%)";

            dialog.appendChild(
                web.HTMLHeadingElement.h2()..textContent = "Dialog");

            final close = web.HTMLButtonElement()
              ..id = "overlay-close"
              ..type = "button"
              ..className = "btn secondary"
              ..textContent = "Close";
            on(close, "click", (_) {
              lastDismiss.value = "close";
              open.value = false;
            });
            dialog.appendChild(close);

            final secondary = web.HTMLButtonElement()
              ..id = "overlay-secondary"
              ..type = "button"
              ..className = "btn secondary"
              ..textContent = "Secondary";
            dialog.appendChild(secondary);

            // Overlay behaviors.
            dismissableLayer(
              dialog,
              stackElement: wrapper,
              disableOutsidePointerEvents: true,
              dismissOnFocusOutside: false,
              onDismiss: (reason) {
                lastDismiss.value = reason;
                open.value = false;
              },
            );
            focusScope(dialog, trapFocus: true, initialFocus: close);
            scrollLock();
            ariaHideOthers(dialog);

            wrapper.appendChild(backdrop);
            wrapper.appendChild(dialog);
            return wrapper;
          },
        ),
      ),
    );

    return root;
  });
}

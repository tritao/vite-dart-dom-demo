import "package:solidus/solidus.dart";
import "package:solidus/solidus_dom.dart";
import "package:web/web.dart" as web;

import "./demo_help.dart";
import "package:solidus/demo/labs_demo_nav.dart";

void mountLabsOverlayDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "overlay-root"
      ..className = "container";

    root.appendChild(labsDemoNav(active: "overlay"));

    final open = createSignal<bool>(false);
    final lastDismiss = createSignal<String>("none");
    final underCount = createSignal<int>(0);

    final title = web.HTMLHeadingElement.h1()
      ..textContent = "Solidus Labs: Overlay";
    root.appendChild(title);

    root.appendChild(
      labsDemoHelp(
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

            final backdrop = web.HTMLDivElement()..id = "overlay-backdrop";
            backdrop.setAttribute("data-solidus-backdrop", "1");

            final dialog = web.HTMLDivElement()
              ..id = "overlay-dialog"
              ..className = "card";

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

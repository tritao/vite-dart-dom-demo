import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

void mountSolidOverlayDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "overlay-root"
      ..className = "container";

    final open = createSignal<bool>(false);
    final lastDismiss = createSignal<String>("none");

    final title = web.HTMLHeadingElement.h1()
      ..textContent = "Solid Overlay Demo";
    root.appendChild(title);

    final trigger = web.HTMLButtonElement()
      ..id = "overlay-trigger"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Open dialog";
    on(trigger, "click", (_) => open.value = true);
    root.appendChild(trigger);

    final status = web.HTMLParagraphElement()
      ..id = "overlay-status"
      ..className = "muted";
    status.appendChild(text(() => "Dismiss: ${lastDismiss.value}"));
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

            final backdrop = web.HTMLDivElement()..id = "overlay-backdrop";
            backdrop.setAttribute("data-solid-backdrop", "1");
            backdrop.style.position = "fixed";
            backdrop.style.inset = "0";
            backdrop.style.background = "transparent";

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

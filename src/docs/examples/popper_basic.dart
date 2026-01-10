import "dart:async";

import "package:solidus/solidus.dart";
import "package:solidus/solidus_dom.dart";
import "package:web/web.dart" as web;

Dispose mountDocsPopperBasic(web.Element mount) {
  // #doc:region snippet
  return render(mount, () {
    final open = createSignal(false);

    final root = web.HTMLDivElement();

    final wrap = web.HTMLDivElement()
      ..className = "docPopperExample";
    root.appendChild(wrap);

    final anchor = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Toggle popper";
    on(anchor, "click", (_) => open.value = !open.value);
    wrap.appendChild(anchor);

    wrap.appendChild(
      Presence(
        when: () => open.value,
        exitMs: 120,
        children: () => Portal(
          id: "docs-popper-portal",
          children: () {
            final panel = web.HTMLDivElement()
              ..className = "card"
              ..id = "docs-popper-panel"
              ..style.maxWidth = "360px";
            panel.appendChild(
              web.HTMLParagraphElement()
                ..className = "muted"
                ..textContent = "I’m positioned with attachPopper().",
            );
            final arrow = web.HTMLDivElement()
              ..className = "popperArrow"
              ..setAttribute("data-solidus-popper-arrow", "1");
            panel.appendChild(arrow);

            final handle = attachPopper(
              anchor: anchor,
              floating: panel,
              placement: "bottom-start",
              flip: true,
              slide: true,
              overlap: false,
              offset: 8,
            );
            scheduleMicrotask(handle.update);

            dismissableLayer(
              panel,
              onDismiss: (_) => open.value = false,
              dismissOnFocusOutside: false,
            );

            on(panel, "keydown", (e) {
              if (e is! web.KeyboardEvent) return;
              if (e.key == "Escape") {
                e.preventDefault();
                open.value = false;
              }
            });

            scheduleMicrotask(() {
              try {
                panel.focus();
              } catch (_) {}
            });

            return panel;
          },
        ),
      ),
    );

    return root;
  });
  // #doc:endregion snippet
}


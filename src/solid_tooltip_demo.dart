import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

void mountSolidTooltipDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "tooltip-root"
      ..className = "container";

    final open = createSignal(false);
    final focusOpen = createSignal(false);
    final lastEvent = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Tooltip Demo");

    final status = web.HTMLParagraphElement()
      ..id = "tooltip-status"
      ..className = "muted";
    status.appendChild(text(() => "Open: ${open.value || focusOpen.value} • Last: ${lastEvent.value}"));
    root.appendChild(status);

    final trigger = web.HTMLButtonElement()
      ..id = "tooltip-trigger"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Hover me";
    root.appendChild(trigger);

    final focusTrigger = web.HTMLButtonElement()
      ..id = "tooltip-focus-trigger"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Focus me";
    root.appendChild(focusTrigger);

    root.appendChild(
      Tooltip(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        trigger: trigger,
        portalId: "tooltip-portal",
        placement: "top",
        offset: 8,
        openDelayMs: 150,
        closeDelayMs: 80,
        onClose: (reason) => lastEvent.value = reason,
        builder: (close) {
          final el = web.HTMLDivElement()
            ..id = "tooltip-panel"
            ..className = "card";
          el.style.padding = "8px 10px";
          el.style.fontSize = "13px";
          el.style.maxWidth = "260px";
          el.textContent = "Hello from a tooltip.";
          return el;
        },
      ),
    );

    root.appendChild(
      Tooltip(
        open: () => focusOpen.value,
        setOpen: (next) => focusOpen.value = next,
        trigger: focusTrigger,
        portalId: "tooltip-focus-portal",
        placement: "bottom",
        offset: 8,
        openDelayMs: 150,
        closeDelayMs: 80,
        onClose: (reason) => lastEvent.value = "focus:$reason",
        builder: (close) {
          final el = web.HTMLDivElement()
            ..id = "tooltip-focus-panel"
            ..className = "card";
          el.style.padding = "8px 10px";
          el.style.fontSize = "13px";
          el.textContent = "Tooltip opened from focus.";
          return el;
        },
      ),
    );

    return root;
  });
}


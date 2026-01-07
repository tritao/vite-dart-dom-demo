import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidTooltipDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "tooltip-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "tooltip"));

    final open = createSignal(false);
    final focusOpen = createSignal(false);
    final edgeOpen = createSignal(false);
    final arrowOpen = createSignal(false);
    final lastEvent = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Tooltip Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Hover \"Hover me\": opens after a small delay, closes on leave.",
          "Tab to \"Focus me\": opens on focus, closes on blur/Escape.",
          "Move between triggers quickly: only the hovered/focused tooltip should be open.",
        ],
      ),
    );

    final status = web.HTMLParagraphElement()
      ..id = "tooltip-status"
      ..className = "muted";
    status.appendChild(text(() => "Open: ${open.value || focusOpen.value || edgeOpen.value || arrowOpen.value} • Last: ${lastEvent.value}"));
    root.appendChild(status);

    final trigger = web.HTMLButtonElement()
      ..id = "tooltip-trigger"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Hover me";
    final focusTrigger = web.HTMLButtonElement()
      ..id = "tooltip-focus-trigger"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Focus me";

    final row = web.HTMLDivElement()..className = "row";
    row.appendChild(trigger);
    row.appendChild(focusTrigger);
    root.appendChild(row);

    // Edge trigger to validate flip/shift behavior near the viewport boundary.
    final edgeTrigger = web.HTMLButtonElement()
      ..id = "tooltip-edge-trigger"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Edge trigger";
    edgeTrigger.style.position = "fixed";
    edgeTrigger.style.right = "8px";
    edgeTrigger.style.top = "120px";
    root.appendChild(edgeTrigger);

    final arrowTrigger = web.HTMLButtonElement()
      ..id = "tooltip-arrow-trigger"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Arrow tooltip";
    arrowTrigger.style.position = "fixed";
    arrowTrigger.style.left = "16px";
    arrowTrigger.style.top = "120px";
    root.appendChild(arrowTrigger);

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

    root.appendChild(
      Tooltip(
        open: () => edgeOpen.value,
        setOpen: (next) => edgeOpen.value = next,
        trigger: edgeTrigger,
        portalId: "tooltip-edge-portal",
        placement: "right",
        offset: 8,
        slide: false,
        overlap: false,
        openDelayMs: 30,
        closeDelayMs: 30,
        onClose: (reason) => lastEvent.value = "edge:$reason",
        builder: (close) {
          final el = web.HTMLDivElement()
            ..id = "tooltip-edge-panel"
            ..className = "card";
          el.style.padding = "8px 10px";
          el.style.fontSize = "13px";
          el.textContent = "Edge tooltip (should flip left).";
          return el;
        },
      ),
    );

    root.appendChild(
      Tooltip(
        open: () => arrowOpen.value,
        setOpen: (next) => arrowOpen.value = next,
        trigger: arrowTrigger,
        portalId: "tooltip-arrow-portal",
        placement: "top",
        offset: 10,
        shift: 0,
        flip: true,
        slide: true,
        overlap: true,
        openDelayMs: 30,
        closeDelayMs: 30,
        onClose: (reason) => lastEvent.value = "arrow:$reason",
        builder: (close) {
          final el = web.HTMLDivElement()
            ..id = "tooltip-arrow-panel"
            ..className = "card";
          el.style.padding = "8px 10px";
          el.style.fontSize = "13px";
          final arrow = web.HTMLDivElement()
            ..className = "popperArrow"
            ..setAttribute("data-solid-popper-arrow", "1");
          el.appendChild(arrow);
          el.appendChild(web.HTMLSpanElement()..textContent = "Tooltip with arrow.");
          return el;
        },
      ),
    );

    return root;
  });
}

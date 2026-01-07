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
    final slideOffOpen = createSignal(false);
    final slideOnOpen = createSignal(false);
    final overlapOffOpen = createSignal(false);
    final overlapOnOpen = createSignal(false);
    final lastEvent = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Tooltip Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Hover \"Hover me\": opens after a small delay, closes on leave.",
          "Tab to \"Focus me\": opens on focus, closes on blur/Escape.",
          "Move between triggers quickly: only the hovered/focused tooltip should be open.",
          "Slide (bottom-left): shrink viewport height; slide=true keeps it from overflowing bottom (it 'slides' along the trigger).",
          "Overlap (top-right): shrink viewport width; overlap=true allows it to shift horizontally and stay visible (it may overlap the trigger).",
        ],
      ),
    );

    final status = web.HTMLParagraphElement()
      ..id = "tooltip-status"
      ..className = "muted";
    status.appendChild(
      text(
        () =>
            "Open: ${open.value || focusOpen.value || edgeOpen.value || arrowOpen.value || slideOffOpen.value || slideOnOpen.value || overlapOffOpen.value || overlapOnOpen.value} • Last: ${lastEvent.value}",
      ),
    );
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
    edgeTrigger.style.top = "160px";
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

    // Slide/overlap parity triggers (fixed so we can assert viewport behavior).
    final slideOffTrigger = web.HTMLButtonElement()
      ..id = "tooltip-trigger-slide-off"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Slide off";
    slideOffTrigger.style.position = "fixed";
    slideOffTrigger.style.left = "16px";
    slideOffTrigger.style.bottom = "104px";
    root.appendChild(slideOffTrigger);

    final slideOnTrigger = web.HTMLButtonElement()
      ..id = "tooltip-trigger-slide-on"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Slide on";
    slideOnTrigger.style.position = "fixed";
    slideOnTrigger.style.left = "16px";
    slideOnTrigger.style.bottom = "64px";
    root.appendChild(slideOnTrigger);

    final overlapOffTrigger = web.HTMLButtonElement()
      ..id = "tooltip-trigger-overlap-off"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Overlap off";
    overlapOffTrigger.style.position = "fixed";
    overlapOffTrigger.style.right = "16px";
    overlapOffTrigger.style.top = "64px";
    root.appendChild(overlapOffTrigger);

    final overlapOnTrigger = web.HTMLButtonElement()
      ..id = "tooltip-trigger-overlap-on"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Overlap on";
    overlapOnTrigger.style.position = "fixed";
    overlapOnTrigger.style.right = "16px";
    overlapOnTrigger.style.top = "104px";
    root.appendChild(overlapOnTrigger);

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

    root.appendChild(
      Tooltip(
        open: () => slideOffOpen.value,
        setOpen: (next) => slideOffOpen.value = next,
        trigger: slideOffTrigger,
        portalId: "tooltip-slide-off-portal",
        placement: "right-start",
        offset: 8,
        flip: false,
        slide: false,
        overlap: false,
        openDelayMs: 30,
        closeDelayMs: 30,
        onClose: (reason) => lastEvent.value = "slide-off:$reason",
        builder: (close) {
          final el = web.HTMLDivElement()
            ..id = "tooltip-panel-slide-off"
            ..className = "card";
          el.style.padding = "8px 10px";
          el.style.fontSize = "13px";
          el.style.width = "240px";
          el.style.height = "220px";
          el.textContent =
              "Slide off (right-start; shrink viewport height: this can overflow the bottom).";
          return el;
        },
      ),
    );

    root.appendChild(
      Tooltip(
        open: () => slideOnOpen.value,
        setOpen: (next) => slideOnOpen.value = next,
        trigger: slideOnTrigger,
        portalId: "tooltip-slide-on-portal",
        placement: "right-start",
        offset: 8,
        flip: false,
        slide: true,
        overlap: false,
        openDelayMs: 30,
        closeDelayMs: 30,
        onClose: (reason) => lastEvent.value = "slide-on:$reason",
        builder: (close) {
          final el = web.HTMLDivElement()
            ..id = "tooltip-panel-slide-on"
            ..className = "card";
          el.style.padding = "8px 10px";
          el.style.fontSize = "13px";
          el.style.width = "240px";
          el.style.height = "220px";
          el.textContent =
              "Slide on (right-start; shrink viewport height: this should slide up to stay visible).";
          return el;
        },
      ),
    );

    root.appendChild(
      Tooltip(
        open: () => overlapOffOpen.value,
        setOpen: (next) => overlapOffOpen.value = next,
        trigger: overlapOffTrigger,
        portalId: "tooltip-overlap-off-portal",
        placement: "right-start",
        offset: 8,
        flip: false,
        slide: false,
        overlap: false,
        openDelayMs: 30,
        closeDelayMs: 30,
        onClose: (reason) => lastEvent.value = "overlap-off:$reason",
        builder: (close) {
          final el = web.HTMLDivElement()
            ..id = "tooltip-panel-overlap-off"
            ..className = "card";
          el.style.padding = "8px 10px";
          el.style.fontSize = "13px";
          el.style.width = "360px";
          el.textContent =
              "Overlap off (right-start; shrink viewport width: this can overflow to the right).";
          return el;
        },
      ),
    );

    root.appendChild(
      Tooltip(
        open: () => overlapOnOpen.value,
        setOpen: (next) => overlapOnOpen.value = next,
        trigger: overlapOnTrigger,
        portalId: "tooltip-overlap-on-portal",
        placement: "right-start",
        offset: 8,
        flip: false,
        slide: false,
        overlap: true,
        openDelayMs: 30,
        closeDelayMs: 30,
        onClose: (reason) => lastEvent.value = "overlap-on:$reason",
        builder: (close) {
          final el = web.HTMLDivElement()
            ..id = "tooltip-panel-overlap-on"
            ..className = "card";
          el.style.padding = "8px 10px";
          el.style.fontSize = "13px";
          el.style.width = "360px";
          el.textContent =
              "Overlap on (right-start; shrink viewport width: this should shift left and stay visible).";
          return el;
        },
      ),
    );

    return root;
  });
}

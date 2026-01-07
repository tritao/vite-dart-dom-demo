import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidPopoverDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "popover-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "popover"));

    // Ensure the page can scroll so we can validate repositioning on scroll.
    root.style.minHeight = "2000px";

    final open = createSignal(false);
    final bottomOpen = createSignal(false);
    final edgeOpen = createSignal(false);
    final lastDismiss = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Popover Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Toggle the popover and click outside to dismiss.",
          "Press Escape while open to dismiss (reason shows below).",
          "Scroll the page: the popover should reposition with the anchor.",
          "Try the bottom trigger to exercise flip/fit-in-viewport behavior.",
          "Popover is non-modal: Tab can move focus to any focusable element on the page.",
        ],
      ),
    );

    final jump = web.HTMLButtonElement()
      ..id = "popover-jump-bottom"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Jump to bottom trigger";
    root.appendChild(jump);

    final trigger = web.HTMLButtonElement()
      ..id = "popover-trigger"
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Toggle popover";
    on(trigger, "click", (_) => open.value = !open.value);
    root.appendChild(trigger);

    final edgeTrigger = web.HTMLButtonElement()
      ..id = "popover-trigger-edge"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Edge popover";
    edgeTrigger.style.position = "fixed";
    edgeTrigger.style.right = "16px";
    edgeTrigger.style.top = "16px";
    on(edgeTrigger, "click", (_) => edgeOpen.value = !edgeOpen.value);
    root.appendChild(edgeTrigger);

    final bottomTrigger = web.HTMLButtonElement()
      ..id = "popover-trigger-bottom"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Open bottom popover";
    on(bottomTrigger, "click", (_) => bottomOpen.value = !bottomOpen.value);
    final bottomWrap = web.HTMLDivElement()
      ..style.marginTop = "1600px";
    bottomWrap.appendChild(bottomTrigger);
    root.appendChild(bottomWrap);

    on(jump, "click", (_) {
      try {
        bottomTrigger.scrollIntoView();
      } catch (_) {}
    });

    final status = web.HTMLParagraphElement()
      ..id = "popover-status"
      ..className = "muted";
    status.appendChild(text(() => "Dismiss: ${lastDismiss.value}"));
    root.appendChild(status);

    root.appendChild(
      Popover(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        portalId: "popover-portal",
        anchor: trigger,
        placement: "bottom-start",
        offset: 8,
        onClose: (reason) => lastDismiss.value = reason,
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel"
            ..className = "card";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent = "Popover content");
          final closeBtn = web.HTMLButtonElement()
            ..id = "popover-close"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Close";
          on(closeBtn, "click", (_) => close());
          panel.appendChild(closeBtn);
          return panel;
        },
      ),
    );

    root.appendChild(
      Popover(
        open: () => edgeOpen.value,
        setOpen: (next) => edgeOpen.value = next,
        portalId: "popover-edge-portal",
        anchor: edgeTrigger,
        placement: "right-start",
        offset: 8,
        onClose: (reason) => lastDismiss.value = "edge:$reason",
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel-edge"
            ..className = "card";
          panel.style.width = "360px";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent = "Edge popover (resize to test shift).");
          final closeBtn = web.HTMLButtonElement()
            ..id = "popover-close-edge"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Close";
          on(closeBtn, "click", (_) => close());
          panel.appendChild(closeBtn);
          return panel;
        },
      ),
    );

    root.appendChild(
      Popover(
        open: () => bottomOpen.value,
        setOpen: (next) => bottomOpen.value = next,
        portalId: "popover-bottom-portal",
        anchor: bottomTrigger,
        placement: "bottom-start",
        offset: 8,
        onClose: (reason) => lastDismiss.value = "bottom:$reason",
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel-bottom"
            ..className = "card";
          panel.style.height = "400px";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent = "Bottom popover");
          final closeBtn = web.HTMLButtonElement()
            ..id = "popover-close-bottom"
            ..type = "button"
            ..className = "btn secondary"
            ..textContent = "Close";
          on(closeBtn, "click", (_) => close());
          panel.appendChild(closeBtn);
          return panel;
        },
      ),
    );

    return root;
  });
}

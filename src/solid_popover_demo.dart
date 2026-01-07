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
    final shiftOpen = createSignal(false);
    final slideOffOpen = createSignal(false);
    final slideOnOpen = createSignal(false);
    final overlapOffOpen = createSignal(false);
    final overlapOnOpen = createSignal(false);
    final flipHOpen = createSignal(false);
    final arrowOpen = createSignal(false);
    final hideOpen = createSignal(false);
    final lastDismiss = createSignal("none");
    final outsideClicks = createSignal(0);

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solid Popover Demo");

    root.appendChild(
      solidDemoHelp(
        title: "What to try",
        bullets: const [
          "Toggle the popover and click outside to dismiss (reason shows below).",
          "Press Escape while open to dismiss.",
          "Tab/Shift+Tab are not trapped: focus can move anywhere on the page.",
          "Scroll the page: the popover should reposition with the anchor.",
          "Slide (bottom-left): shrink viewport height; slide=true keeps it from overflowing bottom (it 'slides' along the trigger).",
          "Overlap (top-right): shrink viewport width; overlap=true allows it to shift horizontally and stay visible (it may overlap the trigger).",
          "Flip H (top-right): shrink viewport width; flip=true switches right-* to left-* (inspect data-solid-placement).",
          "HideWhenDetached (bottom-left): open it, then toggle the anchor's display to see the panel become visibility:hidden.",
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

    final shiftTrigger = web.HTMLButtonElement()
      ..id = "popover-trigger-shift"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Shift popover (+40)";
    shiftTrigger.style.marginLeft = "200px";
    on(shiftTrigger, "click", (_) => shiftOpen.value = !shiftOpen.value);
    root.appendChild(shiftTrigger);

    // Slide/overlap parity triggers (fixed so we can assert viewport behavior).
    final slideOffTrigger = web.HTMLButtonElement()
      ..id = "popover-trigger-slide-off"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Slide off";
    slideOffTrigger.style.position = "fixed";
    slideOffTrigger.style.left = "16px";
    slideOffTrigger.style.bottom = "104px";
    on(slideOffTrigger, "click", (_) => slideOffOpen.value = !slideOffOpen.value);
    root.appendChild(slideOffTrigger);

    final slideOnTrigger = web.HTMLButtonElement()
      ..id = "popover-trigger-slide-on"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Slide on";
    slideOnTrigger.style.position = "fixed";
    slideOnTrigger.style.left = "16px";
    slideOnTrigger.style.bottom = "64px";
    on(slideOnTrigger, "click", (_) => slideOnOpen.value = !slideOnOpen.value);
    root.appendChild(slideOnTrigger);

    final overlapOffTrigger = web.HTMLButtonElement()
      ..id = "popover-trigger-overlap-off"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Overlap off";
    overlapOffTrigger.style.position = "fixed";
    overlapOffTrigger.style.right = "16px";
    overlapOffTrigger.style.top = "144px";
    on(overlapOffTrigger, "click", (_) => overlapOffOpen.value = !overlapOffOpen.value);
    root.appendChild(overlapOffTrigger);

    final overlapOnTrigger = web.HTMLButtonElement()
      ..id = "popover-trigger-overlap-on"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Overlap on";
    overlapOnTrigger.style.position = "fixed";
    overlapOnTrigger.style.right = "16px";
    overlapOnTrigger.style.top = "184px";
    on(overlapOnTrigger, "click", (_) => overlapOnOpen.value = !overlapOnOpen.value);
    root.appendChild(overlapOnTrigger);

    final flipHTrigger = web.HTMLButtonElement()
      ..id = "popover-trigger-flip-h"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Flip H";
    flipHTrigger.style.position = "fixed";
    flipHTrigger.style.right = "16px";
    flipHTrigger.style.top = "224px";
    on(flipHTrigger, "click", (_) => flipHOpen.value = !flipHOpen.value);
    root.appendChild(flipHTrigger);

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

    final arrowTrigger = web.HTMLButtonElement()
      ..id = "popover-trigger-arrow"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Arrow popover";
    arrowTrigger.style.position = "fixed";
    arrowTrigger.style.left = "16px";
    arrowTrigger.style.bottom = "16px";
    on(arrowTrigger, "click", (_) => arrowOpen.value = !arrowOpen.value);
    root.appendChild(arrowTrigger);

    final hideTrigger = web.HTMLButtonElement()
      ..id = "popover-trigger-hide"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "HideWhenDetached popover";
    hideTrigger.style.position = "fixed";
    hideTrigger.style.left = "160px";
    hideTrigger.style.bottom = "16px";
    on(hideTrigger, "click", (_) => hideOpen.value = !hideOpen.value);
    root.appendChild(hideTrigger);

    var hideAnchorHidden = false;
    final toggleHideAnchor = web.HTMLButtonElement()
      ..id = "popover-toggle-hide-anchor"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Toggle anchor display";
    toggleHideAnchor.style.position = "fixed";
    toggleHideAnchor.style.left = "356px";
    toggleHideAnchor.style.bottom = "16px";
    on(toggleHideAnchor, "click", (_) {
      hideAnchorHidden = !hideAnchorHidden;
      hideTrigger.style.display = hideAnchorHidden ? "none" : "";
    });
    root.appendChild(toggleHideAnchor);

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
    status.appendChild(
      text(
        () =>
            "Dismiss: ${lastDismiss.value} • Outside clicks: ${outsideClicks.value}",
      ),
    );
    root.appendChild(status);

    final outsideAction = web.HTMLButtonElement()
      ..id = "popover-outside-action"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Outside action (increments)";
    on(outsideAction, "click", (_) => outsideClicks.value++);
    root.appendChild(outsideAction);

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
        open: () => shiftOpen.value,
        setOpen: (next) => shiftOpen.value = next,
        portalId: "popover-shift-portal",
        anchor: shiftTrigger,
        placement: "bottom-start",
        offset: 8,
        shift: 40,
        onClose: (reason) => lastDismiss.value = "shift:$reason",
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel-shift"
            ..className = "card";
          panel.style.width = "240px";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent = "Shifted popover (skidding +40px).");
          final closeBtn = web.HTMLButtonElement()
            ..id = "popover-close-shift"
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
        open: () => slideOffOpen.value,
        setOpen: (next) => slideOffOpen.value = next,
        portalId: "popover-slide-off-portal",
        anchor: slideOffTrigger,
        placement: "right-start",
        offset: 8,
        flip: false,
        slide: false,
        overlap: false,
        onClose: (reason) => lastDismiss.value = "slide-off:$reason",
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel-slide-off"
            ..className = "card";
          panel.style.width = "240px";
          panel.style.height = "220px";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent =
                "Slide off (right-start; shrink viewport height: this can overflow the bottom).");
          final closeBtn = web.HTMLButtonElement()
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
        open: () => slideOnOpen.value,
        setOpen: (next) => slideOnOpen.value = next,
        portalId: "popover-slide-on-portal",
        anchor: slideOnTrigger,
        placement: "right-start",
        offset: 8,
        flip: false,
        slide: true,
        overlap: false,
        onClose: (reason) => lastDismiss.value = "slide-on:$reason",
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel-slide-on"
            ..className = "card";
          panel.style.width = "240px";
          panel.style.height = "220px";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent =
                "Slide on (right-start; shrink viewport height: this should slide up to stay visible).");
          final closeBtn = web.HTMLButtonElement()
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
        open: () => overlapOffOpen.value,
        setOpen: (next) => overlapOffOpen.value = next,
        portalId: "popover-overlap-off-portal",
        anchor: overlapOffTrigger,
        placement: "right-start",
        offset: 8,
        flip: false,
        slide: false,
        overlap: false,
        onClose: (reason) => lastDismiss.value = "overlap-off:$reason",
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel-overlap-off"
            ..className = "card";
          panel.style.width = "360px";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent =
                "Overlap off (right-start; shrink viewport width: this can overflow to the right).");
          final closeBtn = web.HTMLButtonElement()
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
        open: () => overlapOnOpen.value,
        setOpen: (next) => overlapOnOpen.value = next,
        portalId: "popover-overlap-on-portal",
        anchor: overlapOnTrigger,
        placement: "right-start",
        offset: 8,
        flip: false,
        slide: false,
        overlap: true,
        onClose: (reason) => lastDismiss.value = "overlap-on:$reason",
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel-overlap-on"
            ..className = "card";
          panel.style.width = "360px";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent =
                "Overlap on (right-start; shrink viewport width: this should shift left and stay visible).");
          final closeBtn = web.HTMLButtonElement()
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
        open: () => flipHOpen.value,
        setOpen: (next) => flipHOpen.value = next,
        portalId: "popover-flip-h-portal",
        anchor: flipHTrigger,
        placement: "right-start",
        offset: 8,
        flip: true,
        slide: false,
        overlap: false,
        onClose: (reason) => lastDismiss.value = "flip-h:$reason",
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel-flip-h"
            ..className = "card";
          panel.style.width = "180px";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent = "Horizontal flip (right -> left).");
          final closeBtn = web.HTMLButtonElement()
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
        overlap: true,
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
        open: () => arrowOpen.value,
        setOpen: (next) => arrowOpen.value = next,
        portalId: "popover-arrow-portal",
        anchor: arrowTrigger,
        placement: "top-start",
        offset: 10,
        flip: true,
        slide: true,
        overlap: true,
        onClose: (reason) => lastDismiss.value = "arrow:$reason",
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel-arrow"
            ..className = "card";
          final arrow = web.HTMLDivElement()
            ..className = "popperArrow"
            ..setAttribute("data-solid-popper-arrow", "1");
          panel.appendChild(arrow);
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent = "Popover with arrow.");
          final closeBtn = web.HTMLButtonElement()
            ..id = "popover-close-arrow"
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
        open: () => hideOpen.value,
        setOpen: (next) => hideOpen.value = next,
        portalId: "popover-hide-portal",
        anchor: hideTrigger,
        placement: "top-start",
        offset: 10,
        flip: true,
        slide: true,
        overlap: true,
        hideWhenDetached: true,
        detachedPadding: 4,
        onClose: (reason) => lastDismiss.value = "hide:$reason",
        builder: (close) {
          final panel = web.HTMLDivElement()
            ..id = "popover-panel-hide"
            ..className = "card";
          panel.appendChild(web.HTMLParagraphElement()
            ..textContent =
                "HideWhenDetached: if the anchor is hidden, this should become visibility:hidden.");
          final closeBtn = web.HTMLButtonElement()
            ..id = "popover-close-hide"
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

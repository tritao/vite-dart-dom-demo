import "dart:async";

import "package:solidus/solidus.dart";
import "package:solidus/solidus_ui.dart";
import "package:web/web.dart" as web;

import "./demo_help.dart";
import "package:solidus/demo/labs_demo_nav.dart";

void mountLabsSelectDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "select-root"
      ..className = "container";

    root.appendChild(labsDemoNav(active: "select"));

    final open = createSignal(false);
    final selected = createSignal<String?>(null);
    final lastEvent = createSignal("none");
    final outsideClicks = createSignal(0);

    root.appendChild(web.HTMLHeadingElement.h1()..textContent = "Solidus Labs: Select");

    root.appendChild(
      labsDemoHelp(
        title: "What to try",
        bullets: const [
          "Open with click/Enter/ArrowDown; navigate with Arrow keys (disabled is skipped).",
          "Hover moves the active option (mouse-only); focus stays on the listbox (virtual focus).",
          "Escape closes and restores focus; Tab closes and moves focus to \"After\".",
          "\"After\" is a focus sentinel button: use it to confirm Tab order and focus restoration.",
          "Click outside to dismiss (reason shows below).",
          "Re-selecting the selected item does not clear it (disallow empty selection).",
        ],
      ),
    );

    final status = web.HTMLParagraphElement()
      ..id = "select-status"
      ..className = "muted";
    status.appendChild(
      text(
        () =>
            "Value: ${selected.value ?? "none"} • Last: ${lastEvent.value} • Outside clicks: ${outsideClicks.value}",
      ),
    );
    root.appendChild(status);

    final trigger = web.HTMLButtonElement()
      ..id = "select-trigger"
      ..type = "button"
      ..className = "btn primary";
    trigger.style.textAlign = "left";
    trigger.style.boxSizing = "border-box";
    trigger.appendChild(text(() => selected.value ?? "Choose a framework"));
    final after = web.HTMLButtonElement()
      ..id = "select-after"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "After";

    final row = web.HTMLDivElement()..className = "row";
    row.appendChild(trigger);
    row.appendChild(after);
    root.appendChild(row);

    final outsideAction = web.HTMLButtonElement()
      ..id = "select-outside-action"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Outside action (increments)";
    on(outsideAction, "click", (_) => outsideClicks.value++);
    root.appendChild(outsideAction);

    void syncTriggerWidth() {
      if (!trigger.isConnected || !outsideAction.isConnected) return;
      final width = outsideAction.getBoundingClientRect().width;
      if (width <= 0) return;
      trigger.style.width = "${width.toStringAsFixed(0)}px";
    }

    void syncTriggerWidthWhenConnected() {
      if (!trigger.isConnected || !outsideAction.isConnected) {
        scheduleMicrotask(syncTriggerWidthWhenConnected);
        return;
      }
      syncTriggerWidth();
      // One more tick after layout/styles settle.
      Timer(Duration.zero, syncTriggerWidth);
    }

    scheduleMicrotask(syncTriggerWidthWhenConnected);
    on(web.window, "resize", (_) => syncTriggerWidth());

    final opts = <SelectOption<String>>[
      const SelectOption(value: "Solid", label: "Solid"),
      const SelectOption(value: "React", label: "React"),
      const SelectOption(value: "Svelte", label: "Svelte"),
      const SelectOption(value: "Vue", label: "Vue", disabled: true),
      const SelectOption(value: "Dart", label: "Dart"),
    ];

    root.appendChild(
      Select<String>(
        open: () => open.value,
        setOpen: (next) => open.value = next,
        trigger: trigger,
        options: () => opts,
        value: () => selected.value,
        setValue: (next) => selected.value = next,
        portalId: "select-portal",
        listboxId: "select-listbox",
        placement: "bottom-start",
        offset: 8,
        disallowEmptySelection: true,
        onClose: (reason) => lastEvent.value = reason,
      ),
    );

    root.appendChild(web.HTMLHRElement());

    final longOpen = createSignal(false);
    final longSelected = createSignal<String?>(null);
    final longLast = createSignal("none");

    root.appendChild(web.HTMLHeadingElement.h2()
      ..textContent = "Select (long list / fit viewport)");

    final longStatus = web.HTMLParagraphElement()
      ..id = "select-status-long"
      ..className = "muted";
    longStatus.appendChild(
      text(() =>
          "Value: ${longSelected.value ?? "none"} • Last: ${longLast.value}"),
    );
    root.appendChild(longStatus);

    final longTrigger = web.HTMLButtonElement()
      ..id = "select-trigger-long"
      ..type = "button"
      ..className = "btn secondary";
    longTrigger.appendChild(text(() => longSelected.value ?? "Choose (long list)"));

    final longAfter = web.HTMLButtonElement()
      ..id = "select-after-long"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "After";

    final longRow = web.HTMLDivElement()..className = "row";
    longRow.appendChild(longTrigger);
    longRow.appendChild(longAfter);
    root.appendChild(longRow);

    final longOpts = <SelectOption<String>>[
      const SelectOption(value: "Solid", label: "Solid"),
      const SelectOption(value: "React", label: "React"),
      const SelectOption(value: "Svelte", label: "Svelte"),
      const SelectOption(value: "Vue", label: "Vue", disabled: true),
      const SelectOption(value: "Dart", label: "Dart"),
      for (var i = 1; i <= 60; i++)
        SelectOption(value: "Extra $i", label: "Extra $i"),
    ];

    root.appendChild(
      Select<String>(
        open: () => longOpen.value,
        setOpen: (next) => longOpen.value = next,
        trigger: longTrigger,
        options: () => longOpts,
        value: () => longSelected.value,
        setValue: (next) => longSelected.value = next,
        portalId: "select-portal-long",
        listboxId: "select-listbox-long",
        placement: "bottom-start",
        offset: 8,
        onClose: (reason) => longLast.value = reason,
      ),
    );

    // Flip integration: fixed trigger near bottom-right, forcing listbox to flip.
    final flipOpen = createSignal(false);
    final flipSelected = createSignal<String?>(null);
    final flipLast = createSignal("none");

    final flipTrigger = web.HTMLButtonElement()
      ..id = "select-trigger-flip"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Flip select";
    flipTrigger.style.position = "fixed";
    flipTrigger.style.right = "16px";
    flipTrigger.style.bottom = "16px";
    root.appendChild(flipTrigger);

    root.appendChild(
      Select<String>(
        open: () => flipOpen.value,
        setOpen: (next) => flipOpen.value = next,
        trigger: flipTrigger,
        options: () => longOpts,
        value: () => flipSelected.value,
        setValue: (next) => flipSelected.value = next,
        portalId: "select-portal-flip",
        listboxId: "select-listbox-flip",
        placement: "bottom-start",
        offset: 8,
        onClose: (reason) => flipLast.value = reason,
      ),
    );

    // Horizontal flip integration: fixed trigger near the right edge, placement
    // is right-start, and flip should resolve to left-start.
    final flipHOpen = createSignal(false);
    final flipHSelected = createSignal<String?>(null);
    final flipHLast = createSignal("none");

    final flipHTrigger = web.HTMLButtonElement()
      ..id = "select-trigger-flip-h"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Flip H select";
    flipHTrigger.style.position = "fixed";
    flipHTrigger.style.right = "16px";
    flipHTrigger.style.top = "16px";
    root.appendChild(flipHTrigger);

    root.appendChild(
      Select<String>(
        open: () => flipHOpen.value,
        setOpen: (next) => flipHOpen.value = next,
        trigger: flipHTrigger,
        options: () => opts,
        value: () => flipHSelected.value,
        setValue: (next) => flipHSelected.value = next,
        portalId: "select-portal-flip-h",
        listboxId: "select-listbox-flip-h",
        placement: "right-start",
        offset: 8,
        flip: true,
        fitViewport: false,
        onClose: (reason) => flipHLast.value = reason,
      ),
    );

    // Slide/overlap matrix: fixed triggers near the viewport edges so we can
    // assert overflow vs. clamping behavior deterministically.
    final slideOffOpen = createSignal(false);
    final slideOnOpen = createSignal(false);
    final overlapOffOpen = createSignal(false);
    final overlapOnOpen = createSignal(false);

    final slideOffTrigger = web.HTMLButtonElement()
      ..id = "select-trigger-slide-off"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Slide off";
    slideOffTrigger.style.position = "fixed";
    slideOffTrigger.style.right = "16px";
    slideOffTrigger.style.bottom = "96px";
    slideOffTrigger.style.minWidth = "220px";
    root.appendChild(slideOffTrigger);

    final slideOnTrigger = web.HTMLButtonElement()
      ..id = "select-trigger-slide-on"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Slide on";
    slideOnTrigger.style.position = "fixed";
    slideOnTrigger.style.right = "16px";
    slideOnTrigger.style.bottom = "56px";
    slideOnTrigger.style.minWidth = "220px";
    root.appendChild(slideOnTrigger);

    final overlapOffTrigger = web.HTMLButtonElement()
      ..id = "select-trigger-overlap-off"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Overlap off";
    overlapOffTrigger.style.position = "fixed";
    overlapOffTrigger.style.right = "16px";
    overlapOffTrigger.style.bottom = "200px";
    overlapOffTrigger.style.minWidth = "260px";
    root.appendChild(overlapOffTrigger);

    final overlapOnTrigger = web.HTMLButtonElement()
      ..id = "select-trigger-overlap-on"
      ..type = "button"
      ..className = "btn secondary"
      ..textContent = "Overlap on";
    overlapOnTrigger.style.position = "fixed";
    overlapOnTrigger.style.right = "16px";
    overlapOnTrigger.style.bottom = "160px";
    overlapOnTrigger.style.minWidth = "260px";
    root.appendChild(overlapOnTrigger);

    final matrixOpts = <SelectOption<String>>[
      for (var i = 1; i <= 30; i++)
        SelectOption(value: "Item $i", label: "Item $i"),
    ];

    root.appendChild(
      Select<String>(
        open: () => slideOffOpen.value,
        setOpen: (next) => slideOffOpen.value = next,
        trigger: slideOffTrigger,
        options: () => matrixOpts,
        value: () => null,
        setValue: (_) {},
        portalId: "select-portal-slide-off",
        listboxId: "select-listbox-slide-off",
        placement: "right-start",
        offset: 8,
        flip: false,
        slide: false,
        overlap: false,
        fitViewport: false,
      ),
    );

    root.appendChild(
      Select<String>(
        open: () => slideOnOpen.value,
        setOpen: (next) => slideOnOpen.value = next,
        trigger: slideOnTrigger,
        options: () => matrixOpts,
        value: () => null,
        setValue: (_) {},
        portalId: "select-portal-slide-on",
        listboxId: "select-listbox-slide-on",
        placement: "right-start",
        offset: 8,
        flip: false,
        slide: true,
        overlap: false,
        fitViewport: false,
      ),
    );

    root.appendChild(
      Select<String>(
        open: () => overlapOffOpen.value,
        setOpen: (next) => overlapOffOpen.value = next,
        trigger: overlapOffTrigger,
        options: () => matrixOpts,
        value: () => null,
        setValue: (_) {},
        portalId: "select-portal-overlap-off",
        listboxId: "select-listbox-overlap-off",
        placement: "bottom-start",
        offset: 8,
        flip: false,
        slide: false,
        overlap: false,
        fitViewport: false,
      ),
    );

    root.appendChild(
      Select<String>(
        open: () => overlapOnOpen.value,
        setOpen: (next) => overlapOnOpen.value = next,
        trigger: overlapOnTrigger,
        options: () => matrixOpts,
        value: () => null,
        setValue: (_) {},
        portalId: "select-portal-overlap-on",
        listboxId: "select-listbox-overlap-on",
        placement: "bottom-start",
        offset: 8,
        flip: false,
        slide: false,
        overlap: true,
        fitViewport: false,
      ),
    );

    return root;
  });
}

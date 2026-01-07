import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom.dart";
import "package:web/web.dart" as web;

import "./solid_demo_help.dart";
import "package:dart_web_test/demo/solid_demo_nav.dart";

void mountSolidSelectionDemo(web.Element mount) {
  render(mount, () {
    final root = web.HTMLDivElement()
      ..id = "selection-root"
      ..className = "container";

    root.appendChild(solidDemoNav(active: "selection"));

    root.appendChild(
      web.HTMLHeadingElement.h1()..textContent = "Solid Selection Core Demo",
    );

    root.appendChild(
      solidDemoHelp(
        title: "What this is",
        bullets: const [
          "This page is a Kobalte-style port target: createSelectableCollection + createSelectableItem.",
          "Arrow keys move the focused item; Enter/Space selects the focused item.",
          "Shift extends selection in multiple mode; Ctrl/Meta toggles selection; Ctrl+A selects all.",
          "Use it as a reference when porting Menu/Listbox/Select/Combobox behavior.",
        ],
      ),
    );

    root.appendChild(
      solidDemoHelp(
        title: "Option meanings",
        bullets: const [
          "Replace vs Toggle: Replace clears previous selection; Toggle adds/removes items from the selected set (checkbox-style).",
          "Select on press up: selection happens on pointer up/click (not pointer down). Useful for menus where selection may close immediately.",
          "Allow different press origin: only relevant with “select on press up”. Press on one item, drag, release on another → selects the release target.",
        ],
      ),
    );

    final selectionMode = createSignal(SelectionMode.multiple);
    final selectionBehavior = createSignal(SelectionBehavior.replace);
    final selectOnPressUp = createSignal(false);
    final allowsDifferentPressOrigin = createSignal(false);

    final keys = <String>[
      "solid",
      "react",
      "svelte",
      "vue",
      "dart",
    ];
    final disabled = <String>{"vue"};
    final orderedKeys = () => keys;

    SelectionManager makeManager() => SelectionManager(
          selectionMode: selectionMode.value,
          selectionBehavior: selectionBehavior.value,
          orderedKeys: orderedKeys,
          isDisabled: (k) => disabled.contains(k),
          canSelectItem: (k) => !disabled.contains(k),
        );

    final manager = makeManager();

    createEffect(() {
      manager.setSelectionMode(selectionMode.value);
      manager.setSelectionBehavior(selectionBehavior.value);
    });

    final controls = web.HTMLDivElement()..className = "row";

    web.HTMLButtonElement modeBtn(String id, String label, SelectionMode mode) {
      final btn = web.HTMLButtonElement()
        ..id = id
        ..type = "button"
        ..className = "btn secondary"
        ..textContent = label;
      on(btn, "click", (_) => selectionMode.value = mode);
      createRenderEffect(() {
        if (selectionMode.value == mode) {
          btn.className = "btn primary";
        } else {
          btn.className = "btn secondary";
        }
      });
      return btn;
    }

    web.HTMLButtonElement behaviorBtn(
      String id,
      String label,
      SelectionBehavior behavior,
    ) {
      final btn = web.HTMLButtonElement()
        ..id = id
        ..type = "button"
        ..className = "btn secondary"
        ..textContent = label;
      on(btn, "click", (_) => selectionBehavior.value = behavior);
      createRenderEffect(() {
        if (selectionBehavior.value == behavior) {
          btn.className = "btn primary";
        } else {
          btn.className = "btn secondary";
        }
      });
      return btn;
    }

    final pressUpToggle = web.HTMLLabelElement()
      ..className = "row"
      ..style.gap = "8px";
    final pressUpCb = web.HTMLInputElement()
      ..id = "selection-pressup"
      ..type = "checkbox";
    on(pressUpCb, "change", (_) => selectOnPressUp.value = pressUpCb.checked);
    createRenderEffect(() => pressUpCb.checked = selectOnPressUp.value);
    pressUpToggle.appendChild(pressUpCb);
    pressUpToggle.appendChild(web.HTMLSpanElement()..textContent = "Select on press up");

    final originToggle = web.HTMLLabelElement()
      ..className = "row"
      ..style.gap = "8px";
    final originCb = web.HTMLInputElement()
      ..id = "selection-pressorigin"
      ..type = "checkbox";
    on(originCb, "change", (_) {
      allowsDifferentPressOrigin.value = originCb.checked;
    });
    createRenderEffect(() => originCb.checked = allowsDifferentPressOrigin.value);
    originToggle.appendChild(originCb);
    originToggle.appendChild(
      web.HTMLSpanElement()..textContent = "Allow different press origin",
    );

    controls.appendChild(modeBtn("selection-mode-multi", "Multiple", SelectionMode.multiple));
    controls.appendChild(modeBtn("selection-mode-single", "Single", SelectionMode.single));
    controls.appendChild(behaviorBtn("selection-behavior-replace", "Replace", SelectionBehavior.replace));
    controls.appendChild(behaviorBtn("selection-behavior-toggle", "Toggle", SelectionBehavior.toggle));
    controls.appendChild(pressUpToggle);
    controls.appendChild(originToggle);
    root.appendChild(controls);

    final status = web.HTMLParagraphElement()
      ..id = "selection-status"
      ..className = "muted";
    status.appendChild(text(() {
      final focused = manager.focusedKey() ?? "none";
      final selected = manager.selectedKeys().toList()..sort();
      return "Focused: $focused • Selected: ${selected.join(", ")}";
    }));
    root.appendChild(status);

    final list = web.HTMLDivElement()
      ..id = "selection-list"
      ..className = "card menu";
    list.style.maxWidth = "360px";
    list.style.maxHeight = "240px";
    list.style.overflow = "auto";
    list.setAttribute("role", "listbox");

    final elByKey = <String, web.HTMLElement>{};
    for (final k in keys) {
      final item = web.HTMLDivElement()
        ..id = "selection-item-$k"
        ..className = "menuItem"
        ..textContent = "${k[0].toUpperCase()}${k.substring(1)}";
      item.setAttribute("role", "option");

      final isDisabled = disabled.contains(k);
      if (isDisabled) item.setAttribute("aria-disabled", "true");

      attr(item, "aria-selected", () => manager.isSelected(k) ? "true" : "false");
      attr(item, "data-selected", () => manager.isSelected(k) ? "true" : null);
      attr(item, "data-focused", () => manager.focusedKey() == k ? "true" : null);

      final selectable = createSelectableItem(
        selectionManager: () => manager,
        key: () => k,
        ref: () => item,
        shouldSelectOnPressUp: () => selectOnPressUp.value,
        allowsDifferentPressOrigin: () => allowsDifferentPressOrigin.value,
        disabled: () => isDisabled,
      );
      selectable.attach(item);

      elByKey[k] = item;
      list.appendChild(item);
    }

    final delegate = ListKeyboardDelegate(
      keys: orderedKeys,
      isDisabled: (k) => disabled.contains(k),
      textValueForKey: (k) => elByKey[k]?.textContent ?? "",
      getContainer: () => list,
      getItemElement: (k) => elByKey[k],
    );

    manager.setFocusedKey(keys.firstWhere((k) => !disabled.contains(k)));

    final collection = createSelectableCollection(
      selectionManager: () => manager,
      keyboardDelegate: () => delegate,
      ref: () => list,
      scrollRef: () => list,
      shouldFocusWrap: () => true,
      selectOnFocus: () => false,
      disallowSelectAll: () => false,
      disallowTypeAhead: () => false,
      shouldUseVirtualFocus: () => false,
      allowsTabNavigation: () => true,
      isVirtualized: () => false,
      orientation: () => Orientation.vertical,
    );
    collection.attach(list, scrollEl: list);

    root.appendChild(list);
    return root;
  });
}

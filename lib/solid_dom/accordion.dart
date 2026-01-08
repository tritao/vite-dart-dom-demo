import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./selection/create_selectable_collection.dart";
import "./selection/create_selectable_item.dart";
import "./selection/list_keyboard_delegate.dart";
import "./selection/selection_manager.dart";
import "./selection/types.dart";
import "./solid_dom.dart";

final class AccordionItem {
  AccordionItem({
    required this.key,
    required this.trigger,
    required this.content,
    this.disabled = false,
    String? textValue,
  }) : textValue = textValue ?? (trigger.textContent ?? "");

  final String key;
  final web.HTMLElement trigger;
  final web.HTMLElement content;
  final bool disabled;
  final String textValue;
}

int _accordionIdCounter = 0;
String _nextAccordionId(String prefix) {
  _accordionIdCounter++;
  return "$prefix-$_accordionIdCounter";
}

/// Accordion primitive with WAI-ARIA semantics and Kobalte-like keyboard behavior.
///
/// - Uses selection core for roving focus (Arrow keys + Home/End + typeahead).
/// - Expansion is controlled via [expandedKeys]/[setExpandedKeys].
web.HTMLElement Accordion({
  required Iterable<AccordionItem> items,
  required Set<String> Function() expandedKeys,
  required void Function(Set<String> next) setExpandedKeys,
  bool Function()? multiple,
  bool Function()? collapsible,
  bool Function()? shouldFocusWrap,
  Orientation Function()? orientation,
  String? ariaLabel,
  String? id,
  String rootClassName = "accordion",
  String itemClassName = "accordionItem",
  String triggerClassName = "accordionTrigger",
  String panelClassName = "accordionPanel",
}) {
  final multipleAccessor = multiple ?? () => false;
  final collapsibleAccessor = collapsible ?? () => true;
  final shouldFocusWrapAccessor = shouldFocusWrap ?? () => true;
  final orientationAccessor = orientation ?? () => Orientation.vertical;

  final resolvedId = id ?? _nextAccordionId("solid-accordion");

  final itemsList = items.toList(growable: false);
  final keys = <String>[];
  final byKey = <String, AccordionItem>{};

  for (var i = 0; i < itemsList.length; i++) {
    final it = itemsList[i];
    var k = it.key;
    if (k.isEmpty) {
      k = it.trigger.id;
    }
    if (k.isEmpty) {
      k = "$resolvedId-item-$i";
    }
    keys.add(k);
    byKey[k] = it;
  }

  bool isDisabled(String k) => byKey[k]?.disabled ?? true;
  String textValueForKey(String k) => byKey[k]?.textValue ?? "";

  final focusManager = SelectionManager(
    selectionMode: SelectionMode.none,
    selectionBehavior: SelectionBehavior.replace,
    orderedKeys: () => keys,
    isDisabled: isDisabled,
    canSelectItem: (k) => !isDisabled(k),
  );

  // Ensure we always have a focusedKey for roving tabIndex.
  createRenderEffect(() {
    final focused = focusManager.focusedKey();
    if (focused != null && focused.isNotEmpty && !isDisabled(focused)) return;
    for (final k in keys) {
      if (!isDisabled(k)) {
        focusManager.setFocusedKey(k);
        return;
      }
    }
  });

  final root = web.HTMLDivElement()
    ..id = resolvedId
    ..className = rootClassName;
  if (ariaLabel != null && ariaLabel.isNotEmpty) {
    root.setAttribute("aria-label", ariaLabel);
  }

  final delegate = ListKeyboardDelegate(
    keys: () => keys,
    isDisabled: isDisabled,
    textValueForKey: textValueForKey,
    getContainer: () => root,
    getItemElement: (k) => byKey[k]?.trigger,
  );

  final selectable = createSelectableCollection(
    selectionManager: () => focusManager,
    keyboardDelegate: () => delegate,
    ref: () => root,
    scrollRef: () => root,
    shouldFocusWrap: shouldFocusWrapAccessor,
    selectOnFocus: () => false,
    shouldUseVirtualFocus: () => false,
    allowsTabNavigation: () => true,
    orientation: orientationAccessor,
  );
  selectable.attach(root);

  void toggle(String k) {
    if (isDisabled(k)) return;
    final current = {...expandedKeys()};
    if (multipleAccessor()) {
      if (current.contains(k)) {
        current.remove(k);
      } else {
        current.add(k);
      }
      setExpandedKeys(current);
      return;
    }

    final isOpen = current.contains(k);
    if (isOpen) {
      if (!collapsibleAccessor()) return;
      setExpandedKeys(<String>{});
      return;
    }
    setExpandedKeys(<String>{k});
  }

  for (var i = 0; i < keys.length; i++) {
    final k = keys[i];
    final it = byKey[k]!;
    final item = web.HTMLDivElement()..className = itemClassName;

    final trigger = it.trigger;
    trigger.classList.add(triggerClassName);

    final headerId = trigger.id.isNotEmpty ? trigger.id : "$resolvedId-header-$k";
    trigger.id = headerId;

    final panel = it.content;
    panel.classList.add(panelClassName);
    final panelId = panel.id.isNotEmpty ? panel.id : "$resolvedId-panel-$k";
    panel.id = panelId;

    trigger.setAttribute("aria-controls", panelId);

    if (it.disabled) {
      trigger.setAttribute("aria-disabled", "true");
      if (trigger is web.HTMLButtonElement) trigger.disabled = true;
    } else {
      trigger.removeAttribute("aria-disabled");
      if (trigger is web.HTMLButtonElement) trigger.disabled = false;
    }

    panel
      ..setAttribute("role", "region")
      ..setAttribute("aria-labelledby", headerId);

    createRenderEffect(() {
      final open = expandedKeys().contains(k);
      trigger.setAttribute("aria-expanded", open ? "true" : "false");
      item.setAttribute("data-state", open ? "open" : "closed");
      if (open) {
        panel.removeAttribute("hidden");
        panel.removeAttribute("aria-hidden");
      } else {
        panel.setAttribute("hidden", "");
        panel.setAttribute("aria-hidden", "true");
      }
    });

    final itemSelectable = createSelectableItem(
      selectionManager: () => focusManager,
      key: () => k,
      ref: () => trigger,
      disabled: () => it.disabled,
      shouldSelectOnPressUp: () => false,
      allowsDifferentPressOrigin: () => false,
    );
    itemSelectable.attach(trigger);

    on(trigger, "click", (_) => toggle(k));
    on(trigger, "keydown", (e) {
      if (e is! web.KeyboardEvent) return;
      if (e.key == "Enter" || e.key == " ") {
        e.preventDefault();
        toggle(k);
      }
    });

    item.appendChild(trigger);
    item.appendChild(panel);
    root.appendChild(item);
  }

  // Run after first paint to align focus with the first enabled trigger.
  scheduleMicrotask(() {
    final focused = focusManager.focusedKey();
    if (focused != null && focused.isNotEmpty && !isDisabled(focused)) return;
    for (final k in keys) {
      if (!isDisabled(k)) {
        focusManager.setFocusedKey(k);
        return;
      }
    }
  });

  return root;
}

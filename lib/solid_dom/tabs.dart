import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./selection/create_selectable_collection.dart";
import "./selection/create_selectable_item.dart";
import "./selection/list_keyboard_delegate.dart";
import "./selection/selection_manager.dart";
import "./selection/types.dart";
import "./solid_dom.dart";

enum TabsActivationMode {
  automatic,
  manual,
}

final class TabsItem {
  TabsItem({
    required this.key,
    required this.trigger,
    required this.panel,
    this.disabled = false,
    String? textValue,
  }) : textValue = textValue ?? (trigger.textContent ?? "");

  final String key;
  final web.HTMLElement trigger;
  final web.HTMLElement panel;
  final bool disabled;
  final String textValue;
}

int _tabsIdCounter = 0;
String _nextTabsId(String prefix) {
  _tabsIdCounter++;
  return "$prefix-$_tabsIdCounter";
}

bool _isRtl() {
  try {
    final html = web.document.documentElement;
    final dir = html?.getAttribute("dir") ?? web.document.dir;
    return (dir ?? "").toLowerCase() == "rtl";
  } catch (_) {
    return false;
  }
}

/// Tabs primitive (Kobalte-style semantics + keyboard behavior).
///
/// - Uses `SelectionManager` + `createSelectableCollection/item` for navigation.
/// - `activationMode=automatic` selects on focus (arrow keys).
/// - `activationMode=manual` moves focus with arrows, selection on click/Enter/Space.
web.HTMLElement Tabs({
  required Iterable<TabsItem> items,
  required String? Function() value,
  required void Function(String next) setValue,
  TabsActivationMode Function()? activationMode,
  Orientation Function()? orientation,
  bool Function()? shouldFocusWrap,
  String? ariaLabel,
  String? id,
  String tabListClassName = "tabsList",
  String panelClassName = "tabsPanel",
  String rootClassName = "tabs",
}) {
  final activationModeAccessor = activationMode ?? () => TabsActivationMode.automatic;
  final orientationAccessor = orientation ?? () => Orientation.horizontal;
  final shouldFocusWrapAccessor = shouldFocusWrap ?? () => true;

  final resolvedId = id ?? _nextTabsId("solid-tabs");
  final listId = "$resolvedId-list";

  final root = web.HTMLDivElement()..className = rootClassName;

  final tabList = web.HTMLDivElement()
    ..id = listId
    ..className = tabListClassName
    ..setAttribute("role", "tablist");

  if (ariaLabel != null && ariaLabel.isNotEmpty) {
    tabList.setAttribute("aria-label", ariaLabel);
  }

  createRenderEffect(() {
    final o = orientationAccessor();
    tabList.setAttribute(
      "aria-orientation",
      o == Orientation.vertical ? "vertical" : "horizontal",
    );
  });

  final panels = web.HTMLDivElement()..className = "tabsPanels";

  final itemsList = items.toList(growable: false);
  final keys = <String>[];
  final byKey = <String, TabsItem>{};

  for (var i = 0; i < itemsList.length; i++) {
    final it = itemsList[i];
    var k = it.key;
    if (k.isEmpty) {
      k = it.trigger.id;
    } else {
      if (it.trigger.id.isEmpty) it.trigger.id = "$resolvedId-tab-$k";
    }
    if (k.isEmpty) {
      k = "$resolvedId-tab-$i";
      it.trigger.id = k;
    }
    keys.add(k);
    byKey[k] = it;
  }

  bool isDisabled(String k) => byKey[k]?.disabled ?? true;
  String textValueForKey(String k) => byKey[k]?.textValue ?? "";

  final selection = SelectionManager(
    selectionMode: SelectionMode.single,
    selectionBehavior: SelectionBehavior.replace,
    orderedKeys: () => keys,
    isDisabled: isDisabled,
    canSelectItem: (k) => !isDisabled(k),
  );

  // Automatic activation: focus changes the value (and therefore selection).
  createRenderEffect(() {
    if (activationModeAccessor() != TabsActivationMode.automatic) return;
    final focused = selection.focusedKey();
    if (focused == null || focused.isEmpty) return;
    if (byKey[focused] == null || isDisabled(focused)) return;
    final v = value();
    if (v != focused) setValue(focused);
  });

  // Sync selection to the controlled value.
  createRenderEffect(() {
    final v = value();
    if (v == null || v.isEmpty) return;
    if (byKey[v] == null || isDisabled(v)) return;
    if (!selection.isSelectionEqual({v})) {
      selection.setSelectedKeys([v], force: true);
    }
    if (selection.focusedKey() == null) {
      selection.setFocusedKey(v);
    }
  });

  // Ensure we always have a tabbable trigger for initial Tab entry.
  createRenderEffect(() {
    final focused = selection.focusedKey();
    if (focused != null && byKey[focused] != null && !isDisabled(focused)) return;
    final selected = selection.firstSelectedKey();
    if (selected != null && !isDisabled(selected)) {
      selection.setFocusedKey(selected);
      return;
    }
    for (final k in keys) {
      if (!isDisabled(k)) {
        selection.setFocusedKey(k);
        return;
      }
    }
  });

  // When focus leaves the tablist, reset roving focus to the selected tab
  // (so Tab into the tablist focuses the active tab).
  on(tabList, "focusout", (e) {
    if (e is! web.FocusEvent) return;
    final related = e.relatedTarget;
    if (related is web.Node && tabList.contains(related)) return;
    final selected = selection.firstSelectedKey();
    if (selected != null) selection.setFocusedKey(selected);
  });

  final delegate = ListKeyboardDelegate(
    keys: () => keys,
    isDisabled: isDisabled,
    textValueForKey: textValueForKey,
    getContainer: () => tabList,
    getItemElement: (k) => byKey[k]?.trigger,
  );

  final selectable = createSelectableCollection(
    selectionManager: () => selection,
    keyboardDelegate: () => delegate,
    ref: () => tabList,
    scrollRef: () => tabList,
    shouldFocusWrap: shouldFocusWrapAccessor,
    selectOnFocus: () => activationModeAccessor() == TabsActivationMode.automatic,
    shouldUseVirtualFocus: () => false,
    allowsTabNavigation: () => true,
    orientation: orientationAccessor,
    isRtl: _isRtl,
  );

  // Wire triggers + panels.
  for (final k in keys) {
    final it = byKey[k]!;
    final tab = it.trigger;
    final panel = it.panel;

    final tabId = tab.id.isEmpty ? "$resolvedId-tab-$k" : tab.id;
    tab.id = tabId;

    final panelId = panel.id.isEmpty ? "$resolvedId-panel-$k" : panel.id;
    panel.id = panelId;

    tab
      ..setAttribute("role", "tab")
      ..setAttribute("aria-controls", panelId);
    if (tab is web.HTMLButtonElement) {
      tab.disabled = it.disabled;
    }
    panel
      ..setAttribute("role", "tabpanel")
      ..setAttribute("aria-labelledby", tabId)
      ..classList.add(panelClassName);

    createRenderEffect(() {
      final selected = (value() == k);
      tab.setAttribute("aria-selected", selected ? "true" : "false");
      if (it.disabled) {
        tab.setAttribute("aria-disabled", "true");
      } else {
        tab.removeAttribute("aria-disabled");
      }
      if (selected) {
        panel.removeAttribute("hidden");
        panel.removeAttribute("aria-hidden");
      } else {
        panel.setAttribute("hidden", "");
        panel.setAttribute("aria-hidden", "true");
      }
    });

    final itemSelectable = createSelectableItem(
      selectionManager: () => selection,
      key: () => k,
      ref: () => tab,
      disabled: () => it.disabled,
      shouldSelectOnPressUp: () => true,
      allowsDifferentPressOrigin: () => false,
      onAction: () {
        if (it.disabled) return;
        if (activationModeAccessor() == TabsActivationMode.manual &&
            selection.focusedKey() != k) {
          selection.setFocusedKey(k);
        }
        setValue(k);
      },
    );
    itemSelectable.attach(tab);

    // Ensure we don't accidentally scroll the page on Space.
    on(tab, "keydown", (e) {
      if (e is! web.KeyboardEvent) return;
      if (e.key == " ") e.preventDefault();
      if (activationModeAccessor() == TabsActivationMode.manual &&
          (e.key == "Enter" || e.key == " ")) {
        e.preventDefault();
        if (!it.disabled) setValue(k);
      }
    });

    tabList.appendChild(tab);
    panels.appendChild(panel);
  }

  // Ensure selection reflects the controlled value on mount.
  scheduleMicrotask(() {
    final v = value();
    if (v != null && v.isNotEmpty && byKey[v] != null && !isDisabled(v)) {
      selection.setSelectedKeys([v], force: true);
      selection.setFocusedKey(v);
      return;
    }
    for (final k in keys) {
      if (!isDisabled(k)) {
        selection.setSelectedKeys([k], force: true);
        setValue(k);
        selection.setFocusedKey(k);
        return;
      }
    }
  });

  selectable.attach(tabList);

  root.appendChild(tabList);
  root.appendChild(panels);

  return root;
}

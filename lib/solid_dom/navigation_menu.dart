import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./popover.dart";
import "./selection/create_selectable_collection.dart";
import "./selection/create_selectable_item.dart";
import "./selection/list_keyboard_delegate.dart";
import "./selection/selection_manager.dart";
import "./selection/types.dart";
import "./selection/utils.dart";
import "./solid_dom.dart";

final class NavigationMenuItem {
  NavigationMenuItem({
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

int _navMenuIdCounter = 0;
String _nextNavMenuId(String prefix) {
  _navMenuIdCounter++;
  return "$prefix-$_navMenuIdCounter";
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

List<web.HTMLElement> _focusableWithin(web.Element root) {
  final nodes = root.querySelectorAll(
    'a[href],button,input,select,textarea,[tabindex]:not([tabindex="-1"])',
  );
  final out = <web.HTMLElement>[];
  for (var i = 0; i < nodes.length; i++) {
    final n = nodes.item(i);
    if (n == null || n is! web.HTMLElement) continue;
    final disabled = (n is web.HTMLButtonElement && n.disabled) ||
        (n is web.HTMLInputElement && n.disabled) ||
        (n is web.HTMLSelectElement && n.disabled) ||
        (n is web.HTMLTextAreaElement && n.disabled);
    if (disabled) continue;
    out.add(n);
  }
  return out;
}

/// NavigationMenu primitive (shadcn/Radix-ish).
///
/// - Triggers are in a horizontal list with roving tabindex.
/// - Each item opens a Popover panel anchored to its trigger.
/// - Hover switches panels; click toggles.
web.HTMLElement NavigationMenu({
  required Iterable<NavigationMenuItem> items,
  bool openOnHover = true,
  int closeDelayMs = 140,
  int openDelayMs = 0,
  String ariaLabel = "navigation",
  String? id,
  String rootClassName = "navigationMenu",
  String listClassName = "navigationMenuList",
  String triggerClassName = "navigationMenuTrigger",
  String contentClassName = "navigationMenuContent",
}) {
  final resolvedId = id ?? _nextNavMenuId("solid-nav-menu");

  final itemsList = items.toList(growable: false);
  final keys = <String>[];
  final byKey = <String, NavigationMenuItem>{};

  for (var i = 0; i < itemsList.length; i++) {
    final it = itemsList[i];
    var k = it.key;
    if (k.isEmpty) k = it.trigger.id;
    if (k.isEmpty) k = "$resolvedId-item-$i";
    keys.add(k);
    byKey[k] = it;
  }

  bool isDisabled(String k) => byKey[k]?.disabled ?? true;
  String textValueForKey(String k) => byKey[k]?.textValue ?? "";

  final openKeySig = createSignal<String?>(null);
  String? openKey() => openKeySig.value;
  void setOpenKey(String? next) {
    if (openKeySig.value != next) openKeySig.value = next;
  }

  Timer? openTimer;
  Timer? closeTimer;
  void clearTimers() {
    openTimer?.cancel();
    closeTimer?.cancel();
    openTimer = null;
    closeTimer = null;
  }

  onCleanup(clearTimers);

  void scheduleOpen(String key) {
    if (!openOnHover || isDisabled(key)) return;
    closeTimer?.cancel();
    closeTimer = null;
    openTimer?.cancel();
    openTimer = Timer(Duration(milliseconds: openDelayMs), () {
      setOpenKey(key);
    });
  }

  void scheduleClose() {
    openTimer?.cancel();
    openTimer = null;
    closeTimer?.cancel();
    closeTimer = Timer(Duration(milliseconds: closeDelayMs), () {
      setOpenKey(null);
    });
  }

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
    if (focused != null && byKey[focused] != null && !isDisabled(focused)) {
      return;
    }
    for (final k in keys) {
      if (!isDisabled(k)) {
        focusManager.setFocusedKey(k);
        return;
      }
    }
  });

  final root = web.HTMLDivElement()
    ..id = resolvedId
    ..className = rootClassName
    ..setAttribute("role", "navigation")
    ..setAttribute("aria-label", ariaLabel);

  final list = web.HTMLDivElement()..className = listClassName;
  root.appendChild(list);

  final delegate = ListKeyboardDelegate(
    keys: () => keys,
    isDisabled: isDisabled,
    textValueForKey: textValueForKey,
    getContainer: () => list,
    getItemElement: (k) => byKey[k]?.trigger,
  );

  final selectable = createSelectableCollection(
    selectionManager: () => focusManager,
    keyboardDelegate: () => delegate,
    ref: () => list,
    scrollRef: () => list,
    shouldFocusWrap: () => true,
    selectOnFocus: () => false,
    disallowTypeAhead: () => true,
    shouldUseVirtualFocus: () => false,
    allowsTabNavigation: () => true,
    orientation: () => Orientation.horizontal,
    isRtl: _isRtl,
  );
  selectable.attach(list);

  // If a panel is open and focus moves between triggers via arrows, switch the
  // open panel to match the focused trigger.
  createEffect(() {
    final focused = focusManager.focusedKey();
    final open = openKey();
    if (open == null || focused == null) return;
    if (open != focused && byKey[focused] != null && !isDisabled(focused)) {
      setOpenKey(focused);
    }
  });

  for (final k in keys) {
    final it = byKey[k]!;
    final trigger = it.trigger;

    trigger.classList.add(triggerClassName);
    if (trigger is web.HTMLButtonElement) trigger.type = "button";

    if (trigger.id.isEmpty) trigger.id = "$resolvedId-trigger-$k";
    final contentId =
        "$resolvedId-content-$k";
    trigger.setAttribute("aria-controls", contentId);

    createRenderEffect(() {
      final open = openKey() == k;
      trigger.setAttribute("aria-expanded", open ? "true" : "false");
      trigger.setAttribute("data-state", open ? "open" : "closed");
      if (it.disabled) {
        trigger.setAttribute("aria-disabled", "true");
        if (trigger is web.HTMLButtonElement) trigger.disabled = true;
      } else {
        trigger.removeAttribute("aria-disabled");
        if (trigger is web.HTMLButtonElement) trigger.disabled = false;
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

    on(trigger, "pointerenter", (_) {
      clearTimers();
      scheduleOpen(k);
    });
    on(trigger, "pointerleave", (_) {
      if (!openOnHover) return;
      scheduleClose();
    });

    void toggleOpen() {
      if (it.disabled) return;
      clearTimers();
      final next = openKey() == k ? null : k;
      setOpenKey(next);
    }

    on(trigger, "click", (_) => toggleOpen());

    on(trigger, "keydown", (e) {
      if (e is! web.KeyboardEvent) return;
      if (e.key == " " || e.key == "Enter") {
        e.preventDefault();
        toggleOpen();
        return;
      }
      if (e.key == "ArrowDown") {
        e.preventDefault();
        if (it.disabled) return;
        clearTimers();
        setOpenKey(k);
        // Focus first focusable element in the content after it mounts.
        scheduleMicrotask(() {
          final panel = web.document.getElementById(contentId);
          if (panel == null) return;
          final focusables = _focusableWithin(panel);
          if (focusables.isNotEmpty) {
            focusWithoutScrolling(focusables.first);
          } else if (panel is web.HTMLElement) {
            panel.tabIndex = -1;
            focusWithoutScrolling(panel);
          }
        });
        return;
      }
      if (e.key == "Escape") {
        if (openKey() != null) {
          e.preventDefault();
          setOpenKey(null);
        }
        return;
      }

      // Forward nav keys to the collection handler (button key events don't
      // always bubble consistently in all environments).
      final isNav = e.key == "ArrowLeft" ||
          e.key == "ArrowRight" ||
          e.key == "Home" ||
          e.key == "End";
      if (isNav) {
        e.stopPropagation();
        selectable.onKeyDownWithOptions(e, bypassTargetCheck: true);
      }
    });

    list.appendChild(trigger);

    // Each item owns its own popover panel.
    final fragment = Popover(
      open: () => openKey() == k,
      setOpen: (next) => setOpenKey(next ? k : null),
      anchor: trigger,
      exitMs: 0,
      placement: "bottom-start",
      offset: 8,
      viewportPadding: 8,
      flip: true,
      slide: true,
      overlap: true,
      hideWhenDetached: true,
      role: "region",
      builder: (close) {
        final panel = web.HTMLDivElement()
          ..id = contentId
          ..className = contentClassName
          ..setAttribute("aria-labelledby", trigger.id);

        // Keep the panel open while interacting with it.
        on(panel, "pointerenter", (_) {
          clearTimers();
        });
        on(panel, "pointerleave", (_) {
          if (!openOnHover) return;
          scheduleClose();
        });
        on(panel, "focusin", (_) {
          clearTimers();
        });
        on(panel, "focusout", (e) {
          if (e is! web.FocusEvent) return;
          final related = e.relatedTarget;
          if (related is web.Node && panel.contains(related)) return;
          if (!openOnHover) return;
          scheduleClose();
        });

        // Clone the provided content node into the panel.
        panel.appendChild(it.content);
        return panel;
      },
      onClose: (_) {
        setOpenKey(null);
        scheduleMicrotask(() {
          if (trigger is web.HTMLElement) focusWithoutScrolling(trigger);
        });
      },
    );
    root.appendChild(fragment);
  }

  return root;
}

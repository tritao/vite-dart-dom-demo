import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./menu.dart";
import "./overlay.dart";
import "./solid_dom.dart";

final class MenubarMenu {
  MenubarMenu({
    required this.key,
    required this.trigger,
    required this.builder,
    this.placement = "bottom-start",
    this.offset = 6,
    this.viewportPadding = 8,
    this.flip = true,
  });

  final String key;
  final web.HTMLElement trigger;
  final MenuBuilder builder;
  final String placement;
  final double offset;
  final double viewportPadding;
  final bool flip;
}

String _documentDirection() {
  try {
    final html = web.document.documentElement;
    final dir = html?.getAttribute("dir") ?? web.document.dir;
    return (dir ?? "").toLowerCase() == "rtl" ? "rtl" : "ltr";
  } catch (_) {
    return "ltr";
  }
}

web.DocumentFragment Menubar({
  required String? Function() openKey,
  required void Function(String? next) setOpenKey,
  required List<MenubarMenu> menus,
  String className = "menubar",
  String? portalId,
  void Function(String reason)? onClose,
}) {
  final fragment = web.DocumentFragment();

  final bar = web.HTMLDivElement()
    ..className = className
    ..setAttribute("role", "menubar");

  fragment.appendChild(bar);

  final openFocusIntent = createSignal<({String key, bool focusLast})?>(null);

  final triggers = <web.HTMLElement>[];
  for (final m in menus) {
    triggers.add(m.trigger);
  }

  final activeIndex = createSignal(0);

  // Keep roving index aligned with the currently open menu (when any).
  createRenderEffect(() {
    final k = openKey();
    if (k == null) return;
    final idx = menus.indexWhere((m) => m.key == k);
    if (idx >= 0) activeIndex.value = idx;
  });

  for (var i = 0; i < menus.length; i++) {
    final index = i;
    final m = menus[i];
    final trigger = m.trigger;
    final k = m.key;

    if (trigger.id.isEmpty) trigger.id = "menubar-trigger-$k";
    trigger
      ..setAttribute("role", "menuitem")
      ..setAttribute("aria-haspopup", "menu");

    createRenderEffect(() {
      final expanded = openKey() == k;
      trigger.setAttribute("aria-expanded", expanded ? "true" : "false");
    });

    on(trigger, "focus", (_) {
      activeIndex.value = index;
    });

    void openFromKeyboard({required bool focusLast}) {
      activeIndex.value = index;
      openFocusIntent.value = (key: k, focusLast: focusLast);
      setOpenKey(k);
    }

    on(trigger, "keydown", (e) {
      if (e is! web.KeyboardEvent) return;
      if (e.repeat) return;

      final isOpen = openKey() == k;

      if (e.key == "Enter" || e.key == " ") {
        e.preventDefault();
        openFromKeyboard(focusLast: false);
        return;
      }

      if (e.key == "ArrowDown") {
        e.preventDefault();
        openFromKeyboard(focusLast: false);
        return;
      }

      if (e.key == "ArrowUp") {
        e.preventDefault();
        openFromKeyboard(focusLast: true);
        return;
      }

      // When any menu is open, ArrowLeft/ArrowRight should switch to adjacent
      // top-level menus (Kobalte Menubar-like).
      if (openKey() != null && (e.key == "ArrowLeft" || e.key == "ArrowRight")) {
        final dir = _documentDirection();
        final forwardKey = dir == "rtl" ? "ArrowLeft" : "ArrowRight";
        final delta = e.key == forwardKey ? 1 : -1;
        e.preventDefault();
        e.stopPropagation();
        final next = (index + delta + menus.length) % menus.length;
        activeIndex.value = next;
        setOpenKey(menus[next].key);
        return;
      }

      // Toggle close on Escape when focus returns to the trigger.
      if (isOpen && e.key == "Escape") {
        e.preventDefault();
        setOpenKey(null);
      }
    });

    on(trigger, "click", (e) {
      if (e is web.MouseEvent) {
        activeIndex.value = index;
        openFocusIntent.value = null;
        final next = openKey() == k ? null : k;
        setOpenKey(next);
      }
    });

    on(trigger, "pointerenter", (e) {
      if (e is! web.PointerEvent) return;
      if (e.pointerType != "mouse") return;
      if (openKey() == null) return;
      if (openKey() == k) return;
      activeIndex.value = index;
      openFocusIntent.value = null;
      setOpenKey(k);
    });

    bar.appendChild(trigger);
  }

  // Horizontal roving focus for triggers.
  rovingTabIndex(
    bar,
    items: () => triggers,
    activeIndex: () => activeIndex.value,
    setActiveIndex: (next) => activeIndex.value = next,
    nextKeys: const {"ArrowRight"},
    prevKeys: const {"ArrowLeft"},
  );

  on(bar, "keydown", (e) {
    if (e is! web.KeyboardEvent) return;
    if (e.key == "Home") {
      e.preventDefault();
      activeIndex.value = 0;
      triggers.firstOrNull?.focus();
      return;
    }
    if (e.key == "End") {
      e.preventDefault();
      activeIndex.value = triggers.isEmpty ? 0 : triggers.length - 1;
      triggers.lastOrNull?.focus();
      return;
    }
  });

  // We need the triggers excluded so focusing another trigger doesn't dismiss
  // the currently open menu before we can switch.
  final excludedTriggers = <web.Element? Function()>[
    for (final t in triggers) () => t,
  ];

  for (var i = 0; i < menus.length; i++) {
    final index = i;
    final m = menus[i];
    final k = m.key;

    fragment.appendChild(
      Menu(
        open: () => openKey() == k,
        setOpen: (next) {
          if (next) {
            activeIndex.value = index;
            setOpenKey(k);
          } else {
            if (openKey() == k) setOpenKey(null);
          }
        },
        anchor: m.trigger,
        restoreFocusTo: m.trigger,
        additionalExcludedElements: excludedTriggers,
        placement: m.placement,
        offset: m.offset,
        viewportPadding: m.viewportPadding,
        flip: m.flip,
        portalId: portalId,
        onClose: onClose,
        builder: (close) {
          final built = m.builder(close);

          // Menubar: allow ArrowLeft/ArrowRight to switch between top-level menus.
          on(built.element, "keydown", (e) {
            if (e is! web.KeyboardEvent) return;
            if (e.repeat) return;
            if (e.key != "ArrowLeft" && e.key != "ArrowRight") return;

            final dir = _documentDirection();
            final forwardKey = dir == "rtl" ? "ArrowLeft" : "ArrowRight";
            final delta = e.key == forwardKey ? 1 : -1;
            e.preventDefault();
            e.stopPropagation();
            final next = (index + delta + menus.length) % menus.length;
            activeIndex.value = next;
            openFocusIntent.value = null;
            setOpenKey(menus[next].key);
          });

          final menuId = "menubar-menu-$k";
          if (built.element.id.isEmpty) built.element.id = menuId;
          m.trigger.setAttribute("aria-controls", built.element.id);

          final intent = openFocusIntent.value;
          if (intent != null && intent.key == k) {
            scheduleMicrotask(() => openFocusIntent.value = null);
            final focusLast = intent.focusLast;
            if (focusLast) {
              return MenuContent(
                element: built.element,
                items: built.items,
                initialActiveIndex: built.items.isEmpty ? 0 : built.items.length - 1,
              );
            }
          }

          return built;
        },
      ),
    );
  }

  return fragment;
}

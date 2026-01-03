import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./floating.dart";
import "./focus_scope.dart";
import "./overlay.dart";
import "./presence.dart";
import "./solid_dom.dart";

final class MenuContent {
  MenuContent({
    required this.element,
    required this.items,
    this.initialActiveIndex = 0,
  });

  final web.HTMLElement element;
  final List<web.HTMLElement> items;
  final int initialActiveIndex;
}

typedef DropdownMenuBuilder = MenuContent Function(
    void Function([String reason]) close);

web.DocumentFragment DropdownMenu({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required web.Element anchor,
  required DropdownMenuBuilder builder,
  void Function(String reason)? onClose,
  void Function(FocusScopeAutoFocusEvent event)? onOpenAutoFocus,
  void Function(FocusScopeAutoFocusEvent event)? onCloseAutoFocus,
  int exitMs = 120,
  String placement = "bottom-start",
  double offset = 4,
  double viewportPadding = 8,
  bool flip = true,
  String? portalId,
}) {
  return Presence(
    when: open,
    exitMs: exitMs,
    children: () => Portal(
      id: portalId,
      children: () {
        var closeReason = "close";

        void close([String reason = "close"]) {
          closeReason = reason;
          onClose?.call(reason);
          setOpen(false);
        }

        final built = builder(close);
        final menu = built.element;
        final items = built.items;

        menu
          ..setAttribute("role", "menu")
          ..tabIndex = -1;

        floatToAnchor(
          anchor: anchor,
          floating: menu,
          placement: placement,
          offset: offset,
          viewportPadding: viewportPadding,
          flip: flip,
          updateOnScrollParents: true,
        );

        // Prevent the common "click trigger to close then click toggles open"
        // issue by excluding the anchor from outside dismissal.
        dismissableLayer(
          menu,
          excludedElements: <web.Element? Function()>[
            () => anchor,
          ],
          onDismiss: (reason) => close(reason),
        );

        final activeIndex = createSignal<int>(
          built.initialActiveIndex
              .clamp(0, items.isEmpty ? 0 : items.length - 1),
        );

        void syncTabIndex() {
          final active =
              activeIndex.value.clamp(0, items.isEmpty ? 0 : items.length - 1);
          for (var i = 0; i < items.length; i++) {
            items[i].tabIndex = i == active ? 0 : -1;
          }
        }

        createRenderEffect(syncTabIndex);

        void focusActive({bool fallbackToMenu = true}) {
          if (!menu.isConnected) return;
          syncTabIndex();
          final idx =
              activeIndex.value.clamp(0, items.isEmpty ? 0 : items.length - 1);
          if (items.isNotEmpty) {
            try {
              items[idx].focus();
              return;
            } catch (_) {}
          }
          if (fallbackToMenu) {
            try {
              menu.focus();
            } catch (_) {}
          }
        }

        // Focus a reasonable item on mount.
        focusScope(
          menu,
          trapFocus: false,
          restoreFocus: true,
          onMountAutoFocus: (e) {
            onOpenAutoFocus?.call(e);
            if (e.defaultPrevented) return;
            e.preventDefault();
            scheduleMicrotask(() => focusActive());
          },
          onUnmountAutoFocus: (e) {
            onCloseAutoFocus?.call(e);
            if (e.defaultPrevented) return;
            if (closeReason == "tab") e.preventDefault();
          },
        );

        Timer? typeaheadTimer;
        var typeahead = "";

        void clearTypeahead() {
          typeahead = "";
          typeaheadTimer?.cancel();
          typeaheadTimer = null;
        }

        void onKeydown(web.Event e) {
          if (e is! web.KeyboardEvent) return;

          if (e.key == "Tab") {
            // Let Tab move focus naturally; just close.
            close("tab");
            return;
          }

          if (items.isEmpty) return;
          final active = activeIndex.value.clamp(0, items.length - 1);

          int? next;
          switch (e.key) {
            case "ArrowDown":
              next = (active + 1) % items.length;
              break;
            case "ArrowUp":
              next = (active - 1 + items.length) % items.length;
              break;
            case "Home":
              next = 0;
              break;
            case "End":
              next = items.length - 1;
              break;
          }

          if (next != null) {
            e.preventDefault();
            activeIndex.value = next;
            focusActive();
            return;
          }

          // Basic typeahead (letters/numbers).
          final key = e.key;
          if (key.length == 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
            typeaheadTimer?.cancel();
            typeahead += key.toLowerCase();
            typeaheadTimer =
                Timer(const Duration(milliseconds: 500), clearTypeahead);

            for (var i = 0; i < items.length; i++) {
              final idx = (active + i) % items.length;
              final text = (items[idx].textContent ?? "").trim().toLowerCase();
              if (text.startsWith(typeahead) && text.isNotEmpty) {
                e.preventDefault();
                activeIndex.value = idx;
                focusActive();
                return;
              }
            }
          }
        }

        on(menu, "keydown", onKeydown);

        onCleanup(() {
          clearTypeahead();
        });

        return menu;
      },
    ),
  );
}

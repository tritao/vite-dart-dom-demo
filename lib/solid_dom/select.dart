import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./floating.dart";
import "./focus_scope.dart";
import "./listbox_core.dart";
import "./overlay.dart";
import "./presence.dart";
import "./solid_dom.dart";

final class SelectOption<T> implements ListboxItem<T> {
  const SelectOption({
    required this.value,
    required this.label,
    String? textValue,
    this.disabled = false,
    this.id,
  }) : textValue = textValue ?? label;

  @override
  final T value;
  @override
  final String label;
  @override
  final String textValue;
  @override
  final bool disabled;
  @override
  final String? id;
}

typedef SelectOptionBuilder<T> = web.HTMLElement Function(
  SelectOption<T> option,
  bool selected,
  bool active,
);

int _selectIdCounter = 0;
String _nextSelectId(String prefix) {
  _selectIdCounter++;
  return "$prefix-$_selectIdCounter";
}

web.DocumentFragment Select<T>({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required web.HTMLElement trigger,
  required Iterable<SelectOption<T>> Function() options,
  required T? Function() value,
  required void Function(T? next) setValue,
  void Function(String reason)? onClose,
  bool Function(T a, T b)? equals,
  String placement = "bottom-start",
  double offset = 4,
  double viewportPadding = 8,
  bool flip = true,
  int exitMs = 120,
  String? portalId,
  String? listboxId,
  SelectOptionBuilder<T>? optionBuilder,
}) {
  bool eq(T a, T b) => equals != null ? equals(a, b) : a == b;

  final resolvedListboxId = listboxId ?? _nextSelectId("solid-select-listbox");
  trigger.setAttribute("aria-haspopup", "listbox");
  attr(trigger, "aria-expanded", () => open() ? "true" : "false");
  attr(trigger, "aria-controls", () => open() ? resolvedListboxId : null);

  void close([String reason = "close"]) {
    onClose?.call(reason);
    setOpen(false);
  }

  void openNow() {
    setOpen(true);
  }

  // Basic trigger interactions (click + keyboard open).
  on(trigger, "click", (_) {
    setOpen(!open());
  });
  on(trigger, "keydown", (e) {
    if (e is! web.KeyboardEvent) return;
    if (e.key == "ArrowDown" || e.key == "ArrowUp" || e.key == "Enter" || e.key == " ") {
      e.preventDefault();
      openNow();
    }
  });

  return Presence(
    when: open,
    exitMs: exitMs,
    children: () => Portal(
      id: portalId,
      children: () {
        var closeReason = "close";

        void closeWith([String reason = "close"]) {
          closeReason = reason;
          close(reason);
        }

        final listbox = web.HTMLDivElement()
          ..id = resolvedListboxId
          ..setAttribute("role", "listbox")
          ..tabIndex = -1
          ..className = "card";

        listbox.style.minWidth = "220px";
        listbox.style.padding = "6px";

        floatToAnchor(
          anchor: trigger,
          floating: listbox,
          placement: placement,
          offset: offset,
          viewportPadding: viewportPadding,
          flip: flip,
          updateOnScrollParents: true,
        );

        // Outside dismissal should not consider the trigger "outside" (otherwise
        // trigger click can close + immediately re-open).
        dismissableLayer(
          listbox,
          excludedElements: <web.Element? Function()>[
            () => trigger,
          ],
          onDismiss: (reason) => closeWith(reason),
        );

        final optionEls = <web.HTMLElement>[];
        final optionValues = <T>[];
        final typeahead = ListboxTypeahead();

        int initialActiveIndex() {
          final current = value();
          final opts = options().toList(growable: false);
          final idx = findSelectedIndex<T, SelectOption<T>>(
            opts,
            current,
            equals: eq,
          );
          return idx == -1 ? 0 : idx;
        }

        final activeIndex = createSignal<int>(initialActiveIndex());

        void focusActive() {
          final idx = activeIndex.value.clamp(
            0,
            optionEls.isEmpty ? 0 : optionEls.length - 1,
          );
          if (optionEls.isEmpty) {
            try {
              listbox.focus();
            } catch (_) {}
            return;
          }
          try {
            optionEls[idx].focus();
          } catch (_) {}
        }

        void selectIndex(int idx, {bool closeAfter = true}) {
          if (idx < 0 || idx >= optionValues.length) return;
          final el = optionEls[idx];
          if (el.getAttribute("aria-disabled") == "true") return;
          setValue(optionValues[idx]);
          if (closeAfter) closeWith("select");
        }

        web.HTMLElement buildOptionEl(
          SelectOption<T> option,
          int idx, {
          required bool selected,
          required bool active,
        }) {
          final el = optionBuilder != null
              ? optionBuilder(option, selected, active)
              : (web.HTMLDivElement()
                ..className = "btn secondary"
                ..style.display = "block"
                ..style.width = "100%"
                ..style.textAlign = "left"
                ..textContent = option.label);

          el.setAttribute("role", "option");
          el.tabIndex = active ? 0 : -1;
          el.setAttribute("aria-selected", selected ? "true" : "false");
          if (option.disabled) el.setAttribute("aria-disabled", "true");

          final optId = option.id ?? "$resolvedListboxId-opt-$idx";
          el.id = optId;

          on(el, "pointermove", (_) {
            if (option.disabled) return;
            activeIndex.value = idx;
          });
          on(el, "click", (_) {
            if (option.disabled) return;
            activeIndex.value = idx;
            selectIndex(idx);
          });

          return el;
        }

        createRenderEffect(() {
          // Rebuild listbox content (simple approach).
          listbox.textContent = "";
          optionEls.clear();
          optionValues.clear();

          final opts = options().toList(growable: false);
          final current = value();

          final idxMax = opts.isEmpty ? 0 : opts.length - 1;
          final nextActive = activeIndex.value.clamp(0, idxMax);
          if (activeIndex.value != nextActive) activeIndex.value = nextActive;

          for (var i = 0; i < opts.length; i++) {
            final opt = opts[i];
            final selected = current != null && eq(opt.value, current);
            final active = i == activeIndex.value;
            final el = buildOptionEl(opt, i, selected: selected, active: active);
            optionEls.add(el);
            optionValues.add(opt.value);
            listbox.appendChild(el);
          }
        });

        // Focus management: focus active option on mount, restore focus unless Tab-close.
        focusScope(
          listbox,
          trapFocus: false,
          restoreFocus: true,
          onMountAutoFocus: (e) {
            e.preventDefault();
            scheduleMicrotask(focusActive);
          },
          onUnmountAutoFocus: (e) {
            if (closeReason == "tab") e.preventDefault();
          },
        );

        void clearTypeahead() {
          typeahead.clear();
        }

        void onKeydown(web.Event e) {
          if (e is! web.KeyboardEvent) return;

          if (e.key == "Tab") {
            // The listbox lives in a portal, so default Tab navigation would move
            // through the portal subtree. Close and move focus back to the trigger
            // so the browser continues tab order from the trigger position.
            closeWith("tab");
            try {
              trigger.focus();
            } catch (_) {}
            return;
          }
          if (e.key == "Escape") {
            e.preventDefault();
            closeWith("escape");
            return;
          }

          if (optionEls.isEmpty) return;
          final opts = options().toList(growable: false);
          final active = activeIndex.value.clamp(0, optionEls.length - 1);

          int? next;
          switch (e.key) {
            case "ArrowDown":
              next = nextEnabledIndex(opts, active, 1);
              break;
            case "ArrowUp":
              next = nextEnabledIndex(opts, active, -1);
              break;
            case "Home":
              next = firstEnabledIndex(opts);
              break;
            case "End":
              next = lastEnabledIndex(opts);
              break;
            case "Enter":
            case " ":
              e.preventDefault();
              selectIndex(active);
              return;
          }

          if (next != null) {
            e.preventDefault();
            activeIndex.value = next;
            scheduleMicrotask(focusActive);
            return;
          }

          final match = typeahead.handleKey(e, opts, startIndex: active);
          if (match != null) {
            e.preventDefault();
            activeIndex.value = match;
            scheduleMicrotask(focusActive);
            return;
          }
        }

        on(listbox, "keydown", onKeydown);

        onCleanup(clearTypeahead);
        onCleanup(typeahead.dispose);

        return listbox;
      },
    ),
  );
}

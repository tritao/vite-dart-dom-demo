import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./floating.dart";
import "./listbox_core.dart";
import "./overlay.dart";
import "./presence.dart";
import "./solid_dom.dart";

final class ComboboxOption<T> implements ListboxItem<T> {
  const ComboboxOption({
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

typedef ComboboxFilter<T> = bool Function(ComboboxOption<T> option, String input);

typedef ComboboxOptionBuilder<T> = web.HTMLElement Function(
  ComboboxOption<T> option, {
  required bool selected,
  required bool active,
});

int _comboboxIdCounter = 0;
String _nextComboboxId(String prefix) {
  _comboboxIdCounter++;
  return "$prefix-$_comboboxIdCounter";
}

web.DocumentFragment Combobox<T>({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required web.HTMLElement anchor,
  required web.HTMLInputElement input,
  required Iterable<ComboboxOption<T>> Function() options,
  required T? Function() value,
  required void Function(T? next) setValue,
  bool Function(T a, T b)? equals,
  String? listboxId,
  String placement = "bottom-start",
  double offset = 6,
  double viewportPadding = 8,
  bool flip = true,
  bool allowsEmptyCollection = false,
  bool closeOnSelection = true,
  ComboboxFilter<T>? filter,
  void Function(String reason)? onClose,
  int exitMs = 120,
  String? portalId,
  ComboboxOptionBuilder<T>? optionBuilder,
}) {
  bool eq(T a, T b) => equals != null ? equals(a, b) : a == b;
  final resolvedListboxId =
      listboxId ?? _nextComboboxId("solid-combobox-listbox");

  // Input state mirrors Kobalte: user types -> filter -> open/close.
  final inputValue = createSignal<String>("");
  final activeIndex = createSignal<int>(-1);

  void syncInputFromSelection() {
    final v = value();
    if (v == null) {
      inputValue.value = "";
      return;
    }
    for (final opt in options()) {
      if (eq(opt.value, v)) {
        inputValue.value = opt.label;
        return;
      }
    }
    inputValue.value = "";
  }

  // Keep input.value in sync with signal.
  createRenderEffect(() {
    final next = inputValue.value;
    if (input.value != next) input.value = next;
  });

  // If controlled value changes from outside, reflect in the input when closed.
  createEffect(() {
    final _ = value();
    if (!open()) syncInputFromSelection();
  });

  List<ComboboxOption<T>> filteredOptions() {
    final all = options().toList(growable: false);
    final q = inputValue.value;
    if (q.isEmpty) return all;
    final f = filter ??
        (ComboboxOption<T> option, String input) =>
            option.textValue.toLowerCase().contains(input.toLowerCase());
    return all.where((o) => f(o, q)).toList(growable: false);
  }

  void openNow([int? focusIndex]) {
    setOpen(true);
    if (focusIndex != null) {
      activeIndex.value = focusIndex;
    } else {
      final opts = filteredOptions();
      if (opts.isEmpty && !allowsEmptyCollection) {
        setOpen(false);
        return;
      }
      if (activeIndex.value < 0 || activeIndex.value >= opts.length) {
        activeIndex.value = firstEnabledIndex(opts);
      }
    }
  }

  void closeNow([String reason = "close"]) {
    onClose?.call(reason);
    setOpen(false);
  }

  void resetInputToSelection() {
    syncInputFromSelection();
  }

  void selectActive({required List<ComboboxOption<T>> opts}) {
    final idx = activeIndex.value;
    if (idx < 0 || idx >= opts.length) return;
    final opt = opts[idx];
    if (opt.disabled) return;
    setValue(opt.value);
    inputValue.value = opt.label;
    if (closeOnSelection) closeNow("select");
  }

  input
    ..setAttribute("role", "combobox")
    ..setAttribute("aria-autocomplete", "list")
    ..setAttribute("aria-haspopup", "listbox")
    ..setAttribute("autocomplete", "off");

  attr(input, "aria-expanded", () => open() ? "true" : "false");
  attr(input, "aria-controls", () => open() ? resolvedListboxId : null);
  attr(
    input,
    "aria-activedescendant",
    () {
      if (!open()) return null;
      final idx = activeIndex.value;
      final opts = filteredOptions();
      if (idx < 0 || idx >= opts.length) return null;
      return optionIdFor(opts, resolvedListboxId, idx);
    },
  );

  on(input, "input", (e) {
    if (e.target is! web.HTMLInputElement) return;
    inputValue.value = (e.target as web.HTMLInputElement).value;

    // If empty, keep it open only if configured.
    final opts = filteredOptions();
    if (open()) {
      if (opts.isEmpty && !allowsEmptyCollection) {
        closeNow("empty");
        resetInputToSelection();
        return;
      }
    } else {
      if (opts.isNotEmpty || allowsEmptyCollection) openNow();
    }
  });

  on(input, "focusin", (_) {
    // Kobalte can open on focus based on triggerMode; default to closed here.
  });

  on(input, "keydown", (e) {
    if (e is! web.KeyboardEvent) return;

    final opts = filteredOptions();
    if (e.key == "ArrowDown") {
      if (!open()) {
        e.preventDefault();
        openNow(firstEnabledIndex(opts));
        return;
      }
      e.preventDefault();
      activeIndex.value = nextEnabledIndex(opts, activeIndex.value, 1);
      return;
    }
    if (e.key == "ArrowUp") {
      if (!open()) {
        e.preventDefault();
        openNow(lastEnabledIndex(opts));
        return;
      }
      e.preventDefault();
      activeIndex.value = nextEnabledIndex(opts, activeIndex.value, -1);
      return;
    }
    if (e.key == "Enter") {
      if (!open()) return;
      e.preventDefault();
      selectActive(opts: opts);
      return;
    }
    if (e.key == "Escape") {
      if (open()) {
        e.preventDefault();
        closeNow("escape");
        resetInputToSelection();
      } else {
        // Mirror Kobalte: Escape when closed clears input.
        inputValue.value = "";
      }
      return;
    }
    if (e.key == "Tab") {
      if (open()) {
        closeNow("tab");
        resetInputToSelection();
      }
      return;
    }
  });

  // Clicking the input should open if there are results.
  on(input, "click", (_) {
    if (open()) return;
    final opts = filteredOptions();
    if (opts.isNotEmpty || allowsEmptyCollection) openNow();
  });

  return Presence(
    when: open,
    exitMs: exitMs,
    children: () => Portal(
      id: portalId,
      children: () {
        final listbox = web.HTMLDivElement()
          ..id = resolvedListboxId
          ..setAttribute("role", "listbox")
          ..className = "card";
        listbox.style.padding = "6px";
        listbox.style.minWidth = "240px";

        floatToAnchor(
          anchor: anchor,
          floating: listbox,
          placement: placement,
          offset: offset,
          viewportPadding: viewportPadding,
          flip: flip,
          updateOnScrollParents: true,
        );

        // Close and reset input when interacting outside.
        dismissableLayer(
          listbox,
          excludedElements: <web.Element? Function()>[
            () => anchor,
          ],
          onDismiss: (reason) {
            closeNow(reason);
            resetInputToSelection();
          },
        );

        void rebuild() {
          listbox.textContent = "";
          final opts = filteredOptions();
          if (opts.isEmpty && !allowsEmptyCollection) {
            closeNow("empty");
            resetInputToSelection();
            return;
          }

          // Clamp active index.
          var idx = activeIndex.value;
          if (idx >= opts.length) idx = opts.length - 1;
          if (idx < -1) idx = -1;
          if (idx == -1) idx = firstEnabledIndex(opts);
          activeIndex.value = idx;

          for (var i = 0; i < opts.length; i++) {
            final opt = opts[i];
            final selected = value() != null && eq(opt.value, value() as T);
            final active = i == activeIndex.value;
            final el = optionBuilder != null
                ? optionBuilder(opt, selected: selected, active: active)
                : (web.HTMLDivElement()
                  ..className = "menuItem"
                  ..textContent = opt.label);

            el.setAttribute("role", "option");
            el.id = optionIdFor(opts, resolvedListboxId, i);
            el.setAttribute("aria-selected", selected ? "true" : "false");
            if (opt.disabled) el.setAttribute("aria-disabled", "true");
            if (active) el.setAttribute("data-active", "true");

            on(el, "pointermove", (_) {
              if (opt.disabled) return;
              activeIndex.value = i;
            });
            on(el, "pointerdown", (ev) {
              // Prevent moving focus away from the input.
              ev.preventDefault();
            });
            on(el, "click", (_) {
              if (opt.disabled) return;
              activeIndex.value = i;
              selectActive(opts: opts);
            });

            listbox.appendChild(el);
          }
        }

        createRenderEffect(rebuild);

        return listbox;
      },
    ),
  );
}

import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./floating.dart";
import "./listbox_core.dart";
import "./listbox.dart";
import "./overlay.dart";
import "./presence.dart";
import "./selection/selection_manager.dart";
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
  bool keepOpenOnEmpty = false,
  String emptyText = "No results.",
  bool noResetInputOnBlur = false,
  bool closeOnSelection = true,
  ComboboxFilter<T>? filter,
  String triggerMode = "input",
  void Function(String reason)? onClose,
  int exitMs = 120,
  String? portalId,
  ComboboxOptionBuilder<T>? optionBuilder,
}) {
  bool eq(T a, T b) => equals != null ? equals(a, b) : a == b;
  final resolvedListboxId =
      listboxId ?? _nextComboboxId("solid-combobox-listbox");
  final ids = ListboxIdRegistry<T, ComboboxOption<T>>(listboxId: resolvedListboxId);
  final selection = SelectionManager();

  // Input state mirrors Kobalte: user types -> filter -> open/close.
  final inputValue = createSignal<String>("");
  final activeIndex = createSignal<int>(-1);
  final showAllOptions = createSignal(false);
  web.HTMLElement? listboxRef;
  ListboxHandle<T, ComboboxOption<T>>? listboxHandle;
  var isComposing = false;
  final allowEmpty = allowsEmptyCollection || keepOpenOnEmpty;
  final showEmptyState = keepOpenOnEmpty;

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

  // Keep selection manager in sync with controlled value (single selection).
  createEffect(() {
    final v = value();
    if (v == null) {
      selection.clearSelection();
      return;
    }
    for (final opt in options()) {
      if (eq(opt.value, v)) {
        selection.replaceSelection(ids.idForOption(opt));
        return;
      }
    }
    selection.clearSelection();
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

  List<ComboboxOption<T>> displayedOptions() {
    if (showAllOptions.value) return options().toList(growable: false);
    return filteredOptions();
  }

  void ensureActiveIndexWithin(List<ComboboxOption<T>> opts) {
    if (opts.isEmpty) {
      activeIndex.value = -1;
      return;
    }
    var idx = activeIndex.value;
    if (idx < 0) {
      final selIdx = findSelectedIndex<T, ComboboxOption<T>>(
        opts,
        value(),
        equals: eq,
      );
      idx = selIdx == -1 ? firstEnabledIndex(opts) : selIdx;
    }
    if (idx >= opts.length) idx = opts.length - 1;
    if (idx >= 0 && opts[idx].disabled) idx = nextEnabledIndex(opts, idx, 1);
    activeIndex.value = idx;
  }

  void openNow({int? focusIndex, bool showAll = false}) {
    showAllOptions.value = showAll;
    setOpen(true);
    final opts = displayedOptions();
    if (focusIndex != null) {
      activeIndex.value = focusIndex;
    } else {
      if (opts.isEmpty && !allowEmpty) {
        showAllOptions.value = false;
        setOpen(false);
        return;
      }
      ensureActiveIndexWithin(opts);
    }
  }

  void closeNow([String reason = "close"]) {
    onClose?.call(reason);
    setOpen(false);
    showAllOptions.value = false;
  }

  void resetInputToSelection() {
    if (noResetInputOnBlur && value() == null) return;
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
      final opts = displayedOptions();
      if (idx < 0 || idx >= opts.length) return null;
      return ids.idForIndex(opts, idx);
    },
  );

  on(input, "input", (e) {
    if (e.target is! web.HTMLInputElement) return;
    final target = e.target as web.HTMLInputElement;
    inputValue.value = target.value;
    showAllOptions.value = false;
    // Keep DOM value in sync (inputs can drift even if "controlled").
    target.value = inputValue.value;
    if (isComposing) return;

    // If empty, keep it open only if configured.
    final opts = displayedOptions();
    if (open()) {
      ensureActiveIndexWithin(opts);
      if (opts.isEmpty && !allowEmpty) {
        closeNow("empty");
        resetInputToSelection();
        return;
      }
    } else {
      if (triggerMode == "manual") return;
      if (opts.isNotEmpty || allowEmpty) openNow(showAll: false);
    }
  });

  on(input, "focusin", (_) {
    if (triggerMode != "focus") return;
    if (open()) return;
    final opts = displayedOptions();
    if (opts.isNotEmpty || allowEmpty) openNow(showAll: false);
  });

  on(input, "focusout", (e) {
    if (!open()) return;
    if (e is! web.FocusEvent) return;
    final next = e.relatedTarget;
    if (next is web.Node) {
      if (anchor.contains(next)) return;
      final lb = listboxRef;
      if (lb != null && lb.contains(next)) return;
    }
    // Close on genuine blur.
    closeNow("blur");
    resetInputToSelection();
  });

  on(input, "compositionstart", (_) {
    isComposing = true;
  });
  on(input, "compositionend", (_) {
    isComposing = false;
    inputValue.value = input.value;
    showAllOptions.value = false;
    if (triggerMode == "manual") return;
    final opts = displayedOptions();
    if (opts.isEmpty && !allowEmpty) {
      if (open()) {
        closeNow("empty");
        resetInputToSelection();
      }
      return;
    }
    if (!open() && (opts.isNotEmpty || allowEmpty)) openNow(showAll: false);
  });

  on(input, "keydown", (e) {
    if (e is! web.KeyboardEvent) return;
    if (isComposing) return;

    final opts = displayedOptions();
    if (e.key == "ArrowDown") {
      if (!open()) {
        final all = options().toList(growable: false);
        e.preventDefault();
        openNow(
          focusIndex: e.altKey ? null : firstEnabledIndex(all),
          showAll: true,
        );
        return;
      }
      e.preventDefault();
      listboxHandle?.handleKeyDown(e, allowTypeAhead: false, allowSpaceSelect: false);
      return;
    }
    if (e.key == "ArrowUp") {
      if (!open()) {
        final all = options().toList(growable: false);
        e.preventDefault();
        openNow(focusIndex: lastEnabledIndex(all), showAll: true);
        return;
      }
      if (e.altKey) {
        e.preventDefault();
        closeNow("escape");
        resetInputToSelection();
        return;
      }
      e.preventDefault();
      listboxHandle?.handleKeyDown(e, allowTypeAhead: false, allowSpaceSelect: false);
      return;
    }
    if (e.key == "Home" ||
        e.key == "End" ||
        e.key == "PageDown" ||
        e.key == "PageUp") {
      if (!open()) return;
      e.preventDefault();
      listboxHandle?.handleKeyDown(e, allowTypeAhead: false, allowSpaceSelect: false);
      return;
    }
    if (e.key == "ArrowLeft" || e.key == "ArrowRight") {
      activeIndex.value = -1;
      selection.setFocusedKey(null);
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
    if (triggerMode == "manual") return;
    final opts = displayedOptions();
    if (opts.isNotEmpty || allowEmpty) openNow(showAll: false);
  });

  return Presence(
    when: open,
    exitMs: exitMs,
    children: () => Portal(
      id: portalId,
      children: () {
        final listbox = createListbox<T, ComboboxOption<T>>(
          id: resolvedListboxId,
          options: displayedOptions,
          selected: value,
          equals: eq,
          activeIndex: activeIndex,
          shouldUseVirtualFocus: true,
          shouldFocusOnHover: true,
          enableKeyboardNavigation: true,
          disallowTypeAhead: true,
          showEmptyState: showEmptyState,
          emptyText: emptyText,
          idRegistry: ids,
          onSelect: (opt, idx) {
            setValue(opt.value);
            inputValue.value = opt.label;
            if (closeOnSelection) closeNow("select");
          },
          optionBuilder: optionBuilder == null
              ? null
              : (opt, {required selected, required active}) =>
                  optionBuilder(opt, selected: selected, active: active),
        );
        listbox.element.style.padding = "6px";
        listbox.element.style.minWidth = "240px";
        listboxRef = listbox.element;
        listboxHandle = listbox;
        onCleanup(() {
          if (identical(listboxRef, listbox.element)) listboxRef = null;
          if (identical(listboxHandle, listbox)) listboxHandle = null;
        });

        floatToAnchor(
          anchor: anchor,
          floating: listbox.element,
          placement: placement,
          offset: offset,
          viewportPadding: viewportPadding,
          flip: flip,
          updateOnScrollParents: true,
        );

        // Close and reset input when interacting outside.
          dismissableLayer(
            listbox.element,
            excludedElements: <web.Element? Function()>[
              () => anchor,
            ],
            onDismiss: (reason) {
              closeNow(reason);
              resetInputToSelection();
            },
          );
          createRenderEffect(() {
            final opts = displayedOptions();
            if (opts.isEmpty && !allowEmpty) {
              closeNow("empty");
              resetInputToSelection();
              return;
            }
            ensureActiveIndexWithin(opts);
        });

        return listbox.element;
      },
    ),
  );
}

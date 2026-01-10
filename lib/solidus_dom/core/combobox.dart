import "dart:async";

import "package:solidus/solidus.dart";
import "package:web/web.dart" as web;

import "./listbox_core.dart";
import "./listbox.dart";
import "../overlay.dart";
import "../popper.dart";
import "../presence.dart";
import "../selection/utils.dart";
import "../solid_dom.dart";

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

web.DocumentFragment createCombobox<T>({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required web.HTMLElement anchor,
  required web.HTMLInputElement input,
  web.HTMLButtonElement? triggerButton,
  required Iterable<ComboboxOption<T>> Function() options,
  required T? Function() value,
  required void Function(T? next) setValue,
  bool Function(T a, T b)? equals,
  String? listboxId,
  String placement = "bottom-start",
  double offset = 6,
  double viewportPadding = 8,
  bool flip = true,
  bool showArrow = false,
  double arrowPadding = 4,
  bool allowsEmptyCollection = false,
  bool keepOpenOnEmpty = false,
  String emptyText = "No results.",
  bool noResetInputOnBlur = false,
  bool disallowEmptySelection = false,
  bool closeOnSelection = true,
  ComboboxFilter<T>? filter,
  String triggerMode = "input",
  void Function(String reason)? onClose,
  int exitMs = 0,
  String? portalId,
  String listboxClassName = "",
  String listboxScrollClassName = "",
  String listboxOptionClassName = "",
  String listboxSectionGroupClassName = "",
  String listboxSectionLabelClassName = "",
  String listboxEmptyClassName = "",
  ComboboxOptionBuilder<T>? optionBuilder,
}) {
  bool eq(T a, T b) => equals != null ? equals(a, b) : a == b;
  final resolvedListboxId =
      listboxId ?? _nextComboboxId("solid-combobox-listbox");
  final ids = ListboxIdRegistry<T, ComboboxOption<T>>(listboxId: resolvedListboxId);

  // Input state mirrors Kobalte: user types -> filter -> open/close.
  final inputValue = createSignal<String>("");
  final showAllOptions = createSignal(false);
  web.HTMLElement? listboxRef;
  final listboxHandleSig =
      createSignal<ListboxHandle<T, ComboboxOption<T>>?>(null);
  final pendingInitialIndex = createSignal<int?>(null);
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

  String? selectedLabel() {
    final v = value();
    if (v == null) return null;
    for (final opt in options()) {
      if (eq(opt.value, v)) return opt.label;
    }
    return null;
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

  List<ComboboxOption<T>> displayedOptions() {
    if (showAllOptions.value) return options().toList(growable: false);
    return filteredOptions();
  }

  void openNow({int? focusIndex, bool showAll = false}) {
    showAllOptions.value = showAll;
    setOpen(true);
    if (focusIndex != null) {
      pendingInitialIndex.value = focusIndex;
    } else {
      pendingInitialIndex.value = null;
      final opts = displayedOptions();
      if (opts.isEmpty && !allowEmpty) {
        showAllOptions.value = false;
        setOpen(false);
        return;
      }
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
      final handle = listboxHandleSig.value;
      return handle?.selectionManager.focusedKey();
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
      listboxHandleSig.value?.handleKeyDown(
        e,
        allowTypeAhead: false,
        allowSpaceSelect: false,
      );
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
      listboxHandleSig.value?.handleKeyDown(
        e,
        allowTypeAhead: false,
        allowSpaceSelect: false,
      );
      return;
    }
    if (e.key == "Home" ||
        e.key == "End" ||
        e.key == "PageDown" ||
        e.key == "PageUp") {
      if (!open()) return;
      e.preventDefault();
      listboxHandleSig.value?.handleKeyDown(
        e,
        allowTypeAhead: false,
        allowSpaceSelect: false,
      );
      return;
    }
    if (e.key == "ArrowLeft" || e.key == "ArrowRight") {
      listboxHandleSig.value?.selectionManager.setFocusedKey(null);
      return;
    }
    if (e.key == "Enter") {
      if (!open()) return;
      e.preventDefault();
      listboxHandleSig.value?.handleKeyDown(
        e,
        allowTypeAhead: false,
        allowSpaceSelect: false,
      );
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
    // UX: clicking a closed combobox should generally show the full list,
    // especially when the input is showing the committed selection.
    final label = selectedLabel();
    final current = inputValue.value;
    final showAll = current.isEmpty || (label != null && current == label);
    final opts = showAll
        ? options().toList(growable: false)
        : displayedOptions();
    if (opts.isNotEmpty || allowEmpty) openNow(showAll: showAll);
  });

  if (triggerButton != null) {
    triggerButton
      ..type = "button"
      ..setAttribute("aria-haspopup", "listbox");
    if ((triggerButton.getAttribute("aria-label") ?? "").isEmpty) {
      triggerButton.setAttribute("aria-label", "Show options");
    }
    attr(triggerButton, "aria-expanded", () => open() ? "true" : "false");
    attr(triggerButton, "aria-controls", () => open() ? resolvedListboxId : null);

    void toggle() {
      if (open()) {
        closeNow("toggle");
        resetInputToSelection();
        return;
      }
      openNow(showAll: true);
      scheduleMicrotask(() => focusWithoutScrolling(input));
    }

    on(triggerButton, "click", (_) => toggle());
    on(triggerButton, "keydown", (e) {
      if (e is! web.KeyboardEvent) return;
      if (e.key != "Enter" && e.key != " ") return;
      e.preventDefault();
      toggle();
    });
  }

  return Presence(
    when: open,
    exitMs: exitMs,
    children: () => Portal(
      id: portalId,
      children: () {
        web.HTMLElement? arrowEl;
        final listbox = createListboxCore<T, ComboboxOption<T>>(
          id: resolvedListboxId,
          options: displayedOptions,
          selected: value,
          equals: eq,
          shouldUseVirtualFocus: true,
          shouldFocusOnHover: true,
          enableKeyboardNavigation: true,
          disallowTypeAhead: true,
          disallowEmptySelection: disallowEmptySelection,
          showEmptyState: showEmptyState,
          emptyText: emptyText,
          idRegistry: ids,
          useInnerScrollContainer: showArrow,
          rootClassName: listboxClassName,
          scrollClassName: listboxScrollClassName,
          optionClassName: listboxOptionClassName,
          sectionGroupClassName: listboxSectionGroupClassName,
          sectionLabelClassName: listboxSectionLabelClassName,
          emptyClassName: listboxEmptyClassName,
          initialActiveIndex: () {
            final idx = pendingInitialIndex.value;
            if (idx != null) {
              pendingInitialIndex.value = null;
              return idx;
            }
            return -1;
          },
          onSelect: (opt, idx) {
            setValue(opt.value);
            inputValue.value = opt.label;
            if (closeOnSelection) closeNow("select");
          },
          onClearSelection: () {
            setValue(null);
            inputValue.value = "";
            if (closeOnSelection) closeNow("select");
          },
          optionBuilder: optionBuilder == null
              ? null
              : (opt, {required selected, required active}) =>
                  optionBuilder(opt, selected: selected, active: active),
        );
        if (showArrow) {
          arrowEl = web.HTMLDivElement()
            ..className = "popperArrow"
            ..setAttribute("data-solidus-popper-arrow", "1");
          listbox.element.appendChild(arrowEl!);
        }
        listboxRef = listbox.element;
        listboxHandleSig.value = listbox;
        onCleanup(() {
          if (identical(listboxRef, listbox.element)) listboxRef = null;
          if (identical(listboxHandleSig.value, listbox)) {
            listboxHandleSig.value = null;
          }
        });

        attachPopper(
          anchor: anchor,
          floating: listbox.element,
          placement: placement,
          offset: offset,
          viewportPadding: viewportPadding,
          flip: flip,
          sameWidth: true,
          fitViewport: true,
          arrow: arrowEl,
          arrowPadding: arrowPadding,
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
        });

        return listbox.element;
      },
    ),
  );
}

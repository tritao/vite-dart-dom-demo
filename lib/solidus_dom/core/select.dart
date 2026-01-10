import "dart:async";

import "package:solidus/solidus.dart";
import "package:web/web.dart" as web;

import "./listbox_core.dart";
import "./listbox.dart";
import "../focus_scope.dart";
import "../overlay.dart";
import "../popper.dart";
import "../presence.dart";
import "../solid_dom.dart";

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

web.DocumentFragment createSelect<T>({
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
  double shift = 0,
  bool slide = true,
  bool overlap = false,
  bool fitViewport = true,
  bool disallowEmptySelection = false,
  int exitMs = 120,
  String? portalId,
  String? listboxId,
  String listboxClassName = "",
  String listboxScrollClassName = "",
  String listboxOptionClassName = "",
  String listboxSectionGroupClassName = "",
  String listboxSectionLabelClassName = "",
  String listboxEmptyClassName = "",
  SelectOptionBuilder<T>? optionBuilder,
}) {
  bool eq(T a, T b) => equals != null ? equals(a, b) : a == b;

  final resolvedListboxId = listboxId ?? _nextSelectId("solid-select-listbox");
  final ids = ListboxIdRegistry<T, SelectOption<T>>(listboxId: resolvedListboxId);
  trigger.setAttribute("aria-haspopup", "listbox");
  attr(trigger, "aria-expanded", () => open() ? "true" : "false");
  attr(trigger, "aria-controls", () => open() ? resolvedListboxId : null);

  var closeReason = "close";
  ListboxHandle<T, SelectOption<T>>? currentHandle;

  void close([String reason = "close"]) {
    closeReason = reason;
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
    // When open, keep keyboard interactions working even if focus hasn't moved
    // to the listbox yet (mirrors Kobalte's "virtual focus owner" behavior).
    if (open()) {
      if (e.key == "Tab") {
        close("tab");
        return;
      }
      if (e.key == "Escape") {
        e.preventDefault();
        close("escape");
        return;
      }
      final handle = currentHandle;
      if (handle != null) {
        handle.handleKeyDown(e);
      }
      return;
    }

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
        final handle = createListboxCore<T, SelectOption<T>>(
          id: resolvedListboxId,
          options: () => options().toList(growable: false),
          selected: value,
          equals: eq,
          idRegistry: ids,
          shouldUseVirtualFocus: true,
          shouldFocusOnHover: true,
          disallowEmptySelection: disallowEmptySelection,
          rootClassName: listboxClassName,
          scrollClassName: listboxScrollClassName,
          optionClassName: listboxOptionClassName,
          sectionGroupClassName: listboxSectionGroupClassName,
          sectionLabelClassName: listboxSectionLabelClassName,
          emptyClassName: listboxEmptyClassName,
          onTabOut: () {
            close("tab");
            try {
              trigger.focus();
            } catch (_) {}
          },
          onEscape: () => close("escape"),
          onSelect: (opt, idx) {
            setValue(opt.value);
            close("select");
          },
          onClearSelection: () {
            setValue(null);
            close("select");
          },
          optionBuilder: optionBuilder == null
              ? null
              : (opt, {required selected, required active}) =>
                  optionBuilder(opt, selected, active),
        );
        handle.element.setAttribute("data-solidus-select-listbox", "1");
        currentHandle = handle;
        onCleanup(() {
          if (identical(currentHandle, handle)) currentHandle = null;
        });

        attachPopper(
          anchor: trigger,
          floating: handle.element,
          placement: placement,
          offset: offset,
          viewportPadding: viewportPadding,
          flip: flip,
          shift: shift,
          slide: slide,
          overlap: overlap,
          sameWidth: true,
          fitViewport: fitViewport,
          updateOnScrollParents: true,
        );

        // Outside dismissal should not consider the trigger "outside" (otherwise
        // trigger click can close + immediately re-open).
        dismissableLayer(
          handle.element,
          excludedElements: <web.Element? Function()>[
            () => trigger,
          ],
          onDismiss: (reason) => close(reason),
          preventClickThrough: true,
        );
        // Use the created listbox element as our positioned element.
        // (createListboxCore already set id/role/className).

        // Focus management: focus active option on mount, restore focus unless Tab-close.
        focusScope(
          handle.element,
          trapFocus: false,
          restoreFocus: true,
          onMountAutoFocus: (e) {
            e.preventDefault();
            try {
              handle.element.focus(web.FocusOptions(preventScroll: true));
            } catch (_) {}
          },
          onUnmountAutoFocus: (e) {
            if (closeReason == "tab") e.preventDefault();
          },
        );
        return handle.element;
      },
    ),
  );
}

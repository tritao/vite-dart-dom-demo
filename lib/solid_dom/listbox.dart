import "dart:async";
import "dart:math";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./listbox_core.dart";
import "./solid_dom.dart";

typedef ListboxOptionBuilder<T, O extends ListboxItem<T>> = web.HTMLElement
    Function(
  O option, {
  required bool selected,
  required bool active,
});

final class ListboxHandle<T, O extends ListboxItem<T>> {
  ListboxHandle._(
    this.element, {
    required this.activeIndex,
    required this.activeId,
    required this.setActiveIndex,
    required this.selectActive,
    required this.moveActive,
    required this.focusActive,
  });

  final web.HTMLElement element;
  final Signal<int> activeIndex;
  final String? Function() activeId;

  /// Sets active index and updates option tabIndex/scrolling; focuses option if
  /// not in virtual focus mode.
  final void Function(int next) setActiveIndex;

  /// Selects the active option (if any).
  final void Function() selectActive;

  /// Move active by delta (uses enabled navigation + wrapping rules).
  final void Function(int delta) moveActive;

  /// Focuses the active option if not in virtual focus mode.
  final void Function() focusActive;
}

ListboxHandle<T, O> createListbox<T, O extends ListboxItem<T>>({
  required String id,
  List<O> Function()? options,
  Iterable<ListboxSection<T, O>> Function()? sections,
  required T? Function() selected,
  required void Function(O option, int index) onSelect,
  bool Function(T a, T b)? equals,
  Signal<int>? activeIndex,
  int Function()? initialActiveIndex,
  bool shouldUseVirtualFocus = false,
  bool shouldFocusOnHover = true,
  bool shouldFocusWrap = true,
  bool disallowTypeAhead = false,
  bool enableKeyboardNavigation = true,
  void Function()? onTabOut,
  void Function()? onEscape,
  String emptyText = "No results.",
  bool showEmptyState = false,
  Object? Function(O option)? getOptionKey,
  ListboxIdRegistry<T, O>? idRegistry,
  web.HTMLElement? Function()? scrollContainer,
  void Function(int index)? scrollToIndex,
  int Function()? pageSize,
  ListboxOptionBuilder<T, O>? optionBuilder,
}) {
  final eq = equals ?? defaultListboxEquals<T>;
  if (options == null && sections == null) {
    throw StateError("createListbox: provide options or sections");
  }
  final listbox = web.HTMLDivElement()
    ..id = id
    ..setAttribute("role", "listbox")
    ..tabIndex = shouldUseVirtualFocus ? -1 : -1
    ..className = "card";

  final ids =
      idRegistry ?? ListboxIdRegistry<T, O>(listboxId: id, getOptionKey: getOptionKey);

  List<O> currentOptions() {
    if (sections != null) {
      final out = <O>[];
      for (final section in sections()) {
        out.addAll(section.options);
      }
      return out;
    }
    return options!();
  }

  final activeIndexSig = activeIndex ??
      createSignal<int>(
        initialActiveIndex?.call() ??
            (() {
              final opts = currentOptions();
              final sel = selected();
              final idx = findSelectedIndex<T, O>(opts, sel, equals: eq);
              return idx == -1 ? firstEnabledIndex(opts) : idx;
            })(),
      );

  final optionEls = <web.HTMLElement>[];

  String? activeId() {
    final idx = activeIndexSig.value;
    final opts = currentOptions();
    if (idx < 0 || idx >= opts.length) return null;
    return ids.idForIndex(opts, idx);
  }

  void scrollElementIntoView(web.HTMLElement container, web.HTMLElement el) {
    try {
      final cRect = container.getBoundingClientRect();
      final eRect = el.getBoundingClientRect();
      final viewTop = container.scrollTop;
      final viewBottom = viewTop + cRect.height;
      final elTop = (eRect.top - cRect.top) + viewTop;
      final elBottom = elTop + eRect.height;

      if (elTop < viewTop) {
        container.scrollTop = elTop;
      } else if (elBottom > viewBottom) {
        container.scrollTop = elBottom - cRect.height;
      }
    } catch (_) {
      try {
        el.scrollIntoView();
      } catch (_) {}
    }
  }

  void scrollActiveIntoView() {
    final idx = activeIndexSig.value;
    if (idx < 0 || idx >= optionEls.length) return;
    if (scrollToIndex != null) {
      scrollToIndex(idx);
      return;
    }
    final el = optionEls[idx];
    final container = scrollContainer?.call() ?? listbox;
    scrollElementIntoView(container, el);
  }

  void focusActive() {
    if (shouldUseVirtualFocus) return;
    final idx = activeIndexSig.value;
    if (idx < 0 || idx >= optionEls.length) return;
    try {
      optionEls[idx].focus();
    } catch (_) {}
  }

  void syncTabIndex() {
    if (optionEls.isEmpty) return;
    final active = activeIndexSig.value.clamp(0, optionEls.length - 1);
    for (var i = 0; i < optionEls.length; i++) {
      optionEls[i].tabIndex = shouldUseVirtualFocus ? -1 : (i == active ? 0 : -1);
      if (i == active) {
        optionEls[i].setAttribute("data-active", "true");
      } else {
        optionEls[i].removeAttribute("data-active");
      }
    }
  }

  void setActiveIndex(int next) {
    final opts = currentOptions();
    if (opts.isEmpty) {
      activeIndexSig.value = -1;
      return;
    }
    var idx = next;
    if (idx < 0) idx = 0;
    if (idx >= opts.length) idx = opts.length - 1;
    if (opts[idx].disabled) {
      idx = shouldFocusWrap
          ? nextEnabledIndex(opts, idx, 1)
          : nextEnabledIndexNoWrap(opts, idx, 1);
    }
    activeIndexSig.value = idx;
    scheduleMicrotask(() {
      syncTabIndex();
      scrollActiveIntoView();
      focusActive();
    });
  }

  void moveActive(int delta) {
    final opts = currentOptions();
    if (opts.isEmpty) return;
    final current = activeIndexSig.value;
    int next;
    if (!shouldFocusWrap) {
      next = (current + delta).clamp(0, opts.length - 1);
      if (opts[next].disabled) {
        next = delta > 0
            ? nextEnabledIndexNoWrap(opts, next, 1)
            : nextEnabledIndexNoWrap(opts, next, -1);
      }
    } else {
      next = nextEnabledIndex(opts, current < 0 ? 0 : current, delta);
    }
    setActiveIndex(next);
  }

  void selectActive() {
    final idx = activeIndexSig.value;
    final opts = currentOptions();
    if (idx < 0 || idx >= opts.length) return;
    final opt = opts[idx];
    if (opt.disabled) return;
    onSelect(opt, idx);
  }

  final typeahead = ListboxTypeahead();

  int computePageSize() {
    try {
      final fromProp = pageSize?.call();
      if (fromProp != null && fromProp > 0) return fromProp;
    } catch (_) {}

    if (optionEls.isEmpty) return 5;
    final container = scrollContainer?.call() ?? listbox;
    final idx = activeIndexSig.value;
    final base =
        (idx >= 0 && idx < optionEls.length) ? optionEls[idx] : optionEls.first;
    try {
      final cH = container.getBoundingClientRect().height;
      final eH = base.getBoundingClientRect().height;
      if (cH <= 0 || eH <= 0) return 5;
      return max(1, (cH / eH).floor() - 1);
    } catch (_) {
      return 5;
    }
  }

  void moveActiveByPage(int direction) {
    final opts = currentOptions();
    if (opts.isEmpty) return;
    final step = computePageSize();
    final current = activeIndexSig.value < 0 ? 0 : activeIndexSig.value;
    var next = current + (direction * step);
    if (shouldFocusWrap) {
      next = ((next % opts.length) + opts.length) % opts.length;
      if (opts[next].disabled) {
        next = nextEnabledIndex(opts, next, direction >= 0 ? 1 : -1);
      }
    } else {
      next = next.clamp(0, opts.length - 1);
      if (opts[next].disabled) {
        next = nextEnabledIndexNoWrap(opts, next, direction >= 0 ? 1 : -1);
      }
    }
    setActiveIndex(next);
  }

  void onKeydown(web.Event e) {
    if (!enableKeyboardNavigation) return;
    if (e is! web.KeyboardEvent) return;
    final opts = currentOptions();
    if (e.key == "Tab") {
      onTabOut?.call();
      return;
    }
    if (e.key == "Escape") {
      e.preventDefault();
      onEscape?.call();
      return;
    }
    if (opts.isEmpty) return;

    int? next;
    switch (e.key) {
      case "ArrowDown":
        if (shouldFocusWrap) {
          next = nextEnabledIndex(opts, activeIndexSig.value, 1);
        } else {
          next = (activeIndexSig.value + 1).clamp(0, opts.length - 1);
          if (opts[next].disabled) next = nextEnabledIndexNoWrap(opts, next, 1);
        }
        break;
      case "ArrowUp":
        if (shouldFocusWrap) {
          next = nextEnabledIndex(opts, activeIndexSig.value, -1);
        } else {
          next = (activeIndexSig.value - 1).clamp(0, opts.length - 1);
          if (opts[next].disabled) next = nextEnabledIndexNoWrap(opts, next, -1);
        }
        break;
      case "Home":
        next = firstEnabledIndex(opts);
        break;
      case "End":
        next = lastEnabledIndex(opts);
        break;
      case "PageDown":
        e.preventDefault();
        moveActiveByPage(1);
        return;
      case "PageUp":
        e.preventDefault();
        moveActiveByPage(-1);
        return;
      case "Enter":
      case " ":
        e.preventDefault();
        selectActive();
        return;
    }

    if (next != null) {
      e.preventDefault();
      setActiveIndex(next);
      return;
    }

    if (!disallowTypeAhead) {
      final match = typeahead.handleKey(e, opts, startIndex: activeIndexSig.value);
      if (match != null) {
        e.preventDefault();
        setActiveIndex(match);
      }
    }
  }

  on(listbox, "keydown", onKeydown);
  onCleanup(typeahead.dispose);

  web.HTMLElement buildOption(O option, int idx, bool selected, bool active) {
    final el = optionBuilder != null
        ? optionBuilder(option, selected: selected, active: active)
        : (web.HTMLDivElement()
          ..className = "menuItem"
          ..textContent = option.label);

    el.setAttribute("role", "option");
    el.id = ids.idForOption(option);
    el.setAttribute("aria-selected", selected ? "true" : "false");
    if (option.disabled) el.setAttribute("aria-disabled", "true");
    if (active) el.setAttribute("data-active", "true");
    el.tabIndex = shouldUseVirtualFocus ? -1 : (active ? 0 : -1);

    if (shouldUseVirtualFocus) {
      on(el, "pointerdown", (ev) {
        // Keep focus on the virtual focus target (e.g., input).
        ev.preventDefault();
      });
    }

    on(el, "pointerenter", (_) {
      if (!shouldFocusOnHover) return;
      if (option.disabled) return;
      if (activeIndexSig.value == idx) return;
      activeIndexSig.value = idx;
      scheduleMicrotask(() {
        syncTabIndex();
        focusActive();
      });
    });

    on(el, "click", (_) {
      if (option.disabled) return;
      activeIndexSig.value = idx;
      selectActive();
    });

    return el;
  }

  createRenderEffect(() {
    final shouldRestoreFocus = !shouldUseVirtualFocus &&
        (() {
          try {
            final activeEl = web.document.activeElement;
            if (activeEl is web.Node) return listbox.contains(activeEl);
          } catch (_) {}
          return false;
        })();

    listbox.textContent = "";
    optionEls.clear();
    final opts = currentOptions();
    final sel = selected();

    if (opts.isEmpty) {
      activeIndexSig.value = -1;
      if (showEmptyState) {
        final empty = web.HTMLDivElement()
          ..setAttribute("data-empty", "1")
          ..textContent = emptyText;
        empty.style.padding = "10px 12px";
        empty.style.opacity = "0.8";
        listbox.appendChild(empty);
      }
      return;
    }

    // Clamp active index to range and make sure it's enabled.
    var active = untrack(() => activeIndexSig.value);
    if (active < 0) active = firstEnabledIndex(opts);
    if (active >= opts.length) active = opts.length - 1;
    if (active >= 0 && opts[active].disabled) active = nextEnabledIndex(opts, active, 1);
    activeIndexSig.value = active;

    if (sections != null) {
      var flatIdx = 0;
      var sectionIdx = 0;
      for (final section in sections()) {
        final labelId =
            section.id != null ? "$id-section-${section.id}-label" : "$id-section-$sectionIdx-label";
        final group = web.HTMLDivElement()
          ..setAttribute("role", "group")
          ..setAttribute("aria-labelledby", labelId);
        group.style.padding = "4px 0";

        final label = web.HTMLDivElement()
          ..id = labelId
          ..textContent = section.label;
        label.style.fontSize = "12px";
        label.style.opacity = "0.7";
        label.style.padding = "4px 8px";
        group.appendChild(label);

        for (final opt in section.options) {
          final isSelected = sel != null && eq(opt.value, sel);
          final isActive = flatIdx == active;
          final el = buildOption(opt, flatIdx, isSelected, isActive);
          optionEls.add(el);
          group.appendChild(el);
          flatIdx++;
        }

        listbox.appendChild(group);
        sectionIdx++;
      }
    } else {
      for (var i = 0; i < opts.length; i++) {
        final opt = opts[i];
        final isSelected = sel != null && eq(opt.value, sel);
        final isActive = i == active;
        final el = buildOption(opt, i, isSelected, isActive);
        optionEls.add(el);
        listbox.appendChild(el);
      }
    }

    scheduleMicrotask(() {
      syncTabIndex();
      scrollActiveIntoView();
      if (shouldRestoreFocus) focusActive();
    });
  });

  return ListboxHandle._(
    listbox,
    activeIndex: activeIndexSig,
    activeId: activeId,
    setActiveIndex: setActiveIndex,
    selectActive: selectActive,
    moveActive: moveActive,
    focusActive: focusActive,
  );
}

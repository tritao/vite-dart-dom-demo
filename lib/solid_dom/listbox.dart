import "dart:async";
import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./listbox_core.dart";
import "./selection/list_keyboard_delegate.dart";
import "./selection/type_select.dart";
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
    required this.activeKey,
    required this.setActiveKey,
    required this.setActiveIndex,
    required this.selectActive,
    required this.moveActive,
    required this.focusActive,
    required this.handleKeyDown,
  });

  final web.HTMLElement element;
  final Signal<int> activeIndex;
  final String? Function() activeId;
  final String? Function() activeKey;
  final void Function(String? key) setActiveKey;

  /// Sets active index and updates option tabIndex/scrolling; focuses option if
  /// not in virtual focus mode.
  final void Function(int next) setActiveIndex;

  /// Selects the active option (if any).
  final void Function() selectActive;

  /// Move active by delta (uses enabled navigation + wrapping rules).
  final void Function(int delta) moveActive;

  /// Focuses the active option if not in virtual focus mode.
  final void Function() focusActive;

  /// Handles keyboard navigation when the listbox itself isn't focused
  /// (e.g., virtual focus listboxes driven by an input).
  final void Function(
    web.KeyboardEvent e, {
    bool allowTypeAhead,
    bool allowSpaceSelect,
  }) handleKeyDown;
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
    ..className = "card listbox";

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
  final optionElByKey = <String, web.HTMLElement>{};
  final indexByKey = <String, int>{};
  final optionsByKey = <String, O>{};
  var currentKeys = <String>[];
  var lastSyncedActive = -2;

  String? activeId() {
    final idx = activeIndexSig.value;
    final opts = currentOptions();
    if (idx < 0 || idx >= opts.length) return null;
    return ids.idForIndex(opts, idx);
  }

  String? activeKey() => activeId();

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
      optionEls[idx].focus(web.FocusOptions(preventScroll: true));
    } catch (_) {}
  }

  void syncTabIndex({bool force = false}) {
    if (optionEls.isEmpty) return;
    final nextActive = activeIndexSig.value;

    void setItemActive(int index, bool isActive) {
      if (index < 0 || index >= optionEls.length) return;
      final el = optionEls[index];
      el.tabIndex = shouldUseVirtualFocus ? -1 : (isActive ? 0 : -1);
      if (isActive) {
        el.setAttribute("data-active", "true");
      } else {
        el.removeAttribute("data-active");
      }
    }

    if (!force && lastSyncedActive == nextActive) return;

    // Fast path: update only previous and current active.
    if (!force &&
        lastSyncedActive >= -1 &&
        lastSyncedActive < optionEls.length &&
        nextActive >= -1 &&
        nextActive < optionEls.length) {
      if (lastSyncedActive != -1) setItemActive(lastSyncedActive, false);
      if (nextActive != -1) setItemActive(nextActive, true);
      lastSyncedActive = nextActive;
      return;
    }

    // Slow path: (re)sync all options.
    for (var i = 0; i < optionEls.length; i++) {
      final isActive = i == nextActive;
      setItemActive(i, isActive);
    }
    lastSyncedActive =
        (nextActive >= -1 && nextActive < optionEls.length) ? nextActive : -1;
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

  final typeSelect = TypeSelect();

  ListKeyboardDelegate delegate() => ListKeyboardDelegate(
        keys: () => currentKeys,
        isDisabled: (key) => optionsByKey[key]?.disabled ?? false,
        textValueForKey: (key) => optionsByKey[key]?.textValue ?? "",
        getContainer: () => scrollContainer?.call() ?? listbox,
        getItemElement: (key) => optionElByKey[key],
        pageSize: pageSize,
      );

  void setActiveKey(String? key) {
    if (key == null) return;
    final idx = indexByKey[key];
    if (idx == null) return;
    setActiveIndex(idx);
  }

  if (shouldUseVirtualFocus) {
    // When the focus target is external (e.g. combobox input), callers often
    // drive activeIndex directly. Mirror Kobalte's derived updates by syncing
    // option state whenever activeIndex changes.
    createEffect(() {
      final _ = activeIndexSig.value;
      scheduleMicrotask(() {
        syncTabIndex();
        scrollActiveIntoView();
      });
    });
  }

  void handleKeyDown(
    web.KeyboardEvent e, {
    bool allowTypeAhead = true,
    bool allowSpaceSelect = true,
  }) {
    if (!enableKeyboardNavigation) return;
    if (e.key == "Tab") {
      onTabOut?.call();
      return;
    }
    if (e.key == "Escape") {
      e.preventDefault();
      onEscape?.call();
      return;
    }

    if (currentKeys.isEmpty) return;

    final del = delegate();
    final focusedKey = activeId();
    final baseKey = focusedKey ?? del.getFirstKey();
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        final below = baseKey == null ? del.getFirstKey() : del.getKeyBelow(baseKey);
        if (below == null && shouldFocusWrap) {
          setActiveKey(del.getFirstKey());
        } else {
          setActiveKey(below);
        }
        return;
      case "ArrowUp":
        e.preventDefault();
        final above = baseKey == null ? del.getLastKey() : del.getKeyAbove(baseKey);
        if (above == null && shouldFocusWrap) {
          setActiveKey(del.getLastKey());
        } else {
          setActiveKey(above);
        }
        return;
      case "Home":
        e.preventDefault();
        setActiveKey(del.getFirstKey());
        return;
      case "End":
        e.preventDefault();
        setActiveKey(del.getLastKey());
        return;
      case "PageDown":
        e.preventDefault();
        if (baseKey != null) setActiveKey(del.getKeyPageBelow(baseKey));
        return;
      case "PageUp":
        e.preventDefault();
        if (baseKey != null) setActiveKey(del.getKeyPageAbove(baseKey));
        return;
      case "Enter":
        e.preventDefault();
        selectActive();
        return;
      case " ":
        if (!allowSpaceSelect) return;
        e.preventDefault();
        selectActive();
        return;
    }

    if (allowTypeAhead && !disallowTypeAhead) {
      final match = typeSelect.handleKey(
        e,
        currentKeys,
        startKey: focusedKey,
        isDisabled: (k) => optionsByKey[k]?.disabled ?? false,
        textValueForKey: (k) => optionsByKey[k]?.textValue ?? "",
      );
      if (match != null) {
        e.preventDefault();
        setActiveKey(match);
      }
    }
  }

  void onKeydown(web.Event e) {
    if (e is! web.KeyboardEvent) return;
    handleKeyDown(e);
  }

  on(listbox, "keydown", onKeydown);
  onCleanup(typeSelect.dispose);

  web.HTMLElement buildOption(O option, int idx, bool selected, bool active) {
    final el = optionBuilder != null
        ? optionBuilder(option, selected: selected, active: active)
        : (web.HTMLDivElement()
          ..className = "menuItem"
          ..textContent = option.label);

    el.setAttribute("role", "option");
    el.id = ids.idForOption(option);
    el.setAttribute("data-key", el.id);
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

    on(el, "click", (_) {
      if (option.disabled) return;
      activeIndexSig.value = idx;
      selectActive();
    });

    on(el, "pointermove", (ev) {
      if (!shouldFocusOnHover) return;
      if (option.disabled) return;
      if (ev is! web.PointerEvent) return;
      if (ev.pointerType != "mouse") return;

      final activeEl = web.document.activeElement;
      final shouldRefocus = !identical(activeEl, el);
      final shouldUpdateActive = activeIndexSig.value != idx;
      if (!shouldRefocus && !shouldUpdateActive) return;

      if (shouldUpdateActive) activeIndexSig.value = idx;
      syncTabIndex();
      if (shouldRefocus) focusActive();
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
    optionElByKey.clear();
    indexByKey.clear();
    optionsByKey.clear();
    currentKeys = <String>[];
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
          optionElByKey[el.id] = el;
          indexByKey[el.id] = flatIdx;
          optionsByKey[el.id] = opt;
          currentKeys.add(el.id);
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
        optionElByKey[el.id] = el;
        indexByKey[el.id] = i;
        optionsByKey[el.id] = opt;
        currentKeys.add(el.id);
        listbox.appendChild(el);
      }
    }

    scheduleMicrotask(() {
      syncTabIndex(force: true);
      scrollActiveIntoView();
      if (shouldRestoreFocus) focusActive();
    });
  });

  return ListboxHandle._(
    listbox,
    activeIndex: activeIndexSig,
    activeId: activeId,
    activeKey: activeKey,
    setActiveKey: setActiveKey,
    setActiveIndex: setActiveIndex,
    selectActive: selectActive,
    moveActive: moveActive,
    focusActive: focusActive,
    handleKeyDown: handleKeyDown,
  );
}

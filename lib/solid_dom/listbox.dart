import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./listbox_core.dart";
import "./selection/create_selectable_collection.dart";
import "./selection/create_selectable_item.dart";
import "./selection/list_keyboard_delegate.dart";
import "./selection/selection_manager.dart";
import "./selection/types.dart";
import "./selection/utils.dart";
import "./solid_dom.dart";

typedef ListboxOptionBuilder<T, O extends ListboxItem<T>> = web.HTMLElement
    Function(
  O option, {
  required bool selected,
  required bool active,
});

typedef ListboxOptionBuilderReactive<T, O extends ListboxItem<T>> =
    web.HTMLElement Function(
  O option, {
  required bool Function() selected,
  required bool Function() active,
});

final class ListboxHandle<T, O extends ListboxItem<T>> {
  ListboxHandle._(
    this.element, {
    required this.selectionManager,
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
  final SelectionManager selectionManager;

  /// Back-compat: derived from `activeKey`.
  final Signal<int> activeIndex;

  final String? Function() activeId;
  final String? Function() activeKey;
  final void Function(String? key) setActiveKey;
  final void Function(int next) setActiveIndex;
  final void Function() selectActive;
  final void Function(int delta) moveActive;
  final void Function() focusActive;

  /// Keyboard handler for external focus targets (e.g. Combobox input).
  final void Function(
    web.KeyboardEvent e, {
    bool allowTypeAhead,
    bool allowSpaceSelect,
  }) handleKeyDown;
}

final class _Entry<T, O extends ListboxItem<T>> {
  _Entry({
    required this.key,
    required this.option,
    required this.index,
    required this.sectionLabelId,
  });

  final String key;
  final O option;
  final int index;
  final String? sectionLabelId;
}

ListboxHandle<T, O> createListbox<T, O extends ListboxItem<T>>({
  required String id,
  List<O> Function()? options,
  Iterable<ListboxSection<T, O>> Function()? sections,
  required T? Function() selected,
  required void Function(O option, int index) onSelect,
  void Function()? onClearSelection,
  bool Function(T a, T b)? equals,
  Signal<int>? activeIndex,
  int Function()? initialActiveIndex,
  bool shouldUseVirtualFocus = false,
  bool shouldFocusOnHover = true,
  bool shouldFocusWrap = true,
  bool disallowTypeAhead = false,
  bool enableKeyboardNavigation = true,
  bool selectOnFocus = false,
  bool shouldSelectOnPressUp = false,
  bool allowsDifferentPressOrigin = false,
  bool disallowEmptySelection = false,
  void Function()? onTabOut,
  void Function()? onEscape,
  String emptyText = "No results.",
  bool showEmptyState = false,
  Object? Function(O option)? getOptionKey,
  ListboxIdRegistry<T, O>? idRegistry,
  web.HTMLElement? Function()? scrollContainer,
  bool useInnerScrollContainer = false,
  void Function(int index)? scrollToIndex,
  int Function()? pageSize,
  ListboxOptionBuilder<T, O>? optionBuilder,
  ListboxOptionBuilderReactive<T, O>? optionBuilderReactive,
}) {
  final eq = equals ?? defaultListboxEquals<T>;
  if (options == null && sections == null) {
    throw StateError("createListbox: provide options or sections");
  }

  final listbox = web.HTMLDivElement()
    ..id = id
    ..setAttribute("role", "listbox")
    ..tabIndex = -1
    ..className = "card listbox";

  final innerScroll = useInnerScrollContainer ? web.HTMLDivElement() : null;
  web.HTMLElement getScrollEl() =>
      scrollContainer?.call() ?? innerScroll ?? listbox;
  web.Element getRenderTarget() => innerScroll ?? listbox;

  if (innerScroll != null) {
    // Allow popper arrows to render outside the border.
    listbox.style.overflow = "visible";
    listbox.style.display = "flex";
    listbox.style.flexDirection = "column";

    innerScroll.className = "listboxScroll";
    innerScroll.style.flex = "1";
    innerScroll.style.minHeight = "0";
    innerScroll.style.overflow = "auto";
    listbox.appendChild(innerScroll);
  } else {
    listbox.style.overflow = "auto";
  }

  final ids = idRegistry ??
      ListboxIdRegistry<T, O>(listboxId: id, getOptionKey: getOptionKey);

  final hasExternalActiveIndex = activeIndex != null;
  final activeIndexSig = activeIndex ?? createSignal<int>(-1);

  final optionElByKey = <String, web.HTMLElement>{};
  final optionByKey = <String, O>{};
  final indexByKey = <String, int>{};
  var keys = <String>[];

  int keysVersion = 0;
  final keysVersionSig = createSignal<int>(0);

  final selection = SelectionManager(
    selectionMode: SelectionMode.single,
    selectionBehavior: SelectionBehavior.replace,
    disallowEmptySelection: disallowEmptySelection,
    orderedKeys: () => keys,
    isDisabled: (k) => optionByKey[k]?.disabled ?? false,
    canSelectItem: (k) => !(optionByKey[k]?.disabled ?? false),
  );

  final delegate = ListKeyboardDelegate(
    keys: () => keys,
    isDisabled: (k) => optionByKey[k]?.disabled ?? false,
    textValueForKey: (k) => optionByKey[k]?.textValue ?? "",
    getContainer: () => getScrollEl(),
    getItemElement: (k) => optionElByKey[k],
    pageSize: pageSize,
  );

  String? activeKey() => selection.focusedKey();
  String? activeId() => selection.focusedKey();

  int _indexForKey(String? key) => key == null ? -1 : (indexByKey[key] ?? -1);

  bool _syncingIndexFromKey = false;
  bool _syncingKeyFromIndex = false;

  void syncActiveIndexFromKey() {
    if (_syncingKeyFromIndex) return;
    final next = _indexForKey(activeKey());
    if (activeIndexSig.value != next) activeIndexSig.value = next;
  }

  void syncKeyFromActiveIndex() {
    if (_syncingIndexFromKey) return;
    final idx = activeIndexSig.value;
    if (idx < 0 || idx >= keys.length) return;
    final k = keys[idx];
    if (activeKey() == k) return;
    _syncingKeyFromIndex = true;
    selection.setFocusedKey(k);
    _syncingKeyFromIndex = false;
  }

  // Keep activeIndex and focusedKey in sync.
  if (hasExternalActiveIndex) {
    createEffect(() {
      final _ = activeIndexSig.value;
      syncKeyFromActiveIndex();
    });
  }
  createEffect(() {
    final _ = selection.focusedKey();
    _syncingIndexFromKey = true;
    syncActiveIndexFromKey();
    _syncingIndexFromKey = false;
  });

  void ensureFocusedKeyValid() {
    final current = selection.focusedKey();
    if (current != null && indexByKey.containsKey(current)) return;

    // Prefer selected key, then initial active index, then first enabled.
    final selectedValue = selected();
    String? preferred;
    if (selectedValue != null) {
      for (final opt in optionByKey.values) {
        if (eq(opt.value, selectedValue)) {
          preferred = ids.idForOption(opt);
          break;
        }
      }
    }
    preferred ??= () {
      final idx = initialActiveIndex?.call() ?? -1;
      if (idx >= 0 && idx < keys.length) return keys[idx];
      return null;
    }();
    preferred ??= delegate.getFirstKey();
    if (preferred != null) selection.setFocusedKey(preferred);
  }

  void focusActive() {
    if (shouldUseVirtualFocus) return;
    final k = selection.focusedKey();
    if (k == null) return;
    final el = optionElByKey[k];
    if (el == null) return;
    try {
      el.focus(web.FocusOptions(preventScroll: true));
    } catch (_) {}
  }

  void setActiveKey(String? key) {
    if (key == null) return;
    if (!indexByKey.containsKey(key)) return;
    selection.setFocusedKey(key);
    if (hasExternalActiveIndex) {
      final idx = indexByKey[key] ?? -1;
      _syncingIndexFromKey = true;
      if (activeIndexSig.value != idx) activeIndexSig.value = idx;
      _syncingIndexFromKey = false;
    }
    if (!shouldUseVirtualFocus) scheduleMicrotask(focusActive);
  }

  void setActiveIndex(int next) {
    if (keys.isEmpty) {
      activeIndexSig.value = -1;
      selection.setFocusedKey(null);
      return;
    }
    var idx = next;
    if (idx < 0) idx = 0;
    if (idx >= keys.length) idx = keys.length - 1;
    final k = keys[idx];
    setActiveKey(k);
  }

  void moveActive(int delta) {
    if (keys.isEmpty) return;

    final currentKey = selection.focusedKey();
    final currentIndex = currentKey == null ? -1 : (indexByKey[currentKey] ?? -1);

    String? nextEnabledFromIndex(int start, int direction) {
      if (keys.isEmpty) return null;
      var idx = start;
      for (var i = 0; i < keys.length; i++) {
        idx += direction;
        if (shouldFocusWrap) {
          idx = (idx + keys.length) % keys.length;
        } else {
          if (idx < 0 || idx >= keys.length) return null;
        }
        final k = keys[idx];
        if (!(optionByKey[k]?.disabled ?? false)) return k;
      }
      return null;
    }

    final direction = delta >= 0 ? 1 : -1;
    final start = currentIndex == -1 ? (direction > 0 ? -1 : keys.length) : currentIndex;
    final next = nextEnabledFromIndex(start, direction);
    if (next != null) setActiveKey(next);
  }

  void selectActive() {
    final k = selection.focusedKey();
    if (k == null) return;
    final opt = optionByKey[k];
    final idx = indexByKey[k];
    if (opt == null || idx == null) return;
    if (opt.disabled) return;
    final wasSelected = selection.isSelected(k);
    selection.select(k, shiftKey: false, toggleKey: false, isTouch: false);
    if (!selection.isSelected(k) && wasSelected) {
      onClearSelection?.call();
      return;
    }
    onSelect(opt, idx);
  }

  createEffect(() {
    final _ = keysVersionSig.value;
    final v = selected();
    if (v == null) {
      selection.clearSelection(force: true);
      return;
    }
    for (final opt in optionByKey.values) {
      if (eq(opt.value, v)) {
        selection.setSelectedKeys([ids.idForOption(opt)], force: true);
        return;
      }
    }
    selection.clearSelection(force: true);
  });

  // Keep aria-activedescendant available in virtual focus mode.
  if (shouldUseVirtualFocus) {
    attr(listbox, "aria-activedescendant", () => selection.focusedKey());
  }

  // Scroll active item into view when focusedKey changes (non-virtualized).
  createEffect(() {
    final scrollEl = getScrollEl();
    final focusedKey = selection.focusedKey();
    if (focusedKey == null) return;
    final el = optionElByKey[focusedKey];
    if (el == null) return;
    if (scrollToIndex != null) {
      final idx = indexByKey[focusedKey];
      if (idx != null) scrollToIndex(idx);
      return;
    }
    try {
      final cRect = scrollEl.getBoundingClientRect();
      final eRect = el.getBoundingClientRect();
      final viewTop = scrollEl.scrollTop;
      final viewBottom = viewTop + cRect.height;
      final elTop = (eRect.top - cRect.top) + viewTop;
      final elBottom = elTop + eRect.height;
      if (elTop < viewTop) {
        scrollEl.scrollTop = elTop;
      } else if (elBottom > viewBottom) {
        scrollEl.scrollTop = elBottom - cRect.height;
      }
    } catch (_) {
      try {
        el.scrollIntoView();
      } catch (_) {}
    }
  });

  // Build/rebuild DOM when the options/sections structure changes.
  final disposers = <Dispose>[];
  void disposeItems() {
    for (final d in disposers) {
      try {
        d();
      } catch (_) {}
    }
    disposers.clear();
  }

  List<_Entry<T, O>> computeEntries() {
    final out = <_Entry<T, O>>[];
    if (sections != null) {
      var flatIdx = 0;
      var sectionIdx = 0;
      for (final section in sections()) {
        final labelId = section.id != null
            ? "$id-section-${section.id}-label"
            : "$id-section-$sectionIdx-label";
        for (final opt in section.options) {
          out.add(
            _Entry(
              key: ids.idForOption(opt),
              option: opt,
              index: flatIdx,
              sectionLabelId: labelId,
            ),
          );
          flatIdx++;
        }
        sectionIdx++;
      }
      return out;
    }

    final opts = options!();
    for (var i = 0; i < opts.length; i++) {
      final opt = opts[i];
      out.add(_Entry(key: ids.idForOption(opt), option: opt, index: i, sectionLabelId: null));
    }
    return out;
  }

  var didBuildOnce = false;

  createEffect(() {
    final entries = computeEntries();
    final nextKeys = entries.map((e) => e.key).toList(growable: false);
    final same = nextKeys.length == keys.length &&
        (() {
          for (var i = 0; i < nextKeys.length; i++) {
            if (nextKeys[i] != keys[i]) return false;
          }
          return true;
        })();

    if (same && didBuildOnce) return;
    didBuildOnce = true;

    disposeItems();

    getRenderTarget().textContent = "";
    optionElByKey.clear();
    optionByKey.clear();
    indexByKey.clear();
    keys = nextKeys.toList(growable: true);

    // Rebuild groups/sections if needed.
    if (sections != null) {
      var sectionIdx = 0;
      for (final section in sections()) {
        final labelId = section.id != null
            ? "$id-section-${section.id}-label"
            : "$id-section-$sectionIdx-label";
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
          final key = ids.idForOption(opt);
          final idx = indexByKey.length;
          final el = optionBuilderReactive != null
              ? optionBuilderReactive(
                  opt,
                  selected: () => selection.isSelected(key),
                  active: () => selection.focusedKey() == key,
                )
              : optionBuilder != null
                  ? optionBuilder(
                      opt,
                      selected: selection.isSelected(key),
                      active: selection.focusedKey() == key,
                    )
              : (web.HTMLDivElement()
                ..className = "menuItem"
                ..textContent = opt.label);
          el.setAttribute("role", "option");
          el.id = key;
          if (opt.disabled) el.setAttribute("aria-disabled", "true");
          optionElByKey[key] = el;
          optionByKey[key] = opt;
          indexByKey[key] = idx;

          createChildRoot<void>((dispose) {
            disposers.add(dispose);
            final selectableItem = createSelectableItem(
              selectionManager: () => selection,
              key: () => key,
              ref: () => el,
              disabled: () => opt.disabled,
              shouldSelectOnPressUp: () => shouldSelectOnPressUp,
              shouldUseVirtualFocus: () => shouldUseVirtualFocus,
              allowsDifferentPressOrigin: () => allowsDifferentPressOrigin,
              onAction: () => onSelect(opt, idx),
            );
            selectableItem.attach(el);

            createRenderEffect(() {
              el.setAttribute(
                "aria-selected",
                selection.isSelected(key) ? "true" : "false",
              );
              if (selection.focusedKey() == key) {
                el.setAttribute("data-active", "true");
              } else {
                el.removeAttribute("data-active");
              }
            });
          });

          group.appendChild(el);
        }

        getRenderTarget().appendChild(group);
        sectionIdx++;
      }
    } else {
      for (final entry in entries) {
        final opt = entry.option;
        final key = entry.key;
        final idx = entry.index;
        final el = optionBuilderReactive != null
            ? optionBuilderReactive(
                opt,
                selected: () => selection.isSelected(key),
                active: () => selection.focusedKey() == key,
              )
            : optionBuilder != null
                ? optionBuilder(
                    opt,
                    selected: selection.isSelected(key),
                    active: selection.focusedKey() == key,
                  )
            : (web.HTMLDivElement()
              ..className = "menuItem"
              ..textContent = opt.label);

        el.setAttribute("role", "option");
        el.id = key;
        if (opt.disabled) el.setAttribute("aria-disabled", "true");

        optionElByKey[key] = el;
        optionByKey[key] = opt;
        indexByKey[key] = idx;

        createChildRoot<void>((dispose) {
          disposers.add(dispose);
          final selectableItem = createSelectableItem(
            selectionManager: () => selection,
            key: () => key,
            ref: () => el,
            disabled: () => opt.disabled,
            shouldSelectOnPressUp: () => shouldSelectOnPressUp,
            shouldUseVirtualFocus: () => shouldUseVirtualFocus,
            allowsDifferentPressOrigin: () => allowsDifferentPressOrigin,
            onAction: () {
              if (selection.isSelected(key)) {
                onSelect(opt, idx);
              } else {
                onClearSelection?.call();
              }
            },
          );
          selectableItem.attach(el);

          createRenderEffect(() {
            el.setAttribute(
              "aria-selected",
              selection.isSelected(key) ? "true" : "false",
            );
            if (selection.focusedKey() == key) {
              el.setAttribute("data-active", "true");
            } else {
              el.removeAttribute("data-active");
            }
          });
        });

        getRenderTarget().appendChild(el);
      }
    }

    keysVersion++;
    keysVersionSig.value = keysVersion;

    if (keys.isEmpty) {
      activeIndexSig.value = -1;
      selection.setFocusedKey(null);
      selection.clearSelection(force: true);
      if (showEmptyState) {
        final empty = web.HTMLDivElement()
          ..setAttribute("data-empty", "1")
          ..textContent = emptyText;
        empty.style.padding = "10px 12px";
        empty.style.opacity = "0.8";
        getRenderTarget().appendChild(empty);
      }
      return;
    }

    ensureFocusedKeyValid();
    syncActiveIndexFromKey();
  });

  // Keyboard handling (listbox focused).
  final selectableCollection = createSelectableCollection(
    selectionManager: () => selection,
    keyboardDelegate: () => delegate,
    ref: () => listbox,
    scrollRef: () => getScrollEl(),
    shouldFocusWrap: () => shouldFocusWrap,
    selectOnFocus: () => selectOnFocus,
    disallowTypeAhead: () => disallowTypeAhead,
    shouldUseVirtualFocus: () => shouldUseVirtualFocus,
    allowsTabNavigation: () => true,
    orientation: () => Orientation.vertical,
  );

  // Bind tabIndex (virtual focus omits the attribute).
  createRenderEffect(() {
    final ti = selectableCollection.tabIndex();
    if (ti == null) {
      listbox.removeAttribute("tabindex");
    } else {
      listbox.tabIndex = ti;
    }
  });

  void handleKeyDown(
    web.KeyboardEvent e, {
    bool allowTypeAhead = true,
    bool allowSpaceSelect = true,
  }) {
    if (e.defaultPrevented) return;

    if (e.key == "Tab") {
      onTabOut?.call();
      return;
    }
    if (e.key == "Escape") {
      e.preventDefault();
      onEscape?.call();
      return;
    }

    // Only handle selection keys at the container level in virtual focus mode.
    // In real focus mode, let the focused option handle Enter/Space so we don't
    // double-trigger (item keydown + container keydown).
    if (shouldUseVirtualFocus && (e.key == "Enter" || e.key == " ")) {
      if (e.key == " " && !allowSpaceSelect) return;
      e.preventDefault();
      selectActive();
      return;
    }
  }

  void onKeydown(web.Event e) {
    if (e is! web.KeyboardEvent) return;
    if (!enableKeyboardNavigation) return;
    handleKeyDown(e);
    if (e.defaultPrevented) return;
    selectableCollection.onKeyDownWithOptions(
      e,
      allowTypeAhead: !disallowTypeAhead,
      bypassTargetCheck: false,
    );
  }

  if (enableKeyboardNavigation) {
    on(listbox, "keydown", onKeydown);
  }

  void maybeFocusFromHoverTarget(web.Event e) {
    if (!shouldFocusOnHover) return;
    final t = e.target;
    if (t is! web.Element) return;
    final optionEl = t.closest('[role="option"]');
    if (optionEl == null) return;
    if (!listbox.contains(optionEl)) return;
    final key = optionEl.getAttribute("data-key") ?? optionEl.id;
    if (key.isEmpty) return;
    final opt = optionByKey[key];
    if (opt == null || opt.disabled) return;
    if (selection.focusedKey() == key) return;
    selection.setFocusedKey(key);
    if (!shouldUseVirtualFocus && optionEl is web.HTMLElement) {
      try {
        optionEl.focus(web.FocusOptions(preventScroll: true));
      } catch (_) {}
    }
  }

  on(listbox, "pointermove", (e) {
    if (e is! web.PointerEvent) return;
    if (e.pointerType != "mouse") return;
    if (e.buttons != 0) return;
    maybeFocusFromHoverTarget(e);
  });
  on(listbox, "mousemove", maybeFocusFromHoverTarget);

  on(listbox, "mousedown", (e) {
    if (e is web.MouseEvent) selectableCollection.onMouseDown(e);
  });
  on(listbox, "focusin", (e) {
    if (e is web.FocusEvent) selectableCollection.onFocusIn(e);
  });
  on(listbox, "focusout", (e) {
    if (e is web.FocusEvent) selectableCollection.onFocusOut(e);
  });

  onCleanup(disposeItems);

  return ListboxHandle._(
    listbox,
    selectionManager: selection,
    activeIndex: activeIndexSig,
    activeId: activeId,
    activeKey: activeKey,
    setActiveKey: setActiveKey,
    setActiveIndex: setActiveIndex,
    selectActive: selectActive,
    moveActive: moveActive,
    focusActive: focusActive,
    handleKeyDown: (e, {allowTypeAhead = true, allowSpaceSelect = true}) {
      // External focus targets: only handle keys we care about.
      if (e.key == "Tab") {
        onTabOut?.call();
        return;
      }
      if (e.key == "Escape") {
        e.preventDefault();
        onEscape?.call();
        return;
      }

      if (e.key == "Enter" || e.key == " ") {
        if (e.key == " " && !allowSpaceSelect) return;
        e.preventDefault();
        selectActive();
        return;
      }

      // If the external key target is an input (e.g. combobox), don't steal
      // printable characters unless typeahead is explicitly enabled.
      if (!allowTypeAhead &&
          e.key.length == 1 &&
          !e.ctrlKey &&
          !e.metaKey &&
          !e.altKey) {
        return;
      }

      selectableCollection.onKeyDownWithOptions(
        e,
        allowTypeAhead: allowTypeAhead && !disallowTypeAhead,
        bypassTargetCheck: true,
      );
    },
  );
}

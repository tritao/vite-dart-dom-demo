import "dart:async";
import "dart:js_util" as js_util;

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./focus_scope.dart";
import "./overlay.dart";
import "./popper.dart";
import "./presence.dart";
import "./selection/create_selectable_collection.dart";
import "./selection/create_selectable_item.dart";
import "./selection/list_keyboard_delegate.dart";
import "./selection/selection_manager.dart";
import "./selection/types.dart";
import "./selection/utils.dart";
import "./solid_dom.dart";

enum MenuItemKind {
  item,
  checkbox,
  radio,
  subTrigger,
}

final class MenuCloseController {
  MenuCloseController._(this._close, this._closeAll);
  final void Function([String reason]) _close;
  final void Function([String reason]) _closeAll;

  void close([String reason = "close"]) => _close(reason);
  void closeAll([String reason = "close"]) => _closeAll(reason);
}

final class MenuItem {
  MenuItem({
    required this.element,
    required this.key,
    this.kind = MenuItemKind.item,
    this.disabled,
    this.textValue,
    this.closeOnSelect,
    this.onSelect,
    this.checked,
    this.indeterminate,
    this.submenuBuilder,
  });

  final web.HTMLElement element;
  final String key;
  final MenuItemKind kind;

  /// When omitted, falls back to the element's own disabled state.
  final bool Function()? disabled;

  /// Optional text for typeahead. Defaults to the element's textContent.
  final String Function()? textValue;

  /// Default follows Kobalte:
  /// - regular items: close
  /// - checkbox/radio: do not close
  final bool? closeOnSelect;

  /// Called on selection (pointer up / Enter / Space).
  final void Function()? onSelect;

  /// For checkbox/radio items.
  final bool Function()? checked;
  final bool Function()? indeterminate;

  /// For submenu triggers.
  final DropdownMenuBuilder? submenuBuilder;
}

final class MenuContent {
  MenuContent({
    required this.element,
    required this.items,
    this.initialActiveIndex = 0,
  });

  final web.HTMLElement element;
  final List<MenuItem> items;
  final int initialActiveIndex;
}

typedef DropdownMenuBuilder = MenuContent Function(MenuCloseController close);

typedef _Polygon = List<({double x, double y})>;

double _pointerClientX(web.PointerEvent e) {
  try {
    final v = js_util.getProperty(e, "clientX");
    return (v as num).toDouble();
  } catch (_) {
    return 0;
  }
}

double _pointerClientY(web.PointerEvent e) {
  try {
    final v = js_util.getProperty(e, "clientY");
    return (v as num).toDouble();
  } catch (_) {
    return 0;
  }
}

bool _isPointInPolygon(double x, double y, _Polygon polygon) {
  if (polygon.isEmpty) return false;

  bool pointOnSegment(
    double ax,
    double ay,
    double bx,
    double by,
    double px,
    double py,
  ) {
    const eps = 1e-6;
    final cross = (px - ax) * (by - ay) - (py - ay) * (bx - ax);
    if (cross.abs() > eps) return false;
    final dot = (px - ax) * (bx - ax) + (py - ay) * (by - ay);
    if (dot < -eps) return false;
    final lenSq = (bx - ax) * (bx - ax) + (by - ay) * (by - ay);
    if (dot - lenSq > eps) return false;
    return true;
  }

  // Treat points on the boundary as "inside" for more stable submenu grace
  // behavior (mirrors @kobalte/utils polygon semantics).
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    if (pointOnSegment(a.x, a.y, b.x, b.y, x, y)) return true;
  }

  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].x;
    final yi = polygon[i].y;
    final xj = polygon[j].x;
    final yj = polygon[j].y;
    final denom = (yj - yi) == 0 ? 1e-9 : (yj - yi);
    final intersect =
        ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / denom + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

_Polygon _getPointerGraceArea({
  required String placement,
  required web.PointerEvent event,
  required web.Element contentEl,
}) {
  final basePlacement = placement.split("-").first;
  final rect = contentEl.getBoundingClientRect();
  final px = _pointerClientX(event);
  final py = _pointerClientY(event);
  final poly = <({double x, double y})>[];

  switch (basePlacement) {
    case "top":
      poly.add((x: px, y: py + 5));
      poly.add((x: rect.left, y: rect.bottom));
      poly.add((x: rect.left, y: rect.top));
      poly.add((x: rect.right, y: rect.top));
      poly.add((x: rect.right, y: rect.bottom));
      break;
    case "right":
      poly.add((x: px - 5, y: py));
      poly.add((x: rect.left, y: rect.top));
      poly.add((x: rect.right, y: rect.top));
      poly.add((x: rect.right, y: rect.bottom));
      poly.add((x: rect.left, y: rect.bottom));
      break;
    case "bottom":
      poly.add((x: px, y: py - 5));
      poly.add((x: rect.right, y: rect.top));
      poly.add((x: rect.right, y: rect.bottom));
      poly.add((x: rect.left, y: rect.bottom));
      poly.add((x: rect.left, y: rect.top));
      break;
    case "left":
      poly.add((x: px + 5, y: py));
      poly.add((x: rect.right, y: rect.bottom));
      poly.add((x: rect.left, y: rect.bottom));
      poly.add((x: rect.left, y: rect.top));
      poly.add((x: rect.right, y: rect.top));
      break;
  }
  return poly;
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

bool _defaultCloseOnSelect(MenuItemKind kind) {
  switch (kind) {
    case MenuItemKind.checkbox:
    case MenuItemKind.radio:
      return false;
    case MenuItemKind.item:
    case MenuItemKind.subTrigger:
      return true;
  }
}

bool _isElementDisabled(web.HTMLElement el) {
  if (el is web.HTMLButtonElement) return el.disabled;
  if (el is web.HTMLInputElement) return el.disabled;
  if (el is web.HTMLSelectElement) return el.disabled;
  if (el is web.HTMLTextAreaElement) return el.disabled;
  return el.getAttribute("aria-disabled") == "true";
}

final class _GraceIntent {
  _GraceIntent({required this.area, required this.side});
  final _Polygon area;
  final String side; // "left" | "right"
}

final class _MenuController {
  _MenuController({
    required this.menu,
    required this.items,
    required this.selection,
    required this.delegate,
    required this.selectable,
    required this.close,
    required this.closeAll,
    required this.anchor,
    required this.modal,
    required this.isSubmenu,
    required this.parent,
  });

  final web.HTMLElement menu;
  final List<MenuItem> items;
  final SelectionManager selection;
  final ListKeyboardDelegate delegate;
  final SelectableCollectionResult selectable;
  final void Function([String reason]) close;
  final void Function([String reason]) closeAll;
  final web.Element anchor;
  final bool modal;
  final bool isSubmenu;
  final _MenuController? parent;

  double lastPointerX = 0;
  String pointerDir = "right";
  _GraceIntent? pointerGraceIntent;
  Timer? pointerGraceTimer;

  void setPointerGraceIntent(_GraceIntent? intent) {
    pointerGraceIntent = intent;
  }

  void clearPointerGraceLater() {
    pointerGraceTimer?.cancel();
    pointerGraceTimer = Timer(const Duration(milliseconds: 300), () {
      pointerGraceIntent = null;
    });
  }

  bool _isPointerMovingToSubmenu(web.PointerEvent e) {
    final intent = pointerGraceIntent;
    if (intent == null) return false;
    if (pointerDir != intent.side) return false;
    return _isPointInPolygon(
      _pointerClientX(e),
      _pointerClientY(e),
      intent.area,
    );
  }

  void onItemEnter(web.PointerEvent e) {
    if (_isPointerMovingToSubmenu(e)) {
      e.preventDefault();
    }
  }

  void focusContent() {
    focusWithoutScrolling(menu);
    selection.setFocused(true);
    selection.setFocusedKey(null);
  }

  void onItemLeave(web.PointerEvent e) {
    if (_isPointerMovingToSubmenu(e)) return;
    focusContent();
  }

  void onTriggerLeave(web.PointerEvent e) {
    if (_isPointerMovingToSubmenu(e)) {
      e.preventDefault();
    }
  }
}

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
  bool modal = false,
  String? portalId,
}) {
  return Presence(
    when: open,
    exitMs: exitMs,
    children: () => Portal(
      id: portalId,
      children: () {
        var closeReason = "close";

        final rootWrapper = web.HTMLDivElement()
          ..setAttribute("data-solid-menu-wrapper", "1");

        void closeRoot([String reason = "close"]) {
          closeReason = reason;
          onClose?.call(reason);
          setOpen(false);
        }

        final closeCtrl = MenuCloseController._(
          ([String reason = "close"]) => closeRoot(reason),
          ([String reason = "close"]) => closeRoot(reason),
        );

        final built = builder(closeCtrl);
        final menu = built.element;
        final items = built.items;

        menu
          ..setAttribute("role", "menu")
          ..tabIndex = -1;

        if (modal) {
          ariaHideOthers(rootWrapper);
        }

        final keys = <String>[];
        final itemByKey = <String, MenuItem>{};
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          final el = item.element;
          var key = item.key;
          if (key.isEmpty) {
            key = el.id;
          } else {
            if (el.id.isEmpty) el.id = key;
          }
          if (key.isEmpty) {
            key = "solid-menu-item-$i";
            el.id = key;
          }
          keys.add(key);
          itemByKey[key] = item;
        }

        bool isItemDisabled(String k) {
          final item = itemByKey[k];
          if (item == null) return true;
          final el = item.element;
          return (item.disabled?.call() ?? false) || _isElementDisabled(el);
        }

        String itemTextValue(String k) {
          final item = itemByKey[k];
          if (item == null) return "";
          return item.textValue?.call() ?? (item.element.textContent ?? "");
        }

        final selection = SelectionManager(
          selectionMode: SelectionMode.none,
          selectionBehavior: SelectionBehavior.replace,
          orderedKeys: () => keys,
          isDisabled: isItemDisabled,
          canSelectItem: (k) => !isItemDisabled(k),
        );

        final initialIndex = built.initialActiveIndex
            .clamp(0, keys.isEmpty ? 0 : keys.length - 1);
        if (keys.isNotEmpty) {
          for (var i = 0; i < keys.length; i++) {
            final idx = (initialIndex + i) % keys.length;
            final k = keys[idx];
            if (!isItemDisabled(k)) {
              selection.setFocusedKey(k);
              break;
            }
          }
        }

        final delegate = ListKeyboardDelegate(
          keys: () => keys,
          isDisabled: isItemDisabled,
          textValueForKey: itemTextValue,
          getContainer: () => menu,
          getItemElement: (k) => itemByKey[k]?.element,
        );

        final selectable = createSelectableCollection(
          selectionManager: () => selection,
          keyboardDelegate: () => delegate,
          ref: () => menu,
          scrollRef: () => menu,
          shouldFocusWrap: () => true,
          disallowTypeAhead: () => !selection.isFocused(),
          shouldUseVirtualFocus: () => false,
          allowsTabNavigation: () => false,
          orientation: () => Orientation.vertical,
        );

        final rootController = _MenuController(
          menu: menu,
          items: items,
          selection: selection,
          delegate: delegate,
          selectable: selectable,
          close: ([String reason = "close"]) => closeRoot(reason),
          closeAll: ([String reason = "close"]) => closeRoot(reason),
          anchor: anchor,
          modal: modal,
          isSubmenu: false,
          parent: null,
        );

        attachPopper(
          anchor: anchor,
          floating: menu,
          placement: placement,
          offset: offset,
          viewportPadding: viewportPadding,
          flip: flip,
          updateOnScrollParents: true,
        );

        // Root menu: match Kobalte's dismissable-layer behavior:
        // - anchor excluded
        // - allow parents to see outside interactions even if a submenu is open
        // - optionally disable outside pointer events when modal
        dismissableLayer(
          menu,
          excludedElements: <web.Element? Function()>[
            () => anchor,
          ],
          onDismiss: (reason) => closeRoot(reason),
          disableOutsidePointerEvents: modal,
          bypassTopMostLayerCheck: true,
          preventClickThrough: true,
        );

        // Track pointer direction for safe-polygon behavior.
        void onMenuPointerMove(web.Event e) {
          if (e is! web.PointerEvent) return;
          if (e.pointerType != "mouse") return;
          final target = e.target;
          if (target is! web.Element) return;
          if (!menu.contains(target)) return;
          final dx = _pointerClientX(e) - rootController.lastPointerX;
          if (dx.abs() <= 0.0) return;
          rootController.pointerDir = dx > 0 ? "right" : "left";
          rootController.lastPointerX = _pointerClientX(e);
        }

        on(menu, "pointermove", onMenuPointerMove);

        final submenuFragments = <Object?>[];

        void wireItem(MenuItem item) {
          final key = item.key;
          final el = item.element;

          // Ensure the element is identifiable for focus and typeahead.
          if (el.id.isEmpty) el.id = key;

          switch (item.kind) {
            case MenuItemKind.checkbox:
              el.setAttribute("role", "menuitemcheckbox");
              createRenderEffect(() {
                final mixed = item.indeterminate?.call() ?? false;
                final checked = item.checked?.call() ?? false;
                el.setAttribute("aria-checked", mixed ? "mixed" : (checked ? "true" : "false"));
              });
              break;
            case MenuItemKind.radio:
              el.setAttribute("role", "menuitemradio");
              createRenderEffect(() {
                final checked = item.checked?.call() ?? false;
                el.setAttribute("aria-checked", checked ? "true" : "false");
              });
              break;
            case MenuItemKind.subTrigger:
              el.setAttribute("role", "menuitem");
              el.setAttribute("aria-haspopup", "true");
              break;
            case MenuItemKind.item:
              el.setAttribute("role", "menuitem");
              break;
          }

          final itemSelectable = createSelectableItem(
            selectionManager: () => selection,
            key: () => key,
            ref: () => el,
            disabled: () => isItemDisabled(key),
            shouldSelectOnPressUp: () => true,
            allowsDifferentPressOrigin: () => true,
          );
          itemSelectable.attach(el);

          createRenderEffect(() {
            if (selection.focusedKey() == key) {
              el.setAttribute("data-active", "true");
            } else {
              el.removeAttribute("data-active");
            }
          });

          createRenderEffect(() {
            if (isItemDisabled(key)) {
              el.setAttribute("aria-disabled", "true");
            } else {
              el.removeAttribute("aria-disabled");
            }
          });

          void runSelect() {
            item.onSelect?.call();
            final shouldClose = item.closeOnSelect ?? _defaultCloseOnSelect(item.kind);
            if (shouldClose) {
              Timer(const Duration(milliseconds: 1), () => closeRoot("select"));
            }
          }

          void onPointerMove(web.Event ev) {
            if (ev is! web.PointerEvent) return;
            if (ev.pointerType != "mouse") return;
            if (isItemDisabled(key)) {
              rootController.onItemLeave(ev);
              return;
            }
            rootController.onItemEnter(ev);
            if (ev.defaultPrevented) return;
            if (selection.focusedKey() == key && web.document.activeElement == el) return;
            focusWithoutScrolling(el);
            selection.setFocused(true);
            selection.setFocusedKey(key);
          }

          void onPointerLeave(web.Event ev) {
            if (ev is! web.PointerEvent) return;
            if (ev.pointerType != "mouse") return;
            rootController.onItemLeave(ev);
          }

          void onPointerUp(web.Event ev) {
            if (ev is! web.PointerEvent) return;
            if (isItemDisabled(key)) return;
            if (ev.button != 0) return;
            if (item.kind == MenuItemKind.subTrigger) return;
            runSelect();
          }

          void onKeyDown(web.Event ev) {
            if (ev is! web.KeyboardEvent) return;
            if (ev.repeat) return;
            if (isItemDisabled(key)) return;
            if (ev.key != "Enter" && ev.key != " ") return;
            if (item.kind == MenuItemKind.subTrigger) return;
            runSelect();
          }

          if (item.kind != MenuItemKind.subTrigger) {
            on(el, "pointermove", onPointerMove);
          }
          if (item.kind != MenuItemKind.subTrigger) {
            on(el, "pointerleave", onPointerLeave);
            on(el, "pointerup", onPointerUp);
            on(el, "keydown", onKeyDown);
          }

          // Submenu trigger.
          if (item.kind == MenuItemKind.subTrigger && item.submenuBuilder != null) {
            final submenuOpen = createSignal(false);
            web.HTMLElement? submenuContent;
            _MenuController? submenuController;
            Timer? openTimer;

            void closeSub([String reason = "close"]) {
              submenuOpen.value = false;
            }

            void clearOpenTimer() {
              openTimer?.cancel();
              openTimer = null;
            }

            void openSub({required bool focusFirst}) {
              submenuOpen.value = true;
              if (!focusFirst) return;

              void focusWhenReady() {
                final content = submenuContent;
                final controller = submenuController;
                if (content == null || controller == null || !content.isConnected) {
                  scheduleMicrotask(focusWhenReady);
                  return;
                }

                focusWithoutScrolling(content);
                controller.selection.setFocused(true);
                final ks = controller.delegate.keys();
                String? first;
                for (final k in ks) {
                  if (!controller.selection.isDisabled(k)) {
                    first = k;
                    break;
                  }
                }
                controller.selection.setFocusedKey(first);
              }

              scheduleMicrotask(focusWhenReady);
            }

            void onSubPointerMove(web.Event ev) {
              if (ev is! web.PointerEvent) return;
              if (ev.pointerType != "mouse") return;
              rootController.onItemEnter(ev);
              if (ev.defaultPrevented) return;
              if (isItemDisabled(key)) {
                rootController.onItemLeave(ev);
                return;
              }

              // Keep visual focus on parent while hovering the trigger.
              final sub = submenuController;
              if (sub != null) {
                sub.selection.setFocused(false);
                sub.selection.setFocusedKey(null);
              }

              focusWithoutScrolling(el);
              selection.setFocused(true);
              selection.setFocusedKey(key);

              if (!submenuOpen.value && openTimer == null) {
                rootController.setPointerGraceIntent(null);
                openTimer = Timer(const Duration(milliseconds: 100), () {
                  openTimer = null;
                  openSub(focusFirst: false);
                });
              }
            }

            void onSubPointerLeave(web.Event ev) {
              if (ev is! web.PointerEvent) return;
              if (ev.pointerType != "mouse") return;
              clearOpenTimer();

              // Update pointer direction from this leave event. In practice, we
              // can miss a final `pointermove` while the pointer crosses the
              // gap between trigger and submenu; this keeps the safe-polygon
              // check stable (Kobalte-equivalent behavior).
              final leaveX = _pointerClientX(ev);
              final dx = leaveX - rootController.lastPointerX;
              if (dx.abs() > 0.0) {
                rootController.pointerDir = dx > 0 ? "right" : "left";
              }
              rootController.lastPointerX = leaveX;

              final contentEl = submenuContent;
              if (contentEl != null) {
                // If the popper hasn't computed its first position yet, the
                // bounding rect can be off-screen (we mount pending off-screen
                // to avoid first-frame flicker). Treat this transition as a
                // "grace" move and avoid stealing focus back to the parent.
                if (contentEl.getAttribute("data-solid-popper-pending") != null) {
                  rootController.setPointerGraceIntent(null);
                  rootController.clearPointerGraceLater();
                  return;
                }
                final place = contentEl.getAttribute("data-solid-placement") ??
                    (_documentDirection() == "rtl" ? "left-start" : "right-start");
                rootController.setPointerGraceIntent(
                  _GraceIntent(
                    area: _getPointerGraceArea(
                      placement: place,
                      event: ev,
                      contentEl: contentEl,
                    ),
                    side: place.split("-").first,
                  ),
                );
                rootController.clearPointerGraceLater();
              } else {
                rootController.onTriggerLeave(ev);
                if (ev.defaultPrevented) return;
                rootController.setPointerGraceIntent(null);
              }

              rootController.onItemLeave(ev);
            }

            void onSubClick(web.Event ev) {
              if (ev is! web.MouseEvent) return;
              if (isItemDisabled(key)) return;
              if (!submenuOpen.value) openSub(focusFirst: false);
            }

            void onSubKeyDown(web.Event ev) {
              if (ev is! web.KeyboardEvent) return;
              if (ev.repeat) return;
              if (isItemDisabled(key)) return;

              final dir = _documentDirection();
              final openKey = dir == "rtl" ? "ArrowLeft" : "ArrowRight";
              final openKeys = <String>{"Enter", " ", openKey};
              if (!openKeys.contains(ev.key)) return;

              ev.stopPropagation();
              ev.preventDefault();

              // Clear focus on parent menu content.
              selection.setFocused(false);
              selection.setFocusedKey(null);

              openSub(focusFirst: true);
            }

            on(el, "pointermove", onSubPointerMove);
            on(el, "pointerleave", onSubPointerLeave);
            on(el, "click", onSubClick);
            on(el, "keydown", onSubKeyDown);

            submenuFragments.add(
              Presence(
                when: () => submenuOpen.value,
                exitMs: exitMs,
                children: () {
                  final subClose = MenuCloseController._(
                    ([String reason = "close"]) => closeSub(reason),
                    ([String reason = "close"]) => closeRoot(reason),
                  );
                  final builtSub = item.submenuBuilder!(subClose);
                  final subMenu = builtSub.element;
                  submenuContent = subMenu;

                  subMenu
                    ..setAttribute("role", "menu")
                    ..tabIndex = -1;

                  final subKeys = <String>[];
                  final subItemByKey = <String, MenuItem>{};
                  for (var i = 0; i < builtSub.items.length; i++) {
                    final it = builtSub.items[i];
                    final itEl = it.element;
                    var itKey = it.key;
                    if (itKey.isEmpty) itKey = itEl.id;
                    if (itKey.isEmpty) {
                      itKey = "solid-submenu-item-$i";
                      itEl.id = itKey;
                    } else {
                      if (itEl.id.isEmpty) itEl.id = itKey;
                    }
                    subKeys.add(itKey);
                    subItemByKey[itKey] = it;
                  }

                  bool subDisabled(String k) {
                    final it = subItemByKey[k];
                    if (it == null) return true;
                    return (it.disabled?.call() ?? false) || _isElementDisabled(it.element);
                  }

                  String subText(String k) {
                    final it = subItemByKey[k];
                    if (it == null) return "";
                    return it.textValue?.call() ?? (it.element.textContent ?? "");
                  }

                  final subSelection = SelectionManager(
                    selectionMode: SelectionMode.none,
                    selectionBehavior: SelectionBehavior.replace,
                    orderedKeys: () => subKeys,
                    isDisabled: subDisabled,
                    canSelectItem: (k) => !subDisabled(k),
                  );

                  final subDelegate = ListKeyboardDelegate(
                    keys: () => subKeys,
                    isDisabled: subDisabled,
                    textValueForKey: subText,
                    getContainer: () => subMenu,
                    getItemElement: (k) => subItemByKey[k]?.element,
                  );

                  final subSelectable = createSelectableCollection(
                    selectionManager: () => subSelection,
                    keyboardDelegate: () => subDelegate,
                    ref: () => subMenu,
                    scrollRef: () => subMenu,
                    shouldFocusWrap: () => true,
                    disallowTypeAhead: () => !subSelection.isFocused(),
                    shouldUseVirtualFocus: () => false,
                    allowsTabNavigation: () => false,
                    orientation: () => Orientation.vertical,
                  );

                  submenuController = _MenuController(
                    menu: subMenu,
                    items: builtSub.items,
                    selection: subSelection,
                    delegate: subDelegate,
                    selectable: subSelectable,
                    close: ([String reason = "close"]) => closeSub(reason),
                    closeAll: ([String reason = "close"]) => closeRoot(reason),
                    anchor: el,
                    modal: false,
                    isSubmenu: true,
                    parent: rootController,
                  );

                  attachPopper(
                    anchor: el,
                    floating: subMenu,
                    placement: _documentDirection() == "rtl" ? "left-start" : "right-start",
                    offset: offset,
                    viewportPadding: viewportPadding,
                    flip: true,
                    updateOnScrollParents: true,
                  );

                  dismissableLayer(
                    subMenu,
                    excludedElements: <web.Element? Function()>[
                      () => el,
                    ],
                    onDismiss: (reason) => closeSub(reason),
                    bypassTopMostLayerCheck: true,
                    preventClickThrough: false,
                  );

                  on(subMenu, "pointerenter", (ev) {
                    if (ev is! web.PointerEvent) return;
                    if (ev.pointerType != "mouse") return;
                    selection.setFocused(false);
                    selection.setFocusedKey(null);
                  });

                  on(subMenu, "pointermove", (ev) {
                    if (ev is! web.PointerEvent) return;
                    if (ev.pointerType != "mouse") return;
                    final target = ev.target;
                    if (target is! web.Element) return;
                    if (!subMenu.contains(target)) return;
                    final dx = _pointerClientX(ev) - submenuController!.lastPointerX;
                    if (dx.abs() <= 0.0) return;
                    submenuController!.pointerDir = dx > 0 ? "right" : "left";
                    submenuController!.lastPointerX = _pointerClientX(ev);
                  });

                  void wireSubItem(MenuItem subItem) {
                    final subKey = subItem.key;
                    final subEl = subItem.element;

                    if (subEl.id.isEmpty) subEl.id = subKey;

                    switch (subItem.kind) {
                      case MenuItemKind.checkbox:
                        subEl.setAttribute("role", "menuitemcheckbox");
                        createRenderEffect(() {
                          final mixed = subItem.indeterminate?.call() ?? false;
                          final checked = subItem.checked?.call() ?? false;
                          subEl.setAttribute("aria-checked", mixed ? "mixed" : (checked ? "true" : "false"));
                        });
                        break;
                      case MenuItemKind.radio:
                        subEl.setAttribute("role", "menuitemradio");
                        createRenderEffect(() {
                          final checked = subItem.checked?.call() ?? false;
                          subEl.setAttribute("aria-checked", checked ? "true" : "false");
                        });
                        break;
                      case MenuItemKind.subTrigger:
                        subEl.setAttribute("role", "menuitem");
                        subEl.setAttribute("aria-haspopup", "true");
                        break;
                      case MenuItemKind.item:
                        subEl.setAttribute("role", "menuitem");
                        break;
                    }

                    final subSelectableItem = createSelectableItem(
                      selectionManager: () => subSelection,
                      key: () => subKey,
                      ref: () => subEl,
                      disabled: () => subDisabled(subKey),
                      shouldSelectOnPressUp: () => true,
                      allowsDifferentPressOrigin: () => true,
                    );
                    subSelectableItem.attach(subEl);

                    createRenderEffect(() {
                      if (subSelection.focusedKey() == subKey) {
                        subEl.setAttribute("data-active", "true");
                      } else {
                        subEl.removeAttribute("data-active");
                      }
                    });

                    createRenderEffect(() {
                      if (subDisabled(subKey)) {
                        subEl.setAttribute("aria-disabled", "true");
                      } else {
                        subEl.removeAttribute("aria-disabled");
                      }
                    });

                    void runSubSelect() {
                      subItem.onSelect?.call();
                      final shouldClose =
                          subItem.closeOnSelect ?? _defaultCloseOnSelect(subItem.kind);
                      if (shouldClose) {
                        Timer(const Duration(milliseconds: 1), () => closeRoot("select"));
                      }
                    }

                    on(subEl, "pointermove", (ev) {
                      if (ev is! web.PointerEvent) return;
                      if (ev.pointerType != "mouse") return;
                      if (subDisabled(subKey)) {
                        submenuController!.onItemLeave(ev);
                        return;
                      }
                      submenuController!.onItemEnter(ev);
                      if (ev.defaultPrevented) return;
                      focusWithoutScrolling(subEl);
                      subSelection.setFocused(true);
                      subSelection.setFocusedKey(subKey);
                    });
                    on(subEl, "pointerleave", (ev) {
                      if (ev is! web.PointerEvent) return;
                      if (ev.pointerType != "mouse") return;
                      submenuController!.onItemLeave(ev);
                    });
                    on(subEl, "pointerup", (ev) {
                      if (ev is! web.PointerEvent) return;
                      if (subDisabled(subKey)) return;
                      if (ev.button != 0) return;
                      if (subItem.kind == MenuItemKind.subTrigger) return;
                      runSubSelect();
                    });
                    on(subEl, "keydown", (ev) {
                      if (ev is! web.KeyboardEvent) return;
                      if (ev.repeat) return;
                      if (subDisabled(subKey)) return;
                      if (ev.key != "Enter" && ev.key != " ") return;
                      if (subItem.kind == MenuItemKind.subTrigger) return;
                      runSubSelect();
                    });
                  }

                  for (final it in builtSub.items) {
                    wireSubItem(it);
                  }

                  void onSubMenuKeyDown(web.Event e) {
                    if (e is! web.KeyboardEvent) return;
                    // Menus should not be navigated using tab.
                    if (e.key == "Tab") {
                      e.preventDefault();
                      return;
                    }

                    final dir = _documentDirection();
                    final closeKey = dir == "rtl" ? "ArrowRight" : "ArrowLeft";
                    if (e.key == closeKey) {
                      e.stopPropagation();
                      e.preventDefault();
                      closeSub("close");
                      focusWithoutScrolling(el);
                      return;
                    }

                    // Mirror Kobalte: Alt+ArrowUp closes all.
                    if (e.key == "ArrowUp" && e.altKey) {
                      e.preventDefault();
                      closeRoot("escape");
                      return;
                    }

                    subSelectable.onKeyDown(e);
                  }

                  on(subMenu, "keydown", onSubMenuKeyDown);
                  on(subMenu, "mousedown", (e) {
                    if (e is web.MouseEvent) subSelectable.onMouseDown(e);
                  });
                  on(subMenu, "focusin", (e) {
                    if (e is web.FocusEvent) subSelectable.onFocusIn(e);
                  });
                  on(subMenu, "focusout", (e) {
                    if (e is web.FocusEvent) subSelectable.onFocusOut(e);
                  });

                  focusScope(
                    subMenu,
                    trapFocus: false,
                    restoreFocus: true,
                    onMountAutoFocus: (e) {
                      // Submenu autofocus is managed by the trigger for keyboard users.
                      e.preventDefault();
                    },
                    onUnmountAutoFocus: (e) {
                      // Avoid refocusing trigger on close; handled by close key handler.
                      e.preventDefault();
                    },
                  );

                  onCleanup(() {
                    submenuContent = null;
                    submenuController = null;
                    clearOpenTimer();
                  });

                  return subMenu;
                },
              ),
            );
          }
        }

        for (final item in items) {
          wireItem(item);
        }

        void onRootKeyDown(web.Event e) {
          if (e is! web.KeyboardEvent) return;

          // Menus should not be navigated using tab key.
          if (e.key == "Tab") {
            e.preventDefault();
            return;
          }

          // Mirror Kobalte: Alt+ArrowUp closes.
          if (e.key == "ArrowUp" && e.altKey) {
            e.preventDefault();
            closeRoot("escape");
            return;
          }

          selectable.onKeyDown(e);
        }

        on(menu, "keydown", onRootKeyDown);
        on(menu, "mousedown", (e) {
          if (e is web.MouseEvent) selectable.onMouseDown(e);
        });
        on(menu, "focusin", (e) {
          if (e is web.FocusEvent) selectable.onFocusIn(e);
        });
        on(menu, "focusout", (e) {
          if (e is web.FocusEvent) selectable.onFocusOut(e);
        });

        focusScope(
          menu,
          trapFocus: modal,
          restoreFocus: true,
          onMountAutoFocus: (e) {
            onOpenAutoFocus?.call(e);
            if (e.defaultPrevented) return;
            e.preventDefault();
            scheduleMicrotask(() => focusWithoutScrolling(menu));
          },
          onUnmountAutoFocus: (e) {
            onCloseAutoFocus?.call(e);
            if (e.defaultPrevented) return;
            // Always prevent autofocus because we either focus manually or want UA focus.
            e.preventDefault();
            if ((closeReason == "select" || closeReason == "escape") &&
                anchor is web.HTMLElement) {
              scheduleMicrotask(() => focusWithoutScrolling(anchor as web.HTMLElement));
            }
          },
        );

        rootWrapper.appendChild(menu);
        for (final frag in submenuFragments) {
          if (frag is web.Node) rootWrapper.appendChild(frag);
        }

        return rootWrapper;
      },
    ),
  );
}

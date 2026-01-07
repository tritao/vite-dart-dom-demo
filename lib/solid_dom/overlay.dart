import "dart:async";
import "dart:js_interop";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

final class ScrollLockHandle {
  ScrollLockHandle._(this._restore);
  final void Function() _restore;
  void dispose() => _restore();
}

int _scrollLockCount = 0;
String? _prevBodyOverflow;

ScrollLockHandle scrollLock() {
  final body = web.document.body;
  if (body == null) return ScrollLockHandle._(() {});

  if (_scrollLockCount == 0) {
    _prevBodyOverflow = body.style.overflow;
    body.style.overflow = "hidden";
  }
  _scrollLockCount++;

  void restore() {
    _scrollLockCount--;
    if (_scrollLockCount <= 0) {
      _scrollLockCount = 0;
      body.style.overflow = _prevBodyOverflow ?? "";
      _prevBodyOverflow = null;
    }
  }

  onCleanup(restore);
  return ScrollLockHandle._(restore);
}

final class AriaHiddenHandle {
  AriaHiddenHandle._(this._restore);
  final void Function() _restore;
  void dispose() => _restore();
}

AriaHiddenHandle ariaHideOthers(web.Element keep) {
  final hidden = <web.Element, ({String? ariaHidden, String? inert})>{};
  var disposed = false;

  void apply() {
    final body = web.document.body;
    if (body == null) return;
    final children = body.children;
    for (var i = 0; i < children.length; i++) {
      final node = children.item(i);
      if (node == null) continue;
      if (identical(node, keep) || node.contains(keep)) continue;
      // Never hide "top layer" UI (e.g. toast regions).
      try {
        if (node.getAttribute("data-solid-top-layer") != null ||
            node.querySelector("[data-solid-top-layer]") != null) {
          continue;
        }
      } catch (_) {}
      if (!hidden.containsKey(node)) {
        hidden[node] = (
          ariaHidden: node.getAttribute("aria-hidden"),
          inert: node.getAttribute("inert"),
        );
      }
      node.setAttribute("aria-hidden", "true");
      // inert isn't in all browsers, but it's safe as an attribute.
      node.setAttribute("inert", "");
    }
  }

  void restore() {
    disposed = true;
    for (final entry in hidden.entries) {
      final el = entry.key;
      final prevAria = entry.value.ariaHidden;
      final prevInert = entry.value.inert;
      if (prevAria == null) {
        el.removeAttribute("aria-hidden");
      } else {
        el.setAttribute("aria-hidden", prevAria);
      }
      if (prevInert == null) {
        el.removeAttribute("inert");
      } else {
        el.setAttribute("inert", prevInert);
      }
    }
    hidden.clear();
  }

  void applyWhenConnected() {
    if (disposed) return;
    if (!keep.isConnected) {
      scheduleMicrotask(applyWhenConnected);
      return;
    }
    apply();
  }

  applyWhenConnected();
  onCleanup(restore);
  return AriaHiddenHandle._(restore);
}

List<web.HTMLElement> _focusableWithin(web.Element root) {
  final nodes = root.querySelectorAll(
    'a[href],button,input,select,textarea,[tabindex]:not([tabindex="-1"])',
  );
  final out = <web.HTMLElement>[];
  for (var i = 0; i < nodes.length; i++) {
    final n = nodes.item(i);
    if (n == null || n is! web.HTMLElement) continue;
    final disabled = (n is web.HTMLButtonElement && n.disabled) ||
        (n is web.HTMLInputElement && n.disabled) ||
        (n is web.HTMLSelectElement && n.disabled) ||
        (n is web.HTMLTextAreaElement && n.disabled);
    if (disabled) continue;
    out.add(n);
  }
  return out;
}

final class FocusTrapHandle {
  FocusTrapHandle._(this._restore);
  final void Function() _restore;
  void dispose() => _restore();
}

final List<_FocusTrapEntry> _focusTrapStack = <_FocusTrapEntry>[];

final class _FocusTrapEntry {
  _FocusTrapEntry(this.container);
  final web.Element container;
  bool disposed = false;
}

bool _isTopMostFocusTrap(_FocusTrapEntry entry) {
  if (_focusTrapStack.isEmpty) return false;
  return identical(_focusTrapStack.last, entry);
}

FocusTrapHandle focusTrap(
  web.Element container, {
  web.HTMLElement? initialFocus,
}) {
  final previousActive = web.document.activeElement;
  final entry = _FocusTrapEntry(container);
  _focusTrapStack.add(entry);

  var disposed = false;

  void focusInitial() {
    try {
      if (initialFocus != null) {
        initialFocus.focus();
        return;
      }

      final focusables = _focusableWithin(container);
      if (focusables.isNotEmpty) {
        focusables.first.focus();
        return;
      }

      if (container is web.HTMLElement) {
        container.focus();
      }
    } catch (_) {}
  }

  void focusWhenConnected() {
    if (disposed) return;
    if (!container.isConnected) {
      scheduleMicrotask(focusWhenConnected);
      return;
    }
    focusInitial();
  }

  scheduleMicrotask(focusWhenConnected);

  void onKeydown(web.Event e) {
    if (!_isTopMostFocusTrap(entry)) return;
    if (e is! web.KeyboardEvent) return;
    if (e.key != "Tab") return;
    final focusables = _focusableWithin(container);
    if (focusables.isEmpty) return;

    final active = web.document.activeElement;
    var index = focusables.indexWhere((el) => identical(el, active));
    if (index == -1) index = 0;

    final nextIndex = e.shiftKey
        ? (index - 1 + focusables.length) % focusables.length
        : (index + 1) % focusables.length;
    e.preventDefault();
    focusables[nextIndex].focus();
  }

  final jsHandler = (onKeydown).toJS;
  container.addEventListener("keydown", jsHandler);

  void onFocusIn(web.Event e) {
    if (!_isTopMostFocusTrap(entry)) return;
    if (e is! web.FocusEvent) return;
    final target = e.target;
    if (target is! web.Node) return;
    if (container.contains(target)) return;
    if (target is web.Element &&
        target.closest("[data-solid-top-layer]") != null) {
      return;
    }
    if (!container.isConnected) return;
    focusInitial();
  }

  final jsFocusIn = (onFocusIn).toJS;
  web.document.addEventListener("focusin", jsFocusIn, true.toJS);

  void restore() {
    disposed = true;
    entry.disposed = true;
    container.removeEventListener("keydown", jsHandler);
    web.document.removeEventListener("focusin", jsFocusIn, true.toJS);
    _focusTrapStack.remove(entry);
    if (previousActive is web.HTMLElement) {
      try {
        previousActive.focus();
      } catch (_) {}
    }
  }

  onCleanup(restore);
  return FocusTrapHandle._(restore);
}

final class DismissableLayerHandle {
  DismissableLayerHandle._(this._dispose);
  final void Function() _dispose;
  void dispose() => _dispose();
}

final List<_LayerEntry> _layerStack = <_LayerEntry>[];
final Map<web.HTMLElement, ({String prevPointerEvents, String? prevPointerLayerAttr})>
    _topLayerPointerPatches =
    <web.HTMLElement, ({String prevPointerEvents, String? prevPointerLayerAttr})>{};

final class _LayerEntry {
  _LayerEntry(
    this.element,
    this.onDismiss, {
    required this.disableOutsidePointerEvents,
  });
  final web.Element element;
  final void Function(String reason) onDismiss;
  final bool disableOutsidePointerEvents;

  String? _prevPointerEvents;
  String? _prevPointerLayerAttr;
  bool _pointerPatched = false;
}

String? _prevBodyPointerEvents;

bool _isTopMostLayer(_LayerEntry entry) {
  if (_layerStack.isEmpty) return false;
  return identical(_layerStack.last, entry);
}

_LayerEntry? _topPointerBlockingLayer() {
  for (var i = _layerStack.length - 1; i >= 0; i--) {
    final entry = _layerStack[i];
    if (entry.disableOutsidePointerEvents) return entry;
  }
  return null;
}

void _restorePointerPatches() {
  if (_topLayerPointerPatches.isNotEmpty) {
    for (final entry in _topLayerPointerPatches.entries) {
      final el = entry.key;
      final prev = entry.value.prevPointerEvents;
      final prevLayerAttr = entry.value.prevPointerLayerAttr;
      try {
        el.style.pointerEvents = prev;
      } catch (_) {}
      if (prevLayerAttr == null) {
        el.removeAttribute("data-solid-pointer-layer");
      } else {
        el.setAttribute("data-solid-pointer-layer", prevLayerAttr);
      }
    }
    _topLayerPointerPatches.clear();
  }

  for (final entry in _layerStack) {
    if (!entry._pointerPatched) continue;
    entry._pointerPatched = false;
    final el = entry.element;
    final prev = entry._prevPointerEvents;
    final prevLayerAttr = entry._prevPointerLayerAttr;
    entry._prevPointerEvents = null;
    entry._prevPointerLayerAttr = null;
    if (prev == null) {
      if (el is web.HTMLElement) el.style.pointerEvents = "";
    } else {
      if (el is web.HTMLElement) el.style.pointerEvents = prev;
    }
    if (prevLayerAttr == null) {
      el.removeAttribute("data-solid-pointer-layer");
    } else {
      el.setAttribute("data-solid-pointer-layer", prevLayerAttr);
    }
  }
  final body = web.document.body;
  if (body != null && _prevBodyPointerEvents != null) {
    body.style.pointerEvents = _prevBodyPointerEvents!;
  }
  _prevBodyPointerEvents = null;
}

void _restoreEntryPointerPatch(_LayerEntry entry) {
  if (!entry._pointerPatched) return;
  entry._pointerPatched = false;
  final el = entry.element;
  final prev = entry._prevPointerEvents;
  final prevLayerAttr = entry._prevPointerLayerAttr;
  entry._prevPointerEvents = null;
  entry._prevPointerLayerAttr = null;
  if (el is web.HTMLElement) {
    if (prev == null) {
      el.style.pointerEvents = "";
    } else {
      el.style.pointerEvents = prev;
    }
  }
  if (prevLayerAttr == null) {
    el.removeAttribute("data-solid-pointer-layer");
  } else {
    el.setAttribute("data-solid-pointer-layer", prevLayerAttr);
  }
}

void _syncPointerBlocking() {
  final body = web.document.body;
  if (body == null) return;

  // Always clear previous patches first; stack changes are infrequent and this
  // keeps behavior predictable.
  _restorePointerPatches();

  final blocker = _topPointerBlockingLayer();
  if (blocker == null) return;

  _prevBodyPointerEvents = body.style.pointerEvents;
  body.style.pointerEvents = "none";

  final blockerIndex = _layerStack.indexOf(blocker);
  if (blockerIndex == -1) return;

  // Mirror Kobalte's layer-stack behavior: anything "below" the top-most
  // pointer-blocking layer is non-interactive; the blocker and anything above
  // it stay interactive.
  for (var i = 0; i < _layerStack.length; i++) {
    final entry = _layerStack[i];
    final el = entry.element;
    if (el is! web.HTMLElement) continue;
    entry._prevPointerEvents = el.style.pointerEvents;
    entry._prevPointerLayerAttr = el.getAttribute("data-solid-pointer-layer");
    entry._pointerPatched = true;

    if (i < blockerIndex) {
      el.style.pointerEvents = "none";
      el.removeAttribute("data-solid-pointer-layer");
    } else {
      el.style.pointerEvents = "auto";
      el.setAttribute("data-solid-pointer-layer", "1");
    }
  }

  // Ensure "top layer" elements remain interactive even when the body is
  // pointer-blocked by a modal layer (e.g. toast viewport).
  try {
    final topNodes = body.querySelectorAll("[data-solid-top-layer]");
    for (var i = 0; i < topNodes.length; i++) {
      final n = topNodes.item(i);
      if (n is! web.HTMLElement) continue;
      if (_topLayerPointerPatches.containsKey(n)) continue;
      _topLayerPointerPatches[n] = (
        prevPointerEvents: n.style.pointerEvents,
        prevPointerLayerAttr: n.getAttribute("data-solid-pointer-layer"),
      );
      n.style.pointerEvents = "auto";
      n.setAttribute("data-solid-pointer-layer", "1");
    }
  } catch (_) {}
}

DismissableLayerHandle dismissableLayer(
  web.Element layer, {
  required void Function(String reason) onDismiss,
  bool disableOutsidePointerEvents = false,
  bool dismissOnFocusOutside = true,
  web.Element? stackElement,
  List<web.Element? Function()>? excludedElements,
  void Function(web.Event event)? onPointerDownOutside,
  void Function(web.Event event)? onFocusOutside,
  void Function(web.Event event)? onInteractOutside,
  bool bypassTopMostLayerCheck = false,
}) {
  final stackEl = stackElement ?? layer;
  final entry = _LayerEntry(
    stackEl,
    onDismiss,
    disableOutsidePointerEvents: disableOutsidePointerEvents,
  );
  _layerStack.add(entry);
  _syncPointerBlocking();

  bool isWithinNestedLayer(web.Element target) {
    final index = _layerStack.indexOf(entry);
    if (index == -1) return false;
    for (var i = index + 1; i < _layerStack.length; i++) {
      final other = _layerStack[i].element;
      if (identical(other, layer)) continue;
      if (other.contains(target)) return true;
    }
    return false;
  }

  bool shouldExclude(web.Element target) {
    if (excludedElements != null) {
      for (final get in excludedElements) {
        final el = get();
        if (el == null) continue;
        if (el.contains(target) || identical(el, target)) return true;
      }
    }
    // Ignore interactions inside nested layers (e.g. submenus / nested dialogs).
    if (isWithinNestedLayer(target)) return true;
    // Ignore events targeting "top layer" elements (e.g. toasts), but do not
    // confuse that with pointer-blocking layers (data-solid-pointer-layer).
    if (target.closest("[data-solid-top-layer]") != null) return true;
    return false;
  }

  bool isEventOutside(web.Event e) {
    final target = e.target;
    if (target is! web.Element) return false;
    if (!target.isConnected) return false;
    if (layer.contains(target)) return false;
    if (shouldExclude(target)) return false;
    return true;
  }

  void maybeDismissOutside(web.Event e) {
    if (!bypassTopMostLayerCheck && !_isTopMostLayer(entry)) return;
    if (!isEventOutside(e)) return;
    onPointerDownOutside?.call(e);
    onInteractOutside?.call(e);
    if (e.defaultPrevented) return;
    onDismiss("outside");
  }

  void maybeDismissFocusOutside(web.Event e) {
    if (!dismissOnFocusOutside) return;
    if (!bypassTopMostLayerCheck && !_isTopMostLayer(entry)) return;
    if (e is! web.FocusEvent) return;
    if (!isEventOutside(e)) return;
    onFocusOutside?.call(e);
    onInteractOutside?.call(e);
    if (e.defaultPrevented) return;
    onDismiss("focus-outside");
  }

  void maybeDismissEscape(web.Event e) {
    if (!bypassTopMostLayerCheck && !_isTopMostLayer(entry)) return;
    if (e is! web.KeyboardEvent) return;
    if (e.key != "Escape") return;
    e.preventDefault();
    onDismiss("escape");
  }

  var disposed = false;
  JSFunction? jsClick;

  void onClick(web.Event e) {
    if (disposed) return;
    maybeDismissOutside(e);
  }

  void onPointerDown(web.Event e) {
    if (disposed) return;
    if (e is web.PointerEvent && e.pointerType == "touch") {
      // On touch, defer to the follow-up click. Browsers can delay click, and
      // pointer events may be canceled by scrolling/long-press.
      if (jsClick != null) {
        web.document.removeEventListener("click", jsClick, true.toJS);
      }
      jsClick = (onClick).toJS;
      web.document.addEventListener("click", jsClick, true.toJS);
      return;
    }
    maybeDismissOutside(e);
  }

  final jsPointerDown = (onPointerDown).toJS;
  final jsFocusOutside = (maybeDismissFocusOutside).toJS;
  final jsEscape = (maybeDismissEscape).toJS;

  Timer? registerTimer;
  registerTimer = Timer(Duration.zero, () {
    web.document.addEventListener("pointerdown", jsPointerDown, true.toJS);
    web.document.addEventListener("focusin", jsFocusOutside, true.toJS);
    registerTimer = null;
  });

  web.document.addEventListener("keydown", jsEscape, true.toJS);

  void dispose() {
    disposed = true;
    registerTimer?.cancel();
    registerTimer = null;
    web.document.removeEventListener("pointerdown", jsPointerDown, true.toJS);
    web.document.removeEventListener("focusin", jsFocusOutside, true.toJS);
    web.document.removeEventListener("keydown", jsEscape, true.toJS);
    if (jsClick != null) {
      web.document.removeEventListener("click", jsClick, true.toJS);
      jsClick = null;
    }
    _restoreEntryPointerPatch(entry);
    _layerStack.remove(entry);
    _syncPointerBlocking();
  }

  onCleanup(dispose);
  return DismissableLayerHandle._(dispose);
}

final class RovingTabIndexHandle {
  RovingTabIndexHandle._(this._dispose);
  final void Function() _dispose;
  void dispose() => _dispose();
}

RovingTabIndexHandle rovingTabIndex(
  web.Element container, {
  required List<web.HTMLElement> Function() items,
  required int Function() activeIndex,
  required void Function(int next) setActiveIndex,
  Set<String> nextKeys = const {"ArrowRight", "ArrowDown"},
  Set<String> prevKeys = const {"ArrowLeft", "ArrowUp"},
}) {
  void sync() {
    final els = items();
    final active = activeIndex().clamp(0, els.isEmpty ? 0 : els.length - 1);
    for (var i = 0; i < els.length; i++) {
      els[i].tabIndex = i == active ? 0 : -1;
    }
  }

  createRenderEffect(sync);

  void onKeydown(web.Event e) {
    if (e is! web.KeyboardEvent) return;
    final els = items();
    if (els.isEmpty) return;
    final active = activeIndex().clamp(0, els.length - 1);
    if (nextKeys.contains(e.key)) {
      e.preventDefault();
      final next = (active + 1) % els.length;
      setActiveIndex(next);
      els[next].focus();
      return;
    }
    if (prevKeys.contains(e.key)) {
      e.preventDefault();
      final next = (active - 1 + els.length) % els.length;
      setActiveIndex(next);
      els[next].focus();
      return;
    }
  }

  final jsKeydown = (onKeydown).toJS;
  container.addEventListener("keydown", jsKeydown);

  void dispose() {
    container.removeEventListener("keydown", jsKeydown);
  }

  onCleanup(dispose);
  return RovingTabIndexHandle._(dispose);
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

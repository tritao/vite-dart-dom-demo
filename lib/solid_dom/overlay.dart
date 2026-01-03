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
  final hidden = <web.Element, String?>{};
  var disposed = false;

  void apply() {
    final body = web.document.body;
    if (body == null) return;
    final children = body.children;
    for (var i = 0; i < children.length; i++) {
      final node = children.item(i);
      if (node == null) continue;
      if (identical(node, keep) || node.contains(keep)) continue;
      if (!hidden.containsKey(node)) {
        hidden[node] = node.getAttribute("aria-hidden");
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
      final prev = entry.value;
      if (prev == null) {
        el.removeAttribute("aria-hidden");
      } else {
        el.setAttribute("aria-hidden", prev);
      }
      el.removeAttribute("inert");
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

FocusTrapHandle focusTrap(
  web.Element container, {
  web.HTMLElement? initialFocus,
}) {
  final previousActive = web.document.activeElement;

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

  // Delay initial focus until after the subtree is inserted into the DOM.
  scheduleMicrotask(focusInitial);

  void onKeydown(web.Event e) {
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

  void restore() {
    container.removeEventListener("keydown", jsHandler);
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

final class _LayerEntry {
  _LayerEntry(this.element, this.onDismiss);
  final web.Element element;
  final void Function(String reason) onDismiss;
}

DismissableLayerHandle dismissableLayer(
  web.Element layer, {
  required void Function(String reason) onDismiss,
}) {
  final entry = _LayerEntry(layer, onDismiss);
  _layerStack.add(entry);

  void maybeDismissOutside(web.Event e) {
    if (_layerStack.isEmpty || !identical(_layerStack.last, entry)) return;
    final target = e.target;
    if (target is web.Node) {
      if (layer.contains(target)) return;
    }
    onDismiss("outside");
  }

  void maybeDismissEscape(web.Event e) {
    if (_layerStack.isEmpty || !identical(_layerStack.last, entry)) return;
    if (e is! web.KeyboardEvent) return;
    if (e.key != "Escape") return;
    e.preventDefault();
    onDismiss("escape");
  }

  final jsOutside = (maybeDismissOutside).toJS;
  final jsEscape = (maybeDismissEscape).toJS;
  web.document.addEventListener("pointerdown", jsOutside, true.toJS);
  web.document.addEventListener("keydown", jsEscape, true.toJS);

  void dispose() {
    web.document.removeEventListener("pointerdown", jsOutside, true.toJS);
    web.document.removeEventListener("keydown", jsEscape, true.toJS);
    _layerStack.remove(entry);
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

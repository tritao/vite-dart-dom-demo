import "dart:async";
import "dart:js_interop";

import "package:solidus/solidus.dart";
import "package:web/web.dart" as web;

final class FocusScopeHandle {
  FocusScopeHandle._(this._dispose);
  final void Function() _dispose;
  void dispose() => _dispose();
}

final class FocusScopeAutoFocusEvent {
  FocusScopeAutoFocusEvent._({
    required this.scope,
    required this.previousFocus,
  });

  final web.Element scope;
  final web.HTMLElement? previousFocus;

  bool defaultPrevented = false;
  void preventDefault() {
    defaultPrevented = true;
  }
}

final class _FocusScopeEntry {
  _FocusScopeEntry(this.container);
  final web.Element container;
  bool paused = false;
  bool disposed = false;

  web.HTMLElement? previouslyFocused;
  web.HTMLElement? lastFocusedWithin;

  web.HTMLElement? startSentinel;
  web.HTMLElement? endSentinel;
}

final List<_FocusScopeEntry> _focusScopeStack = <_FocusScopeEntry>[];

bool _isTopMostScope(_FocusScopeEntry entry) =>
    _focusScopeStack.isNotEmpty && identical(_focusScopeStack.last, entry);

void _pausePreviousScope() {
  if (_focusScopeStack.isEmpty) return;
  _focusScopeStack.last.paused = true;
}

void _resumeTopScope() {
  if (_focusScopeStack.isEmpty) return;
  _focusScopeStack.last.paused = false;
}

List<web.HTMLElement> _tabbablesWithin(web.Element root) {
  final nodes = root.querySelectorAll(
    'a[href],button,input,select,textarea,[tabindex]:not([tabindex="-1"])',
  );
  final out = <web.HTMLElement>[];
  for (var i = 0; i < nodes.length; i++) {
    final n = nodes.item(i);
    if (n == null || n is! web.HTMLElement) continue;
    if (n.getAttribute("data-solidus-focus-sentinel") != null) continue;
    final disabled = (n is web.HTMLButtonElement && n.disabled) ||
        (n is web.HTMLInputElement && n.disabled) ||
        (n is web.HTMLSelectElement && n.disabled) ||
        (n is web.HTMLTextAreaElement && n.disabled);
    if (disabled) continue;
    if (n.tabIndex < 0) continue;
    out.add(n);
  }
  return out;
}

web.HTMLElement _createSentinel() {
  final el = web.HTMLSpanElement()
    ..setAttribute("data-solidus-focus-sentinel", "1")
    ..tabIndex = 0;
  final style = el.style;
  style.position = "fixed";
  style.width = "1px";
  style.height = "1px";
  style.padding = "0";
  style.margin = "-1px";
  style.overflow = "hidden";
  style.clip = "rect(0, 0, 0, 0)";
  style.whiteSpace = "nowrap";
  style.border = "0";
  return el;
}

void _focusElement(web.HTMLElement? el) {
  if (el == null) return;
  try {
    el.focus();
  } catch (_) {}
}

bool _isLikelyFocusableOutside(web.Element container) {
  final active = web.document.activeElement;
  if (active is! web.HTMLElement) return false;
  if (active == web.document.body) return false;
  if (container.contains(active)) return false;
  // If something else is already focused, don't steal focus back on unmount.
  return true;
}

FocusScopeHandle focusScope(
  web.Element container, {
  bool trapFocus = false,
  bool? loop,
  bool autoFocus = true,
  web.HTMLElement? initialFocus,
  bool restoreFocus = true,

  /// Call `event.preventDefault()` to prevent the default auto-focus behavior.
  void Function(FocusScopeAutoFocusEvent event)? onMountAutoFocus,

  /// Call `event.preventDefault()` to prevent the default restore-focus behavior.
  void Function(FocusScopeAutoFocusEvent event)? onUnmountAutoFocus,
}) {
  final shouldLoop = loop ?? trapFocus;
  final entry = _FocusScopeEntry(container);
  entry.previouslyFocused = web.document.activeElement is web.HTMLElement
      ? web.document.activeElement as web.HTMLElement
      : null;

  _pausePreviousScope();
  _focusScopeStack.add(entry);

  web.HTMLElement? start;
  web.HTMLElement? end;
  if (shouldLoop) {
    start = _createSentinel();
    end = _createSentinel();
    entry.startSentinel = start;
    entry.endSentinel = end;
  }

  void attachSentinelsWhenConnected() {
    if (!shouldLoop) return;
    if (entry.disposed) return;
    if (!container.isConnected) {
      scheduleMicrotask(attachSentinelsWhenConnected);
      return;
    }
    final first = container.firstChild;
    if (first != null) {
      container.insertBefore(start!, first);
    } else {
      container.appendChild(start!);
    }
    container.appendChild(end!);
  }

  if (shouldLoop) {
    scheduleMicrotask(attachSentinelsWhenConnected);
  }

  void focusInitial() {
    if (entry.disposed) return;
    if (initialFocus != null) {
      _focusElement(initialFocus);
      return;
    }
    final tabbables = _tabbablesWithin(container);
    if (tabbables.isNotEmpty) {
      _focusElement(tabbables.first);
      return;
    }
    if (container is web.HTMLElement) _focusElement(container);
  }

  void runMountAutoFocusWhenConnected() {
    if (entry.disposed) return;
    if (!container.isConnected) {
      scheduleMicrotask(runMountAutoFocusWhenConnected);
      return;
    }

    final mountEvent = FocusScopeAutoFocusEvent._(
      scope: container,
      previousFocus: entry.previouslyFocused,
    );
    onMountAutoFocus?.call(mountEvent);
    if (mountEvent.defaultPrevented) return;

    final active = web.document.activeElement;
    if (active is web.Node && container.contains(active)) return;
    if (!autoFocus) return;
    focusInitial();
  }

  scheduleMicrotask(runMountAutoFocusWhenConnected);

  void onContainerFocusIn(web.Event e) {
    if (entry.disposed) return;
    if (entry.paused) return;
    final target = e.target;
    if (target is! web.HTMLElement) return;
    if (!container.contains(target)) return;
    if (target.getAttribute("data-solidus-focus-sentinel") != null) return;
    entry.lastFocusedWithin = target;
  }

  void onStartSentinelFocus(web.Event _) {
    if (entry.disposed) return;
    if (entry.paused) return;
    if (!_isTopMostScope(entry)) return;
    final tabbables = _tabbablesWithin(container);
    if (tabbables.isNotEmpty) {
      _focusElement(tabbables.last);
    } else if (container is web.HTMLElement) {
      _focusElement(container);
    }
  }

  void onEndSentinelFocus(web.Event _) {
    if (entry.disposed) return;
    if (entry.paused) return;
    if (!_isTopMostScope(entry)) return;
    final tabbables = _tabbablesWithin(container);
    if (tabbables.isNotEmpty) {
      _focusElement(tabbables.first);
    } else if (container is web.HTMLElement) {
      _focusElement(container);
    }
  }

  void onDocumentFocusIn(web.Event e) {
    if (!trapFocus) return;
    if (entry.disposed) return;
    if (entry.paused) return;
    if (!_isTopMostScope(entry)) return;
    if (!container.isConnected) return;

    final target = e.target;
    if (target is! web.Node) return;
    if (container.contains(target)) return;
    if (target is web.Element &&
        target.closest("[data-solidus-top-layer]") != null) {
      return;
    }

    // If focus escapes, bring it back to the last focused element inside.
    final preferred = entry.lastFocusedWithin;
    if (preferred != null) {
      _focusElement(preferred);
      return;
    }
    focusInitial();
  }

  void onKeydown(web.Event e) {
    if (!shouldLoop) return;
    if (entry.disposed) return;
    if (entry.paused) return;
    if (!_isTopMostScope(entry)) return;
    if (e is! web.KeyboardEvent) return;
    if (e.key != "Tab") return;

    final tabbables = _tabbablesWithin(container);
    if (tabbables.isEmpty) return;

    final active = web.document.activeElement;
    var index = tabbables.indexWhere((el) => identical(el, active));
    if (index == -1) index = 0;

    final nextIndex = e.shiftKey
        ? (index - 1 + tabbables.length) % tabbables.length
        : (index + 1) % tabbables.length;
    e.preventDefault();
    _focusElement(tabbables[nextIndex]);
  }

  final jsContainerFocus = (onContainerFocusIn).toJS;
  final jsKeydown = (onKeydown).toJS;
  final jsStartFocus = (onStartSentinelFocus).toJS;
  final jsEndFocus = (onEndSentinelFocus).toJS;
  final jsDocFocus = (onDocumentFocusIn).toJS;

  container.addEventListener("focusin", jsContainerFocus, true.toJS);
  container.addEventListener("keydown", jsKeydown, true.toJS);
  if (shouldLoop) {
    start!.addEventListener("focus", jsStartFocus);
    end!.addEventListener("focus", jsEndFocus);
  }

  Timer? docRegister;
  if (trapFocus) {
    docRegister = Timer(Duration.zero, () {
      web.document.addEventListener("focusin", jsDocFocus, true.toJS);
      docRegister = null;
    });
  }

  void detachSentinel(web.HTMLElement? el) {
    if (el == null) return;
    final parent = el.parentNode;
    if (parent != null) parent.removeChild(el);
  }

  void dispose() {
    if (entry.disposed) return;
    entry.disposed = true;

    docRegister?.cancel();
    docRegister = null;

    container.removeEventListener("focusin", jsContainerFocus, true.toJS);
    container.removeEventListener("keydown", jsKeydown, true.toJS);
    if (shouldLoop) {
      start!.removeEventListener("focus", jsStartFocus);
      end!.removeEventListener("focus", jsEndFocus);
    }
    if (trapFocus) {
      web.document.removeEventListener("focusin", jsDocFocus, true.toJS);
    }

    detachSentinel(start);
    detachSentinel(end);

    _focusScopeStack.remove(entry);
    _resumeTopScope();

    final unmountEvent = FocusScopeAutoFocusEvent._(
      scope: container,
      previousFocus: entry.previouslyFocused,
    );
    onUnmountAutoFocus?.call(unmountEvent);

    if (!restoreFocus) return;
    if (unmountEvent.defaultPrevented) return;
    if (_isLikelyFocusableOutside(container)) return;
    _focusElement(entry.previouslyFocused);
  }

  onCleanup(dispose);
  return FocusScopeHandle._(dispose);
}

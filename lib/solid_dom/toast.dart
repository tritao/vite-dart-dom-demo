import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./presence.dart";
import "./solid_dom.dart";

final class ToastEntry {
  ToastEntry({
    required this.id,
    required this.message,
    required this.open,
  });

  final int id;
  final String message;
  final bool open;

  ToastEntry copyWith({String? message, bool? open}) => ToastEntry(
        id: id,
        message: message ?? this.message,
        open: open ?? this.open,
      );
}

final class ToastController {
  ToastController({
    this.exitMs = 120,
    this.defaultDurationMs = 2500,
  });

  final int exitMs;
  final int defaultDurationMs;

  final _toasts = createSignal<List<ToastEntry>>(<ToastEntry>[]);
  final _timers = <int, Timer>{};
  final _exitTimers = <int, Timer>{};
  var _nextId = 1;

  List<ToastEntry> get toasts => _toasts.value;

  int show(
    String message, {
    int? durationMs,
  }) {
    final id = _nextId++;
    final entry = ToastEntry(id: id, message: message, open: true);
    _toasts.value = <ToastEntry>[..._toasts.value, entry];

    final ttl = durationMs ?? defaultDurationMs;
    if (ttl > 0) {
      _timers[id]?.cancel();
      _timers[id] = Timer(Duration(milliseconds: ttl), () {
        dismiss(id, reason: "timeout");
      });
    }
    return id;
  }

  void dismiss(int id, {String reason = "dismiss"}) {
    final list = _toasts.value;
    final index = list.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final existing = list[index];
    if (!existing.open) return;

    _timers.remove(id)?.cancel();

    final next = <ToastEntry>[...list];
    next[index] = existing.copyWith(open: false);
    _toasts.value = next;

    _exitTimers.remove(id)?.cancel();
    _exitTimers[id] = Timer(Duration(milliseconds: exitMs), () {
      remove(id);
    });
  }

  void remove(int id) {
    _timers.remove(id)?.cancel();
    _exitTimers.remove(id)?.cancel();
    _toasts.value = _toasts.value.where((t) => t.id != id).toList();
  }

  web.DocumentFragment view({
    String portalId = "toast-portal-container",
    String viewportId = "toast-viewport",
  }) {
    final placeholder = Portal(
      id: portalId,
      children: () {
        final viewport = web.HTMLDivElement()
          ..id = viewportId
          ..className = "toastViewport"
          ..setAttribute("data-solid-toast-viewport", "1")
          ..setAttribute("data-solid-top-layer", "1")
          ..setAttribute("role", "region")
          ..setAttribute("aria-label", "Notifications")
          ..setAttribute("aria-live", "polite");

        viewport.appendChild(
          For<ToastEntry, int>(
            each: () => _toasts.value,
            key: (t) => t.id,
            children: (get) => Presence(
              when: () => get().open,
              exitMs: exitMs,
              children: () {
                final toast = get();
                final card = web.HTMLDivElement()
                  ..id = "toast-${toast.id}"
                  ..className = "card"
                  ..setAttribute("role", "status");

                final textEl = web.HTMLParagraphElement()
                  ..textContent = toast.message;
                card.appendChild(textEl);

                final close = web.HTMLButtonElement()
                  ..type = "button"
                  ..className = "btn secondary"
                  ..textContent = "Dismiss";
                on(
                  close,
                  "click",
                  (_) => dismiss(toast.id, reason: "button"),
                );
                card.appendChild(close);

                return card;
              },
            ),
          ),
        );

        return viewport;
      },
    );
    return web.DocumentFragment()..appendChild(placeholder);
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    for (final t in _exitTimers.values) {
      t.cancel();
    }
    _exitTimers.clear();
  }
}

ToastController createToaster({
  int exitMs = 120,
  int defaultDurationMs = 2500,
}) {
  final controller = ToastController(
    exitMs: exitMs,
    defaultDurationMs: defaultDurationMs,
  );
  onCleanup(controller.dispose);
  return controller;
}

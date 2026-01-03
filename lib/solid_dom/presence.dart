import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "dart:async";

/// Mounts/unmounts children with an optional exit delay (for animations).
///
/// When `when()` transitions false, the subtree stays mounted for [exitMs]
/// milliseconds before disposal, unless it becomes true again.
web.DocumentFragment Presence({
  required bool Function() when,
  required Object? Function() children,
  int exitMs = 0,
}) {
  final start = web.Comment("solid:presence-start");
  final end = web.Comment("solid:presence-end");
  final fragment = web.DocumentFragment()
    ..appendChild(start)
    ..appendChild(end);

  Dispose? disposeSubtree;
  final current = <web.Node>[];
  Timer? timer;
  var version = 0;

  void clearNow() {
    timer?.cancel();
    timer = null;
    for (final node in current) {
      final parent = node.parentNode;
      if (parent != null) parent.removeChild(node);
    }
    current.clear();
    disposeSubtree?.call();
    disposeSubtree = null;
  }

  void mountNow() {
    clearNow();
    createChildRoot<void>((dispose) {
      disposeSubtree = dispose;
      final built = children();
      final nodes = _normalizeToNodes(built);
      current.addAll(nodes);
      for (final node in nodes) {
        end.parentNode?.insertBefore(node, end);
      }
    });
  }

  createRenderEffect(() {
    final open = when();
    if (open) {
      version++;
      if (disposeSubtree == null) mountNow();
      return;
    }
    if (disposeSubtree == null) return;
    if (exitMs <= 0) {
      clearNow();
      return;
    }
    final my = ++version;
    timer?.cancel();
    timer = Timer(Duration(milliseconds: exitMs), () {
      if (my != version) return;
      clearNow();
    });
  });

  onCleanup(() {
    timer?.cancel();
    timer = null;
    clearNow();
    final p1 = start.parentNode;
    if (p1 != null) p1.removeChild(start);
    final p2 = end.parentNode;
    if (p2 != null) p2.removeChild(end);
  });

  return fragment;
}

List<web.Node> _normalizeToNodes(Object? value) {
  if (value == null) return const <web.Node>[];
  if (value is web.Node) return <web.Node>[value];
  if (value is Iterable) {
    final out = <web.Node>[];
    for (final v in value) {
      out.addAll(_normalizeToNodes(v));
    }
    return out;
  }
  if (value is String || value is num || value is bool) {
    return <web.Node>[web.Text(value.toString())];
  }
  throw ArgumentError.value(value, "value");
}

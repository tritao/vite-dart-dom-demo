import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

typedef SolidView = Object? Function();

Dispose render(web.Node mount, SolidView view) {
  return createRoot<Dispose>((dispose) {
    mount.textContent = "";

    final nodes = _normalizeToNodes(view());
    for (final node in nodes) {
      mount.appendChild(node);
    }

    onCleanup(() {
      for (final node in nodes) {
        _detach(node);
      }
    });

    return dispose;
  });
}

web.Text text(String Function() compute) {
  final node = web.Text("");
  createRenderEffect(() {
    node.data = compute();
  });
  return node;
}

/// Inserts dynamic content into [parent] between comment anchors.
///
/// The [compute] callback may return:
/// - `null` (renders nothing)
/// - `String` / `num` / `bool` (renders as a text node)
/// - `web.Node`
/// - `Iterable<web.Node>`
web.DocumentFragment insert(web.Node parent, Object? Function() compute) {
  final start = web.Comment("solid:start");
  final end = web.Comment("solid:end");
  final fragment = web.DocumentFragment()
    ..appendChild(start)
    ..appendChild(end);

  final current = <web.Node>[];

  void replaceWith(List<web.Node> next) {
    for (final node in current) {
      _detach(node);
    }
    current
      ..clear()
      ..addAll(next);

    for (final node in next) {
      end.parentNode?.insertBefore(node, end);
    }
  }

  createRenderEffect(() {
    final next = _normalizeToNodes(compute());
    replaceWith(next);
  });

  onCleanup(() {
    replaceWith(const []);
    _detach(start);
    _detach(end);
  });

  return fragment;
}

web.DocumentFragment Show({
  required bool Function() when,
  required SolidView children,
  SolidView? fallback,
}) {
  final start = web.Comment("solid:show-start");
  final end = web.Comment("solid:show-end");
  final fragment = web.DocumentFragment()
    ..appendChild(start)
    ..appendChild(end);

  Dispose? disposeSubtree;
  final current = <web.Node>[];

  void clear() {
    for (final node in current) {
      _detach(node);
    }
    current.clear();
    disposeSubtree?.call();
    disposeSubtree = null;
  }

  void mount(SolidView builder) {
    clear();
    createChildRoot<void>((dispose) {
      disposeSubtree = dispose;
      final nodes = _normalizeToNodes(builder());
      current.addAll(nodes);
      for (final node in nodes) {
        end.parentNode?.insertBefore(node, end);
      }
    });
  }

  createRenderEffect(() {
    if (when()) {
      if (disposeSubtree == null) mount(children);
      return;
    }
    if (fallback != null) {
      if (disposeSubtree == null) mount(fallback);
      return;
    }
    clear();
  });

  onCleanup(() {
    clear();
    _detach(start);
    _detach(end);
  });

  return fragment;
}

List<web.Node> _normalizeToNodes(Object? value) {
  if (value == null) return const <web.Node>[];
  if (value is web.Node) return <web.Node>[value];
  if (value is Iterable<web.Node>) return value.toList(growable: false);
  if (value is String || value is num || value is bool) {
    return <web.Node>[web.Text(value.toString())];
  }
  throw ArgumentError.value(
    value,
    "value",
    "Expected null, String/num/bool, Node, or Iterable<Node>",
  );
}

void _detach(web.Node node) {
  final parent = node.parentNode;
  if (parent == null) return;
  parent.removeChild(node);
}

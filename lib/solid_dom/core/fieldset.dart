import "package:web/web.dart" as web;

/// Fieldset primitive (unstyled).
web.HTMLFieldSetElement createFieldset({
  String? id,
  String className = "",
  String? legend,
  String legendClassName = "",
  bool disabled = false,
  Iterable<web.Node> Function()? children,
}) {
  final root = web.HTMLFieldSetElement()
    ..id = id ?? ""
    ..className = className;
  root.disabled = disabled;

  if (legend != null && legend.trim().isNotEmpty) {
    final l = web.HTMLLegendElement()
      ..className = legendClassName
      ..textContent = legend;
    root.appendChild(l);
  }

  final nodes = children?.call();
  if (nodes != null) {
    for (final n in nodes) {
      root.appendChild(n);
    }
  }

  return root;
}


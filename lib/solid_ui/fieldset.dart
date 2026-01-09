import "package:web/web.dart" as web;

import "../solid_dom/core/fieldset.dart";

/// Styled Fieldset (Solidus UI skin).
web.HTMLFieldSetElement Fieldset({
  String? id,
  String className = "fieldset",
  String? legend,
  String legendClassName = "fieldsetLegend",
  bool disabled = false,
  Iterable<web.Node> Function()? children,
}) {
  return createFieldset(
    id: id,
    className: className,
    legend: legend,
    legendClassName: legendClassName,
    disabled: disabled,
    children: children,
  );
}


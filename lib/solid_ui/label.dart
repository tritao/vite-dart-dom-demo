import "package:web/web.dart" as web;

import "../solid_dom/core/label.dart";

/// Styled Label (Solidus UI skin).
///
/// For an unstyled primitive, use `createLabel` from `solid_dom`.
web.HTMLLabelElement Label({
  required String text,
  String? htmlFor,
  String className = "label",
  bool required = false,
}) {
  return createLabel(
    text: text,
    htmlFor: htmlFor,
    className: className,
    required: required,
  );
}


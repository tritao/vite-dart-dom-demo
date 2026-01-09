import "package:web/web.dart" as web;

import "../solid_dom/solid_dom.dart";

enum HelperTextVariant { description, error }

/// Styled helper text (description or error) for forms.
web.HTMLParagraphElement HelperText({
  required String Function() compute,
  HelperTextVariant variant = HelperTextVariant.description,
  String descriptionClassName = "formDescription",
  String errorClassName = "formMessage",
}) {
  final p = web.HTMLParagraphElement();
  p.className = variant == HelperTextVariant.error
      ? errorClassName
      : descriptionClassName;
  p.appendChild(text(compute));
  return p;
}

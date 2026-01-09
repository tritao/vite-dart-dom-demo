import "package:web/web.dart" as web;

enum HelperTextVariant { description, error }

/// Styled helper text (description or error) for forms.
web.HTMLParagraphElement HelperText({
  required String Function() text,
  HelperTextVariant variant = HelperTextVariant.description,
  String descriptionClassName = "formDescription",
  String errorClassName = "formMessage",
}) {
  final p = web.HTMLParagraphElement();
  p.className = variant == HelperTextVariant.error
      ? errorClassName
      : descriptionClassName;
  p.textContent = text();
  return p;
}


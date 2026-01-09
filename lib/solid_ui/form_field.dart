import "package:web/web.dart" as web;

import "../solid_dom/core/form_field.dart";

/// Styled FormField (Solidus UI skin).
///
/// Wires label/description/error to the control with the expected ARIA
/// attributes.
web.HTMLElement FormField({
  required web.HTMLElement control,
  web.HTMLElement? a11yTarget,
  String? Function()? label,
  String? Function()? description,
  String? Function()? error,
  String? id,
  String className = "formField",
  String labelClassName = "formLabel",
  String descriptionClassName = "formDescription",
  String messageClassName = "formMessage",
  String controlWrapClassName = "formControl",
}) {
  return createFormField(
    control: control,
    a11yTarget: a11yTarget,
    label: label,
    description: description,
    error: error,
    id: id,
    className: className,
    labelClassName: labelClassName,
    descriptionClassName: descriptionClassName,
    messageClassName: messageClassName,
    controlWrapClassName: controlWrapClassName,
  );
}

import "package:web/web.dart" as web;

import "../solid_dom/core/input.dart";

/// Styled Input (Solidus UI skin).
///
/// For an unstyled primitive, use `createInput` from `solid_dom`.
web.HTMLInputElement Input({
  String type = "text",
  String? id,
  String className = "input",
  String? ariaLabel,
  String? placeholder,
  bool Function()? disabled,
  String? Function()? value,
  void Function(String next)? setValue,
  void Function(web.Event e, String currentValue)? onInput,
  void Function(web.Event e, String currentValue)? onChange,
}) {
  return createInput(
    type: type,
    id: id,
    className: className,
    ariaLabel: ariaLabel,
    placeholder: placeholder,
    disabled: disabled,
    value: value,
    setValue: setValue,
    onInput: onInput,
    onChange: onChange,
  );
}


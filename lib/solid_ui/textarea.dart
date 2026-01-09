import "package:web/web.dart" as web;

import "../solid_dom/core/textarea.dart";
import "../solid_dom/core/textarea_autosize.dart";

/// Styled Textarea (Solidus UI skin).
web.HTMLTextAreaElement Textarea({
  String? id,
  String className = "textarea",
  String? ariaLabel,
  String? placeholder,
  int? rows,
  int? cols,
  bool autosize = false,
  bool Function()? disabled,
  String? Function()? value,
  void Function(String next)? setValue,
  void Function(web.Event e, String currentValue)? onInput,
  void Function(web.Event e, String currentValue)? onChange,
  int? maxHeightPx,
}) {
  if (autosize) {
    return createTextareaAutosize(
      id: id,
      className: className,
      ariaLabel: ariaLabel,
      placeholder: placeholder,
      rows: rows,
      cols: cols,
      disabled: disabled,
      value: value,
      setValue: setValue,
      onInput: onInput,
      onChange: onChange,
      maxHeightPx: maxHeightPx,
    );
  }

  return createTextarea(
    id: id,
    className: className,
    ariaLabel: ariaLabel,
    placeholder: placeholder,
    rows: rows,
    cols: cols,
    disabled: disabled,
    value: value,
    setValue: setValue,
    onInput: onInput,
    onChange: onChange,
  );
}

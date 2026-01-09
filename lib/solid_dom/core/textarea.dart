import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "../solid_dom.dart";

/// Textarea primitive (unstyled).
web.HTMLTextAreaElement createTextarea({
  String? id,
  String className = "",
  String? ariaLabel,
  String? placeholder,
  int? rows,
  int? cols,
  bool Function()? disabled,
  String? Function()? value,
  void Function(String next)? setValue,
  void Function(web.Event e, String currentValue)? onInput,
  void Function(web.Event e, String currentValue)? onChange,
}) {
  final isDisabled = disabled ?? () => false;
  final valueAccessor = value;

  final el = web.HTMLTextAreaElement()
    ..id = id ?? ""
    ..className = className;

  if (ariaLabel != null && ariaLabel.isNotEmpty) {
    el.setAttribute("aria-label", ariaLabel);
  }
  if (placeholder != null) el.placeholder = placeholder;
  if (rows != null) el.rows = rows;
  if (cols != null) el.cols = cols;

  createRenderEffect(() {
    final d = isDisabled();
    el.disabled = d;
    if (d) {
      el.setAttribute("aria-disabled", "true");
      el.setAttribute("data-disabled", "true");
    } else {
      el.removeAttribute("aria-disabled");
      el.removeAttribute("data-disabled");
    }
  });

  if (valueAccessor != null) {
    createRenderEffect(() {
      final next = valueAccessor() ?? "";
      if (el.value != next) el.value = next;
    });
  }

  on(el, "input", (e) {
    final current = el.value;
    setValue?.call(current);
    onInput?.call(e, current);
  });

  on(el, "change", (e) {
    final current = el.value;
    onChange?.call(e, current);
  });

  return el;
}


import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "../solid_dom.dart";

/// Input primitive (unstyled).
///
/// This is a thin helper around `<input>` to support controlled/uncontrolled
/// patterns with automatic cleanup.
web.HTMLInputElement createInput({
  String type = "text",
  String? id,
  String className = "",
  String? ariaLabel,
  String? placeholder,
  bool Function()? disabled,
  String? Function()? value,
  void Function(String next)? setValue,
  void Function(web.Event e, String currentValue)? onInput,
  void Function(web.Event e, String currentValue)? onChange,
}) {
  final isDisabled = disabled ?? () => false;
  final valueAccessor = value;

  final input = web.HTMLInputElement()
    ..type = type
    ..id = id ?? ""
    ..className = className;

  if (ariaLabel != null && ariaLabel.isNotEmpty) {
    input.setAttribute("aria-label", ariaLabel);
  }
  if (placeholder != null) input.placeholder = placeholder;

  createRenderEffect(() {
    final d = isDisabled();
    input.disabled = d;
    if (d) {
      input.setAttribute("aria-disabled", "true");
      input.setAttribute("data-disabled", "true");
    } else {
      input.removeAttribute("aria-disabled");
      input.removeAttribute("data-disabled");
    }
  });

  if (valueAccessor != null) {
    createRenderEffect(() {
      final next = valueAccessor() ?? "";
      if (input.value != next) input.value = next;
    });
  }

  on(input, "input", (e) {
    final current = input.value;
    setValue?.call(current);
    onInput?.call(e, current);
  });

  on(input, "change", (e) {
    final current = input.value;
    onChange?.call(e, current);
  });

  return input;
}


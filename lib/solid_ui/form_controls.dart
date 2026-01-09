import "package:web/web.dart" as web;

import "../solid_dom/solid_dom.dart";

typedef InputGroupControl = ({
  web.HTMLElement anchor,
  web.HTMLInputElement input,
  web.HTMLButtonElement? button,
});

/// Builds an input group: a wrapper + input + optional right-side button.
///
/// This is a UI convenience helper to keep examples consistent.
InputGroupControl buildInputGroup({
  web.HTMLInputElement? input,
  String? inputId,
  String? placeholder,
  String inputClassName = "input",
  String anchorClassName = "comboControl",
  bool includeButton = false,
  String buttonClassName = "comboTrigger",
  String buttonAriaLabel = "",
  web.Node Function()? buttonChild,
}) {
  final resolvedInput = input ??
      (web.HTMLInputElement()
        ..type = "text"
        ..className = inputClassName);

  if (inputId != null && inputId.isNotEmpty) resolvedInput.id = inputId;
  if (placeholder != null) resolvedInput.placeholder = placeholder;
  if (resolvedInput.className.isEmpty) resolvedInput.className = inputClassName;

  web.HTMLButtonElement? button;
  if (includeButton) {
    button = web.HTMLButtonElement()
      ..type = "button"
      ..className = buttonClassName;
    if (buttonAriaLabel.isNotEmpty) {
      button.setAttribute("aria-label", buttonAriaLabel);
    }
    final child = buttonChild?.call();
    if (child != null) button.appendChild(child);
  }

  final anchor = web.HTMLDivElement()..className = anchorClassName;
  anchor.appendChild(resolvedInput);
  if (button != null) anchor.appendChild(button);

  return (anchor: anchor, input: resolvedInput, button: button);
}

web.SVGSVGElement _chevronsSvg() {
  final svg = web.document.createElementNS(
    "http://www.w3.org/2000/svg",
    "svg",
  ) as web.SVGSVGElement
    ..setAttribute("viewBox", "0 0 24 24")
    ..setAttribute("aria-hidden", "true")
    ..setAttribute("width", "18")
    ..setAttribute("height", "18")
    ..setAttribute("fill", "none")
    ..setAttribute("stroke", "currentColor")
    ..setAttribute("stroke-width", "2")
    ..setAttribute("stroke-linecap", "round")
    ..setAttribute("stroke-linejoin", "round");

  final p1 = web.document.createElementNS(
    "http://www.w3.org/2000/svg",
    "path",
  ) as web.SVGElement
    ..setAttribute("d", "m7 15 5 5 5-5");
  final p2 = web.document.createElementNS(
    "http://www.w3.org/2000/svg",
    "path",
  ) as web.SVGElement
    ..setAttribute("d", "m7 9 5-5 5 5");
  svg.appendChild(p1);
  svg.appendChild(p2);
  return svg;
}

typedef SelectControl = ({
  web.HTMLButtonElement trigger,
});

/// Builds a Select trigger button with reactive label.
SelectControl buildSelectControl({
  String? id,
  String className = "btn primary",
  required String Function() label,
  String? ariaLabel,
}) {
  final btn = web.HTMLButtonElement()
    ..type = "button"
    ..id = id ?? ""
    ..className = className;

  if (ariaLabel != null && ariaLabel.isNotEmpty) {
    btn.setAttribute("aria-label", ariaLabel);
  }

  btn.appendChild(text(label));
  return (trigger: btn);
}

typedef ComboboxControl = ({
  web.HTMLElement anchor,
  web.HTMLInputElement input,
  web.HTMLButtonElement? triggerButton,
});

/// Builds a Combobox control (anchor + input + trigger button).
ComboboxControl buildComboboxControl({
  web.HTMLInputElement? input,
  String? inputId,
  String? placeholder,
  String inputClassName = "input",
  bool includeTrigger = true,
  String triggerClassName = "comboTrigger",
  String triggerAriaLabel = "Show options",
  String anchorClassName = "comboControl",
}) {
  final group = buildInputGroup(
    input: input,
    inputId: inputId,
    placeholder: placeholder,
    inputClassName: inputClassName,
    anchorClassName: anchorClassName,
    includeButton: includeTrigger,
    buttonClassName: triggerClassName,
    buttonAriaLabel: triggerAriaLabel,
    buttonChild: _chevronsSvg,
  );

  return (anchor: group.anchor, input: group.input, triggerButton: group.button);
}

import "package:web/web.dart" as web;

import "../solid_dom/core/combobox.dart";

typedef ComboboxControl = ({
  web.HTMLElement anchor,
  web.HTMLInputElement input,
  web.HTMLButtonElement? triggerButton,
});

/// Builds a combobox control (anchor + input + optional trigger button).
///
/// This is a UI convenience helper so examples can share markup and integrate
/// with `Input`/`FormField` without duplicating the same DOM scaffolding.
ComboboxControl buildComboboxControl({
  web.HTMLInputElement? input,
  String? inputId,
  String? placeholder,
  String inputClassName = "input",
  bool includeTrigger = true,
  String triggerClassName = "comboTrigger",
  String triggerAriaLabel = "Show options",
  String anchorClassName = "comboControl",
  web.HTMLElement Function(
    web.HTMLInputElement input,
    web.HTMLButtonElement? triggerButton,
  )? controlBuilder,
}) {
  final resolvedInput = input ??
      (web.HTMLInputElement()
        ..type = "text"
        ..className = inputClassName);

  if (inputId != null && inputId.isNotEmpty) {
    resolvedInput.id = inputId;
  }
  if (placeholder != null) {
    resolvedInput.placeholder = placeholder;
  }
  if (resolvedInput.className.isEmpty) {
    resolvedInput.className = inputClassName;
  }

  web.HTMLButtonElement? triggerButton;
  if (includeTrigger) {
    triggerButton = web.HTMLButtonElement()
      ..type = "button"
      ..className = triggerClassName
      ..setAttribute("aria-label", triggerAriaLabel);

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
    triggerButton.appendChild(svg);
  }

  final anchor = controlBuilder != null
      ? controlBuilder(resolvedInput, triggerButton)
      : (() {
          final el = web.HTMLDivElement()..className = anchorClassName;
          el.appendChild(resolvedInput);
          if (triggerButton != null) el.appendChild(triggerButton);
          return el;
        })();

  if (anchorClassName.isNotEmpty && anchor.className.isEmpty) {
    anchor.className = anchorClassName;
  }

  return (anchor: anchor, input: resolvedInput, triggerButton: triggerButton);
}

/// Styled Combobox (Solidus UI skin).
///
/// For an unstyled primitive, use `createCombobox` from `solid_dom`.
web.DocumentFragment Combobox<T>({
  required bool Function() open,
  required void Function(bool next) setOpen,
  required web.HTMLElement anchor,
  required web.HTMLInputElement input,
  web.HTMLButtonElement? triggerButton,
  required Iterable<ComboboxOption<T>> Function() options,
  required T? Function() value,
  required void Function(T? next) setValue,
  bool Function(T a, T b)? equals,
  String? listboxId,
  String placement = "bottom-start",
  double offset = 6,
  double viewportPadding = 8,
  bool flip = true,
  bool showArrow = false,
  double arrowPadding = 4,
  bool allowsEmptyCollection = false,
  bool keepOpenOnEmpty = false,
  String emptyText = "No results.",
  bool noResetInputOnBlur = false,
  bool disallowEmptySelection = false,
  bool closeOnSelection = true,
  ComboboxFilter<T>? filter,
  String triggerMode = "input",
  void Function(String reason)? onClose,
  int exitMs = 0,
  String? portalId,
  ComboboxOptionBuilder<T>? optionBuilder,
}) {
  return createCombobox(
    open: open,
    setOpen: setOpen,
    anchor: anchor,
    input: input,
    triggerButton: triggerButton,
    options: options,
    value: value,
    setValue: setValue,
    equals: equals,
    listboxId: listboxId,
    placement: placement,
    offset: offset,
    viewportPadding: viewportPadding,
    flip: flip,
    showArrow: showArrow,
    arrowPadding: arrowPadding,
    allowsEmptyCollection: allowsEmptyCollection,
    keepOpenOnEmpty: keepOpenOnEmpty,
    emptyText: emptyText,
    noResetInputOnBlur: noResetInputOnBlur,
    disallowEmptySelection: disallowEmptySelection,
    closeOnSelection: closeOnSelection,
    filter: filter,
    triggerMode: triggerMode,
    onClose: onClose,
    exitMs: exitMs,
    portalId: portalId,
    listboxClassName: "card listbox",
    listboxScrollClassName: "listboxScroll",
    listboxOptionClassName: "listboxOption",
    listboxSectionGroupClassName: "listboxGroup",
    listboxSectionLabelClassName: "listboxGroupLabel",
    listboxEmptyClassName: "listboxEmpty",
    optionBuilder: optionBuilder,
  );
}

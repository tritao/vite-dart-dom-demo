import "dart:js_interop";

import "package:web/web.dart" as web;

enum ButtonVariant {
  /// shadcn: "default"
  normal,
  secondary,
  outline,
  ghost,
  link,
  destructive,
}

enum ButtonSize {
  normal,
  sm,
  lg,
  icon,
}

String _variantClass(ButtonVariant v) {
  switch (v) {
    case ButtonVariant.normal:
      return "default";
    case ButtonVariant.secondary:
      return "secondary";
    case ButtonVariant.outline:
      return "outline";
    case ButtonVariant.ghost:
      return "ghost";
    case ButtonVariant.link:
      return "link";
    case ButtonVariant.destructive:
      return "destructive";
  }
}

String _sizeClass(ButtonSize s) {
  switch (s) {
    case ButtonSize.normal:
      return "size-default";
    case ButtonSize.sm:
      return "size-sm";
    case ButtonSize.lg:
      return "size-lg";
    case ButtonSize.icon:
      return "size-icon";
  }
}

String buttonClassName({
  ButtonVariant variant = ButtonVariant.normal,
  ButtonSize size = ButtonSize.normal,
  String? className,
}) {
  final parts = <String>[
    "btn",
    _variantClass(variant),
    _sizeClass(size),
    if (className != null && className.trim().isNotEmpty) className.trim(),
  ];
  return parts.join(" ");
}

web.HTMLElement Button({
  required String label,
  ButtonVariant variant = ButtonVariant.normal,
  ButtonSize size = ButtonSize.normal,
  bool disabled = false,
  String? ariaLabel,
  String? className,
  void Function(web.MouseEvent e)? onClick,
}) {
  final btn = web.HTMLButtonElement()
    ..type = "button"
    ..className = buttonClassName(variant: variant, size: size, className: className)
    ..disabled = disabled
    ..textContent = label;
  if (ariaLabel != null && ariaLabel.isNotEmpty) btn.setAttribute("aria-label", ariaLabel);
  if (onClick != null) {
    final jsHandler = ((web.Event e) {
      if (e is web.MouseEvent) onClick(e);
    }).toJS;
    btn.addEventListener("click", jsHandler);
  }
  return btn;
}

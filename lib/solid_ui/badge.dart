import "package:web/web.dart" as web;

enum BadgeVariant {
  normal,
  secondary,
  outline,
  destructive,
}

String _variantClass(BadgeVariant v) {
  switch (v) {
    case BadgeVariant.normal:
      return "default";
    case BadgeVariant.secondary:
      return "secondary";
    case BadgeVariant.outline:
      return "outline";
    case BadgeVariant.destructive:
      return "destructive";
  }
}

String badgeClassName({
  BadgeVariant variant = BadgeVariant.normal,
  String? className,
}) {
  final parts = <String>[
    "badge",
    _variantClass(variant),
    if (className != null && className.trim().isNotEmpty) className.trim(),
  ];
  return parts.join(" ");
}

web.HTMLElement Badge({
  required String label,
  BadgeVariant variant = BadgeVariant.normal,
  String? className,
}) {
  return web.HTMLSpanElement()
    ..className = badgeClassName(variant: variant, className: className)
    ..textContent = label;
}

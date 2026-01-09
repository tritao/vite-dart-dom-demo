import "package:web/web.dart" as web;

enum AlertVariant {
  normal,
  destructive,
}

String _variantClass(AlertVariant v) {
  switch (v) {
    case AlertVariant.normal:
      return "default";
    case AlertVariant.destructive:
      return "destructive";
  }
}

String alertClassName({
  AlertVariant variant = AlertVariant.normal,
  String? className,
}) {
  final parts = <String>[
    "alert",
    _variantClass(variant),
    if (className != null && className.trim().isNotEmpty) className.trim(),
  ];
  return parts.join(" ");
}

web.HTMLElement AlertTitle(String text, {String className = "alertTitle"}) {
  return web.HTMLDivElement()
    ..className = className
    ..textContent = text;
}

web.HTMLElement AlertDescription(
  String text, {
  String className = "alertDescription",
}) {
  return web.HTMLDivElement()
    ..className = className
    ..textContent = text;
}

/// Alert / callout primitive (shadcn-ish).
///
/// Uses `role="alert"` for parity with shadcn. If you don't want live-region
/// semantics, set `role` to "status" or remove it in your own wrapper.
web.HTMLElement Alert({
  required Iterable<web.Node> children,
  AlertVariant variant = AlertVariant.normal,
  String? className,
  String role = "alert",
}) {
  final root = web.HTMLDivElement()
    ..className = alertClassName(variant: variant, className: className);
  if (role.isNotEmpty) root.setAttribute("role", role);
  for (final c in children) {
    root.appendChild(c);
  }
  return root;
}

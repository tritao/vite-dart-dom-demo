import "package:web/web.dart" as web;

enum SeparatorOrientation {
  horizontal,
  vertical,
}

/// Separator primitive (Radix-like).
///
/// - When `decorative=true`, sets `role="presentation"` + `aria-hidden="true"`.
/// - Otherwise uses `role="separator"` + `aria-orientation`.
web.HTMLElement Separator({
  SeparatorOrientation orientation = SeparatorOrientation.horizontal,
  bool decorative = true,
  String className = "separator",
}) {
  final el = web.HTMLDivElement()..className = className;

  final o = orientation == SeparatorOrientation.vertical ? "vertical" : "horizontal";
  el.setAttribute("data-orientation", o);

  if (decorative) {
    el.setAttribute("role", "presentation");
    el.setAttribute("aria-hidden", "true");
    el.removeAttribute("aria-orientation");
  } else {
    el.setAttribute("role", "separator");
    el.setAttribute("aria-orientation", o);
    el.removeAttribute("aria-hidden");
  }

  return el;
}

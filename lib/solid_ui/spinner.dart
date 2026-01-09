import "package:web/web.dart" as web;

/// Spinner primitive.
///
/// - Uses `role="status"` + `aria-live="polite"` by default so assistive tech
///   can announce a loading state when appropriate.
web.HTMLElement Spinner({
  String? ariaLabel,
  String className = "spinner",
}) {
  final el = web.HTMLSpanElement()
    ..className = className
    ..setAttribute("role", "status")
    ..setAttribute("aria-live", "polite");
  if (ariaLabel != null && ariaLabel.isNotEmpty) {
    el.setAttribute("aria-label", ariaLabel);
  } else {
    el.setAttribute("aria-label", "Loading");
  }
  return el;
}

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

/// Progress primitive (shadcn-ish).
///
/// - Uses `role="progressbar"`.
/// - Determinate: sets `aria-valuenow` and updates the indicator transform.
/// - Indeterminate: omit `value` (or return null) to get a looping indicator.
web.HTMLElement Progress({
  double? Function()? value,
  double Function()? max,
  String? ariaLabel,
  String rootClassName = "progress",
  String indicatorClassName = "progressIndicator",
}) {
  final valueAccessor = value ?? () => null;
  final maxAccessor = max ?? () => 100.0;

  final root = web.HTMLDivElement()
    ..className = rootClassName
    ..setAttribute("role", "progressbar");

  if (ariaLabel != null && ariaLabel.isNotEmpty) {
    root.setAttribute("aria-label", ariaLabel);
  }

  final indicator = web.HTMLDivElement()..className = indicatorClassName;
  root.appendChild(indicator);

  createRenderEffect(() {
    final mRaw = maxAccessor();
    final m = mRaw <= 0 ? 100.0 : mRaw;
    final vRaw = valueAccessor();

    if (vRaw == null) {
      root.setAttribute("data-state", "indeterminate");
      root.removeAttribute("aria-valuenow");
      root.setAttribute("aria-valuemin", "0");
      root.setAttribute("aria-valuemax", m.toString());
      indicator.style.removeProperty("transform");
      return;
    }

    final v = vRaw.clamp(0, m).toDouble();
    final pct = (v / m) * 100.0;

    root.setAttribute("data-state", "determinate");
    root.setAttribute("aria-valuenow", v.toStringAsFixed(0));
    root.setAttribute("aria-valuemin", "0");
    root.setAttribute("aria-valuemax", m.toString());
    // Use translateX for smoother animations without relayout.
    indicator.style.transform = "translateX(${pct - 100}%)";
  });

  return root;
}

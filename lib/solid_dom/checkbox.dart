import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./solid_dom.dart";

/// Checkbox primitive (Kobalte-like semantics).
///
/// - Uses `role="checkbox"` + `aria-checked` ("true" | "false" | "mixed").
/// - Supports indeterminate state (aria-checked="mixed").
/// - Keyboard: Enter/Space toggles.
/// - Click toggles.
web.HTMLElement Checkbox({
  required bool Function() checked,
  required void Function(bool next) setChecked,
  bool Function()? indeterminate,
  void Function(bool next)? setIndeterminate,
  bool Function()? disabled,
  String? id,
  String className = "checkbox",
  String? ariaLabel,
}) {
  final isDisabled = disabled ?? () => false;
  final isIndeterminate = indeterminate ?? () => false;

  final root = web.HTMLButtonElement()
    ..type = "button"
    ..id = id ?? ""
    ..className = className
    ..setAttribute("role", "checkbox");

  if (ariaLabel != null && ariaLabel.isNotEmpty) {
    root.setAttribute("aria-label", ariaLabel);
  }

  void toggle() {
    if (isDisabled()) return;
    if (isIndeterminate()) {
      setIndeterminate?.call(false);
      setChecked(true);
      return;
    }
    setChecked(!checked());
  }

  createRenderEffect(() {
    final mixed = isIndeterminate();
    final v = checked();
    root.setAttribute("aria-checked", mixed ? "mixed" : (v ? "true" : "false"));
    root.setAttribute(
      "data-state",
      mixed ? "indeterminate" : (v ? "checked" : "unchecked"),
    );
  });

  createRenderEffect(() {
    final d = isDisabled();
    if (d) {
      root.disabled = true;
      root.setAttribute("aria-disabled", "true");
      root.setAttribute("data-disabled", "true");
    } else {
      root.disabled = false;
      root.removeAttribute("aria-disabled");
      root.removeAttribute("data-disabled");
    }
  });

  on(root, "click", (_) => toggle());
  on(root, "keydown", (e) {
    if (e is! web.KeyboardEvent) return;
    if (e.key != "Enter" && e.key != " ") return;
    e.preventDefault();
    toggle();
  });

  return root;
}


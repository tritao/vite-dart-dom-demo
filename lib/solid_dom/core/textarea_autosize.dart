import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "./textarea.dart";
import "../solid_dom.dart";

/// Textarea autosize behavior (unstyled).
///
/// Adjusts the element height to fit content.
web.HTMLTextAreaElement createTextareaAutosize({
  String? id,
  String className = "",
  String? ariaLabel,
  String? placeholder,
  int? rows,
  int? cols,
  bool Function()? disabled,
  String? Function()? value,
  void Function(String next)? setValue,
  void Function(web.Event e, String currentValue)? onInput,
  void Function(web.Event e, String currentValue)? onChange,
  int? maxHeightPx,
}) {
  final el = createTextarea(
    id: id,
    className: className,
    ariaLabel: ariaLabel,
    placeholder: placeholder,
    rows: rows,
    cols: cols,
    disabled: disabled,
    value: value,
    setValue: setValue,
    onInput: onInput,
    onChange: onChange,
  );

  void resize() {
    try {
      el.style.height = "auto";
      final h = el.scrollHeight;
      if (maxHeightPx != null && h > maxHeightPx) {
        el.style.height = "${maxHeightPx}px";
        el.style.overflowY = "auto";
      } else {
        el.style.height = "${h}px";
        el.style.overflowY = "hidden";
      }
    } catch (_) {}
  }

  Timer? pending;
  void scheduleResize() {
    pending?.cancel();
    pending = Timer(const Duration(milliseconds: 0), resize);
  }

  on(el, "input", (_) => scheduleResize());

  // Resize on initial mount and whenever the controlled value changes.
  createRenderEffect(() {
    final _ = value?.call();
    scheduleMicrotask(resize);
  });

  onCleanup(() {
    pending?.cancel();
    pending = null;
  });

  return el;
}

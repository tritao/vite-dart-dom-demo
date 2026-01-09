import "dart:async";

import "package:dart_web_test/solid.dart";
import "package:dart_web_test/solid_dom/solid_dom.dart";
import "package:web/web.dart" as web;

/// Styled OTP input (Solidus UI skin).
///
/// Controlled: `value()` is the full OTP string (0..length chars).
web.HTMLElement InputOTP({
  required int length,
  required String Function() value,
  required void Function(String next) setValue,
  bool Function()? disabled,
  RegExp? allowedChar,
  String? inputPattern,
  String className = "otp",
  String inputClassName = "otpInput",
  String? ariaLabel,
}) {
  final isDisabled = disabled ?? () => false;
  final allowed = allowedChar ?? RegExp(r"[0-9]");
  final pattern = inputPattern ?? "[0-9]*";
  final inputs = <web.HTMLInputElement>[];

  String normalized(String raw) {
    final out = StringBuffer();
    for (final rune in raw.runes) {
      final ch = String.fromCharCode(rune);
      if (ch.trim().isEmpty) continue;
      if (!allowed.hasMatch(ch)) continue;
      out.write(ch);
      if (out.length >= length) break;
    }
    return out.toString();
  }

  void commitAt(int index, String nextChar) {
    final current = normalized(value());
    final chars = List<String>.filled(length, "");
    for (var i = 0; i < length; i++) {
      if (i < current.length) chars[i] = current[i];
    }
    chars[index] = nextChar;
    final next = normalized(chars.join());
    setValue(next);
  }

  void commitMany(int start, String pasted) {
    final raw = normalized(pasted);
    if (raw.isEmpty) return;
    final current = normalized(value());
    final chars = List<String>.filled(length, "");
    for (var i = 0; i < length; i++) {
      if (i < current.length) chars[i] = current[i];
    }
    var at = start;
    for (var i = 0; i < raw.length && at < length; i++, at++) {
      chars[at] = raw[i];
    }
    setValue(normalized(chars.join()));
    if (at < inputs.length) {
      scheduleMicrotask(() => inputs[at].focus());
    } else {
      scheduleMicrotask(() => inputs.last.focus());
    }
  }

  final root = web.HTMLDivElement()..className = className;
  if (ariaLabel != null && ariaLabel.isNotEmpty) {
    root.setAttribute("aria-label", ariaLabel);
  }

  for (var i = 0; i < length; i++) {
    final input = web.HTMLInputElement()
      ..type = "text"
      ..inputMode = "numeric"
      ..maxLength = 2
      ..className = inputClassName
      ..setAttribute("data-index", i.toString())
      ..setAttribute("autocomplete", "one-time-code");
    input.setAttribute("pattern", pattern);

    on(input, "keydown", (e) {
      if (e is! web.KeyboardEvent) return;
      if (isDisabled()) return;

      if (e.key == "Backspace") {
        e.preventDefault();
        final current = normalized(value());
        final hasChar = i < current.length && current[i].isNotEmpty;
        if (hasChar) {
          commitAt(i, "");
          scheduleMicrotask(() => inputs[i].focus());
        } else if (i > 0) {
          commitAt(i - 1, "");
          scheduleMicrotask(() => inputs[i - 1].focus());
        }
        return;
      }

      if (e.key == "ArrowLeft" && i > 0) {
        e.preventDefault();
        scheduleMicrotask(() => inputs[i - 1].focus());
        return;
      }
      if (e.key == "ArrowRight" && i < length - 1) {
        e.preventDefault();
        scheduleMicrotask(() => inputs[i + 1].focus());
        return;
      }
    });

    on(input, "input", (_) {
      if (isDisabled()) return;
      final raw = input.value;
      final v = normalized(raw);
      if (v.isEmpty) {
        if (raw.isNotEmpty) input.value = "";
        commitAt(i, "");
        return;
      }
      if (v.length > 1) {
        commitMany(i, v);
        return;
      }
      commitAt(i, v);
      if (i < length - 1) scheduleMicrotask(() => inputs[i + 1].focus());
    });

    on(input, "paste", (e) {
      if (isDisabled()) return;
      if (e is! web.ClipboardEvent) return;
      e.preventDefault();
      final data = e.clipboardData?.getData("text") ?? "";
      commitMany(i, data);
    });

    inputs.add(input);
    root.appendChild(input);
  }

  createRenderEffect(() {
    final v = normalized(value());
    for (var i = 0; i < inputs.length; i++) {
      final next = i < v.length ? v[i] : "";
      if (inputs[i].value != next) inputs[i].value = next;
      final d = isDisabled();
      inputs[i].disabled = d;
      if (d) {
        inputs[i].setAttribute("aria-disabled", "true");
        inputs[i].setAttribute("data-disabled", "true");
      } else {
        inputs[i].removeAttribute("aria-disabled");
        inputs[i].removeAttribute("data-disabled");
      }
    }
  });

  return root;
}

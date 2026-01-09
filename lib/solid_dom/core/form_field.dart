import "package:dart_web_test/solid.dart";
import "package:web/web.dart" as web;

import "../solid_dom.dart";

int _formFieldId = 0;
String _nextId(String prefix) {
  _formFieldId += 1;
  return "$prefix-$_formFieldId";
}

/// FormField primitive (unstyled).
///
/// Wires `label` + `description` + `error` to a control via `for` and
/// `aria-describedby`/`aria-invalid`.
web.HTMLElement createFormField({
  required web.HTMLElement control,
  String? Function()? label,
  String? Function()? description,
  String? Function()? error,
  String? id,
  String className = "",
  String labelClassName = "",
  String descriptionClassName = "",
  String messageClassName = "",
  String controlWrapClassName = "",
}) {
  final resolvedId = id ?? _nextId("solidus-field");

  if (control.id.isEmpty) {
    control.id = "$resolvedId-control";
  }

  final root = web.HTMLDivElement()..className = className;

  final labelEl = web.HTMLLabelElement()..className = labelClassName;
  labelEl.htmlFor = control.id;

  final descEl = web.HTMLParagraphElement()
    ..id = "$resolvedId-desc"
    ..className = descriptionClassName;

  final msgEl = web.HTMLParagraphElement()
    ..id = "$resolvedId-msg"
    ..className = messageClassName;

  final controlWrap = web.HTMLDivElement()..className = controlWrapClassName;
  controlWrap.appendChild(control);

  root.appendChild(labelEl);
  root.appendChild(controlWrap);
  root.appendChild(descEl);
  root.appendChild(msgEl);

  void syncDescribedBy({required bool hasDesc, required bool hasMsg}) {
    final parts = <String>[];
    final existing = control.getAttribute("aria-describedby");
    if (existing != null && existing.trim().isNotEmpty) {
      parts.addAll(existing.split(RegExp(r"\\s+")).where((p) => p.isNotEmpty));
    }

    parts.remove(descEl.id);
    parts.remove(msgEl.id);

    if (hasDesc) parts.add(descEl.id);
    if (hasMsg) parts.add(msgEl.id);

    if (parts.isEmpty) {
      control.removeAttribute("aria-describedby");
    } else {
      control.setAttribute("aria-describedby", parts.join(" "));
    }
  }

  createRenderEffect(() {
    final l = (label?.call() ?? "").trim();
    labelEl.textContent = l;
    if (l.isEmpty) {
      labelEl.setAttribute("hidden", "");
    } else {
      labelEl.removeAttribute("hidden");
    }
  });

  createRenderEffect(() {
    final d = (description?.call() ?? "").trim();
    descEl.textContent = d;
    if (d.isEmpty) {
      descEl.setAttribute("hidden", "");
    } else {
      descEl.removeAttribute("hidden");
    }

    final e = (error?.call() ?? "").trim();
    msgEl.textContent = e;
    if (e.isEmpty) {
      msgEl.setAttribute("hidden", "");
    } else {
      msgEl.removeAttribute("hidden");
    }

    final invalid = e.isNotEmpty;
    if (invalid) {
      control.setAttribute("aria-invalid", "true");
    } else {
      control.removeAttribute("aria-invalid");
    }

    syncDescribedBy(hasDesc: d.isNotEmpty, hasMsg: e.isNotEmpty);
  });

  return root;
}

import "package:web/web.dart" as web;

/// Label primitive (unstyled).
web.HTMLLabelElement createLabel({
  required String text,
  String? htmlFor,
  String className = "",
  bool required = false,
}) {
  final label = web.HTMLLabelElement()
    ..className = className
    ..textContent = text;

  if (htmlFor != null && htmlFor.isNotEmpty) {
    label.htmlFor = htmlFor;
  }
  if (required) {
    label.setAttribute("data-required", "true");
  }
  return label;
}


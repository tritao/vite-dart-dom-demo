import 'package:web/web.dart' as web;

T _apply<T extends web.Element>(
  T element, {
  String? id,
  String? className,
  String? text,
  Map<String, String>? attrs,
  List<web.Element>? children,
}) {
  if (id != null) element.setAttribute('id', id);
  if (className != null) element.setAttribute('class', className);
  if (text != null) element.textContent = text;
  if (attrs != null) {
    for (final entry in attrs.entries) {
      element.setAttribute(entry.key, entry.value);
    }
  }
  if (children != null) {
    for (final child in children) {
      element.append(child);
    }
  }
  return element;
}

web.HTMLDivElement div({
  String? id,
  String? className,
  Map<String, String>? attrs,
  List<web.Element>? children,
}) =>
    _apply(web.HTMLDivElement(),
        id: id, className: className, attrs: attrs, children: children);

web.HTMLDivElement row({
  String? className,
  List<web.Element>? children,
}) =>
    div(className: className == null ? 'row' : 'row $className', children: children);

web.HTMLParagraphElement p(
  String text, {
  String? className,
}) =>
    _apply(web.HTMLParagraphElement(), className: className, text: text);

web.HTMLParagraphElement muted(String text) => p(text, className: 'muted');

web.HTMLParagraphElement danger(String text) => p(text, className: 'muted error');

web.HTMLLIElement mutedLi(String text) => li(className: 'muted', text: text);

web.HTMLParagraphElement statusText({
  required String text,
  bool isError = false,
}) =>
    isError ? danger(text) : muted(text);

web.HTMLHeadingElement h1(
  String text, {
  String? className,
}) =>
    _apply(web.HTMLHeadingElement.h1(), className: className, text: text);

web.HTMLHeadingElement h2(
  String text, {
  String? className,
}) =>
    _apply(web.HTMLHeadingElement.h2(), className: className, text: text);

web.HTMLSpanElement span(
  String text, {
  String? className,
}) =>
    _apply(web.HTMLSpanElement(), className: className, text: text);

web.HTMLSpanElement textMuted(String text) => span(text, className: 'muted');

web.HTMLSpanElement textStrong(String text) => span(text, className: 'user');

web.HTMLUListElement ul({
  String? className,
  List<web.Element>? children,
}) =>
    _apply(web.HTMLUListElement(), className: className, children: children);

web.HTMLUListElement list({
  List<web.Element>? children,
}) =>
    ul(className: 'list', children: children);

web.HTMLLIElement li({
  String? className,
  String? text,
  Map<String, String>? attrs,
  List<web.Element>? children,
}) =>
    _apply(web.HTMLLIElement(),
        className: className, text: text, attrs: attrs, children: children);

web.HTMLLIElement item({
  Map<String, String>? attrs,
  List<web.Element>? children,
}) =>
    li(className: 'item', attrs: attrs, children: children);

web.HTMLInputElement inputText({
  String? id,
  String? className,
  String? placeholder,
  Map<String, String>? attrs,
}) {
  final input = web.HTMLInputElement()..type = 'text';
  if (placeholder != null) input.placeholder = placeholder;
  return _apply(input, id: id, className: className, attrs: attrs);
}

web.HTMLInputElement checkbox({
  bool checked = false,
  String? className,
  Map<String, String>? attrs,
}) {
  final input = web.HTMLInputElement()
    ..type = 'checkbox'
    ..checked = checked;
  return _apply(input, className: className, attrs: attrs);
}

web.HTMLButtonElement button(
  String label, {
  String kind = 'primary',
  bool disabled = false,
  String? action,
  int? dataId,
}) {
  final btn = web.HTMLButtonElement()
    ..type = 'button'
    ..textContent = label
    ..disabled = disabled
    ..className = 'btn $kind';
  if (action != null) btn.setAttribute('data-action', action);
  if (dataId != null) btn.setAttribute('data-id', '$dataId');
  return btn;
}

web.HTMLButtonElement actionButton(
  String label, {
  String kind = 'primary',
  bool disabled = false,
  required String action,
  int? dataId,
}) =>
    button(label,
        kind: kind,
        disabled: disabled,
        action: action,
        dataId: dataId);

web.HTMLButtonElement primaryButton(
  String label, {
  bool disabled = false,
  required String action,
  int? dataId,
}) =>
    actionButton(label, kind: 'primary', disabled: disabled, action: action, dataId: dataId);

web.HTMLButtonElement secondaryButton(
  String label, {
  bool disabled = false,
  required String action,
  int? dataId,
}) =>
    actionButton(label, kind: 'secondary', disabled: disabled, action: action, dataId: dataId);

web.HTMLButtonElement dangerButton(
  String label, {
  bool disabled = false,
  required String action,
  int? dataId,
}) =>
    actionButton(label, kind: 'danger', disabled: disabled, action: action, dataId: dataId);

web.HTMLInputElement actionCheckbox({
  bool checked = false,
  String? className,
  required String action,
  int? dataId,
  Map<String, String>? attrs,
}) {
  final merged = <String, String>{
    if (attrs != null) ...attrs,
    'data-action': action,
    if (dataId != null) 'data-id': '$dataId',
  };

  return checkbox(checked: checked, className: className, attrs: merged);
}

web.Element card({
  required String title,
  required List<web.Element> children,
}) {
  final cardEl = div(className: 'card');
  cardEl.append(h2(title));
  for (final child in children) {
    cardEl.append(child);
  }
  return cardEl;
}

web.Element section({
  required String title,
  String? subtitle,
  required List<web.Element> children,
}) {
  final cardEl = div(className: 'card');
  cardEl.append(h2(title));
  if (subtitle != null) {
    cardEl.append(p(subtitle, className: 'muted'));
  }
  for (final child in children) {
    cardEl.append(child);
  }
  return cardEl;
}

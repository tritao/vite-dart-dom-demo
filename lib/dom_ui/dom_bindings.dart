import 'package:web/web.dart' as web;

import './component.dart';
import './reactive.dart' as rx;

void bindText(
  Component component,
  String key,
  web.Element element,
  String Function() compute,
) {
  final handleRef = component.useRef<rx.EffectHandle?>('bindText:$key', null);
  rx.EffectFn fn = () {
    element.textContent = compute();
    return null;
  };

  final existing = handleRef.value;
  if (existing == null) {
    final handle = rx.effect(fn);
    handleRef.value = handle;
    component.addCleanup(handle.dispose);
    return;
  }

  existing.update(fn, runNow: true);
}

void bindDisabled(
  Component component,
  String key,
  web.HTMLButtonElement button,
  bool Function() compute,
) {
  final handleRef =
      component.useRef<rx.EffectHandle?>('bindDisabled:$key', null);
  rx.EffectFn fn = () {
    button.disabled = compute();
    return null;
  };

  final existing = handleRef.value;
  if (existing == null) {
    final handle = rx.effect(fn);
    handleRef.value = handle;
    component.addCleanup(handle.dispose);
    return;
  }

  existing.update(fn, runNow: true);
}

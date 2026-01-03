import 'package:web/web.dart' as web;

web.Element? eventTargetElement(web.Event event) {
  final target = event.target;
  if (target == null) return null;
  try {
    return target as web.Element;
  } catch (_) {
    return null;
  }
}

web.Element? closestActionElement(web.Event event) {
  final target = eventTargetElement(event);
  if (target == null) return null;
  return target.closest('[data-action]');
}

String? actionNameFromEvent(web.Event event) {
  final el = closestActionElement(event);
  return el?.getAttribute('data-action');
}

int? actionIdFromElement(web.Element element) {
  final raw = element.getAttribute('data-id');
  if (raw == null) return null;
  return int.tryParse(raw);
}

int? actionIdFromEvent(web.Event event) {
  final el = closestActionElement(event);
  if (el == null) return null;
  return actionIdFromElement(el);
}

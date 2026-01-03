import 'package:web/web.dart' as web;

import './events.dart' as events;

typedef ActionHandler = void Function(web.Element? actionElement);

void dispatchAction(
  web.Event event,
  Map<String, ActionHandler> handlers,
) {
  final actionEl = events.closestActionElement(event);
  final action = actionEl?.getAttribute('data-action');
  if (action == null) return;

  final handler = handlers[action];
  if (handler == null) return;

  handler(actionEl);
}

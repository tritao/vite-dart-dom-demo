import 'package:web/web.dart' as web;

import 'package:dart_web_test/vite_ui/component.dart';
import 'package:dart_web_test/vite_ui/action_dispatch.dart';
import 'package:dart_web_test/vite_ui/dom.dart' as dom;

abstract final class _CounterActions {
  static const dec = 'counter-dec';
  static const inc = 'counter-inc';
  static const reset = 'counter-reset';
}

final class CounterComponent extends Component {
  CounterComponent();

  int counter = 0;

  @override
  web.Element render() {
    return dom.section(
      title: 'Counter',
      subtitle: 'Exercises state updates and re-rendering.',
      children: [
        dom.p('$counter', className: 'big'),
        dom.row(children: [
          dom.actionButton('−1', action: _CounterActions.dec),
          dom.actionButton('+1', action: _CounterActions.inc),
          dom.actionButton('Reset',
              kind: 'secondary', action: _CounterActions.reset),
        ]),
      ],
    );
  }

  @override
  void onMount() {
    listen(root.onClick, _onClick);
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      _CounterActions.dec: (_) => setState(() => counter--),
      _CounterActions.inc: (_) => setState(() => counter++),
      _CounterActions.reset: (_) => setState(() => counter = 0),
    });
  }
}

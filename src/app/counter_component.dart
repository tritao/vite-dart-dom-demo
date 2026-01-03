import 'package:web/web.dart' as web;

import 'package:dart_web_test/dom_ui/component.dart';
import 'package:dart_web_test/dom_ui/action_dispatch.dart';
import 'package:dart_web_test/dom_ui/dom.dart' as dom;

abstract final class CounterDomActions {
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
          dom.actionButton('−1', action: CounterDomActions.dec),
          dom.actionButton('+1', action: CounterDomActions.inc),
          dom.secondaryButton('Reset', action: CounterDomActions.reset),
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
      CounterDomActions.dec: (_) => setState(() => counter--),
      CounterDomActions.inc: (_) => setState(() => counter++),
      CounterDomActions.reset: (_) => setState(() => counter = 0),
    });
  }
}

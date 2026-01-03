import 'package:web/web.dart' as web;

import 'package:dart_web_test/dom_ui/action_dispatch.dart';
import 'package:dart_web_test/dom_ui/component.dart';
import 'package:dart_web_test/dom_ui/dom.dart' as dom;
import 'package:dart_web_test/dom_ui/dom_bindings.dart' as bind;
import 'package:dart_web_test/dom_ui/reactive.dart' as rx;

abstract final class CounterDomActions {
  static const dec = 'counter-dec';
  static const inc = 'counter-inc';
  static const reset = 'counter-reset';
}

final class CounterComponent extends Component {
  CounterComponent();

  int get count => _countSignal.value;

  set count(int value) => _countSignal.value = value;

  rx.Signal<int> get _countSignal => useSignal<int>('count', 0);

  @override
  web.Element render() {
    final countEl = dom.p('', className: 'big');
    bind.bindText(this, 'countText', countEl, () => '$count');

    return dom.section(
      title: 'Counter',
      subtitle: 'Exercises state updates and re-rendering.',
      children: [
        countEl,
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
      CounterDomActions.dec: (_) => count = count - 1,
      CounterDomActions.inc: (_) => count = count + 1,
      CounterDomActions.reset: (_) => count = 0,
    });
  }
}

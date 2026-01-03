import 'package:web/web.dart' as web;

import './app/counter_component.dart';
import './app/todos_component.dart';
import './app/users_component.dart';
import './ui/component.dart';
import './ui/dom.dart' as dom;

abstract final class _AppActions {
  static const toggleUsersEndpoint = 'app-toggle-users-endpoint';
}

void main() {
  final mount = web.document.querySelector('#app');
  if (mount == null) return;

  AppComponent(
    counter: CounterComponent(),
    todos: TodosComponent(),
    users: UsersComponent(),
  ).mountInto(mount);
}

final class AppComponent extends Component {
  AppComponent({
    required this.counter,
    required this.todos,
    required this.users,
  });

  final CounterComponent counter;
  final TodosComponent todos;
  final UsersComponent users;

  @override
  void onMount() {
    counter.mountInto(root.querySelector('#counter-root')!);
    todos.mountInto(root.querySelector('#todos-root')!);
    users.mountInto(root.querySelector('#users-root')!);
    listen(root.onClick, _onClick);
  }

  void _onClick(web.MouseEvent event) {
    final target = event.target;
    if (target == null) return;
    web.Element? targetEl;
    try {
      targetEl = target as web.Element;
    } catch (_) {
      return;
    }

    final actionEl =
        targetEl.closest('[data-action="${_AppActions.toggleUsersEndpoint}"]');
    if (actionEl == null) return;

    const full = 'https://jsonplaceholder.typicode.com/users';
    const limited = 'https://jsonplaceholder.typicode.com/users?_limit=5';

    users.update(() {
      users.endpoint = users.endpoint == full ? limited : full;
    });
  }

  @override
  web.Element render() {
    return dom.div(id: 'app-root', className: 'container', children: [
      dom.div(className: 'header', children: [
        dom.h1('Dart + Vite (DOM demo)'),
        dom.p(
          'Counter + Todos (localStorage) + Fetch (async) to validate the integration.',
          className: 'muted',
        ),
        dom.div(className: 'row', children: [
          dom.button(
            'Toggle users endpoint',
            kind: 'secondary',
            action: _AppActions.toggleUsersEndpoint,
          ),
        ]),
      ]),
      dom.div(id: 'counter-root'),
      dom.div(className: 'spacer'),
      dom.div(id: 'todos-root'),
      dom.div(className: 'spacer'),
      dom.div(id: 'users-root'),
    ]);
  }
}

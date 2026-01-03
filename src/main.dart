import 'package:web/web.dart' as web;

import './app/counter_component.dart';
import './app/todos_component.dart';
import './app/users_component.dart';
import './ui/component.dart';
import './ui/action_dispatch.dart';
import './ui/dom.dart' as dom;
import './ui/events.dart' as events;

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
    mountChild(counter, root.querySelector('#counter-root')!);
    mountChild(todos, root.querySelector('#todos-root')!);
    mountChild(users, root.querySelector('#users-root')!);
    listen(root.onClick, _onClick);
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      _AppActions.toggleUsersEndpoint: (_) {
        const full = 'https://jsonplaceholder.typicode.com/users';
        const limited = 'https://jsonplaceholder.typicode.com/users?_limit=5';
        users.setEndpoint(users.endpoint == full ? limited : full);
      }
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
        dom.row(children: [
          dom.actionButton(
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

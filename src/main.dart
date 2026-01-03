import 'package:web/web.dart' as web;

import './app/app_component.dart';
import './app/counter_component.dart';
import './app/todos_component.dart';
import './app/users_component.dart';

void main() {
  final mount = web.document.querySelector('#app');
  if (mount == null) return;

  AppComponent(
    counter: CounterComponent(),
    todos: TodosComponent(),
    usersFactory: () => UsersComponent(),
  ).mountInto(mount);
}

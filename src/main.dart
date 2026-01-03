import 'package:web/web.dart' as web;

import './app/app_component.dart';
import './app/counter_component.dart';
import './app/todos_component.dart';
import './app/users_component.dart';
import './solid_dom_demo.dart';
import './solid_overlay_demo.dart';

void main() {
  final mount = web.document.querySelector('#app');
  if (mount == null) return;

  final search = web.window.location.search;
  if (search.contains('solid=overlay')) {
    mountSolidOverlayDemo(mount);
    return;
  }
  if (search.contains('solid=1')) {
    mountSolidDomDemo(mount);
    return;
  }

  AppComponent(
    counter: CounterComponent(),
    todos: TodosComponent(),
    usersFactory: () => UsersComponent(),
  ).mountInto(mount);
}

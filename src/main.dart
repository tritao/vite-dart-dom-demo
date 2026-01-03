import 'package:web/web.dart' as web;

import './app/app_component.dart';
import './app/counter_component.dart';
import './app/todos_component.dart';
import './app/users_component.dart';
import './solid_dom_demo.dart';
import './solid_overlay_demo.dart';
import './solid_dialog_demo.dart';
import './solid_popover_demo.dart';
import './solid_roving_demo.dart';
import './solid_toast_demo.dart';
import './solid_menu_demo.dart';

void main() {
  final mount = web.document.querySelector('#app');
  if (mount == null) return;

  final search = web.window.location.search;
  if (search.contains('solid=overlay')) {
    mountSolidOverlayDemo(mount);
    return;
  }
  if (search.contains('solid=dialog')) {
    mountSolidDialogDemo(mount);
    return;
  }
  if (search.contains('solid=popover')) {
    mountSolidPopoverDemo(mount);
    return;
  }
  if (search.contains('solid=roving')) {
    mountSolidRovingDemo(mount);
    return;
  }
  if (search.contains('solid=toast')) {
    mountSolidToastDemo(mount);
    return;
  }
  if (search.contains('solid=menu')) {
    mountSolidMenuDemo(mount);
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

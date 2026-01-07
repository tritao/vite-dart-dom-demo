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
import './solid_context_menu_demo.dart';
import './solid_tooltip_demo.dart';
import './solid_select_demo.dart';
import './solid_combobox_demo.dart';
import './solid_listbox_demo.dart';
import './solid_selection_demo.dart';
import 'package:dart_web_test/wordproc/wordproc.dart';
import './solid_nesting_demo.dart';
import './solid_toast_modal_demo.dart';
import './solid_optionbuilder_demo.dart';

void main() {
  final mount = web.document.querySelector('#app');
  if (mount == null) return;

  final search = web.window.location.search;
  final query = search.startsWith("?") ? search.substring(1) : search;
  final solid = Uri.splitQueryString(query)["solid"];

  if (solid == 'overlay') {
    mountSolidOverlayDemo(mount);
    return;
  }
  if (solid == 'dialog') {
    mountSolidDialogDemo(mount);
    return;
  }
  if (solid == 'popover') {
    mountSolidPopoverDemo(mount);
    return;
  }
  if (solid == 'roving') {
    mountSolidRovingDemo(mount);
    return;
  }
  if (solid == 'toast') {
    mountSolidToastDemo(mount);
    return;
  }
  if (solid == 'menu') {
    mountSolidMenuDemo(mount);
    return;
  }
  if (solid == 'contextmenu') {
    mountSolidContextMenuDemo(mount);
    return;
  }
  if (solid == 'tooltip') {
    mountSolidTooltipDemo(mount);
    return;
  }
  if (solid == 'select') {
    mountSolidSelectDemo(mount);
    return;
  }
  if (solid == 'combobox') {
    mountSolidComboboxDemo(mount);
    return;
  }
  if (solid == 'listbox') {
    mountSolidListboxDemo(mount);
    return;
  }
  if (solid == 'selection') {
    mountSolidSelectionDemo(mount);
    return;
  }
  if (solid == 'wordproc') {
    mountSolidWordprocShellDemo(mount);
    return;
  }
  if (solid == 'nesting') {
    mountSolidNestingDemo(mount);
    return;
  }
  if (solid == 'toast-modal') {
    mountSolidToastModalDemo(mount);
    return;
  }
  if (solid == 'optionbuilder') {
    mountSolidOptionBuilderDemo(mount);
    return;
  }
  if (solid == '1') {
    mountSolidDomDemo(mount);
    return;
  }

  AppComponent(
    counter: CounterComponent(),
    todos: TodosComponent(),
    usersFactory: () => UsersComponent(),
  ).mountInto(mount);
}

import 'package:web/web.dart' as web;

import './app/app_component.dart';
import './app/counter_component.dart';
import './app/intro_component.dart';
import './app/todos_component.dart';
import './app/users_component.dart';
import './docs/router.dart';
import './solid/dom_demo.dart';
import './solid/overlay_demo.dart';
import './solid/dialog_demo.dart';
import './solid/popover_demo.dart';
import './solid/roving_demo.dart';
import './solid/toast_demo.dart';
import './solid/catalog_demo.dart';
import './solid/dropdown_menu_demo.dart';
import './solid/menubar_demo.dart';
import './solid/context_menu_demo.dart';
import './solid/tooltip_demo.dart';
import './solid/select_demo.dart';
import './solid/combobox_demo.dart';
import './solid/listbox_demo.dart';
import './solid/selection_demo.dart';
import './solid/tabs_demo.dart';
import './solid/accordion_demo.dart';
import './solid/switch_demo.dart';
import './solid/nesting_demo.dart';
import './solid/toast_modal_demo.dart';
import './solid/optionbuilder_demo.dart';
import 'package:dart_web_test/dom_ui/theme.dart' as theme;

void main() {
  final mount = web.document.querySelector('#app');
  if (mount == null) return;

  theme.initTheme();

  final search = web.window.location.search;
  final query = search.startsWith("?") ? search.substring(1) : search;
  final params = Uri.splitQueryString(query);
  final docs = params["docs"];
  final solid = params["solid"];
  final demos = params["demos"];

  if (docs != null) {
    mountSolidDocs(mount, docs);
    return;
  }

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
  if (solid == 'catalog') {
    mountSolidCatalogDemo(mount);
    return;
  }
  if (solid == 'dropdownmenu') {
    mountSolidDropdownMenuDemo(mount);
    return;
  }
  if (solid == 'menubar') {
    mountSolidMenubarDemo(mount);
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
  if (solid == 'tabs') {
    mountSolidTabsDemo(mount);
    return;
  }
  if (solid == 'accordion') {
    mountSolidAccordionDemo(mount);
    return;
  }
  if (solid == 'switch') {
    mountSolidSwitchDemo(mount);
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

  if (demos == "1" || demos == "true") {
    AppComponent(
      counter: CounterComponent(),
      todos: TodosComponent(),
      usersFactory: () => UsersComponent(),
    ).mountInto(mount);
    return;
  }

  IntroComponent().mountInto(mount);
}

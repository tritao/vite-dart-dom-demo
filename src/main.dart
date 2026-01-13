import 'package:web/web.dart' as web;

import './app/app_component.dart';
import './app/counter_component.dart';
import './app/backend_playground_component.dart';
import './app/intro_component.dart';
import './app/todos_component.dart';
import './app/users_component.dart';
import 'package:solidus/dom_ui/theme.dart' as theme;

void main() {
  final mount = web.document.querySelector('#app');
  if (mount == null) return;

  theme.initTheme();

  final search = web.window.location.search;
  final query = search.startsWith("?") ? search.substring(1) : search;
  final params = Uri.splitQueryString(query);
  final docs = params["docs"];
  final lab = params["lab"];
  final demos = params["demos"];
  final backend = params["backend"];

  // Split bundles: redirect to dedicated entrypoints for docs/labs.
  if (docs != null) {
    web.window.location.assign("docs.html$search");
    return;
  }
  if (lab != null) {
    web.window.location.assign("labs.html$search");
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

  if (backend == "1" || backend == "true") {
    BackendPlaygroundComponent().mountInto(mount);
    return;
  }

  IntroComponent().mountInto(mount);
}

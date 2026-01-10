import 'package:web/web.dart' as web;

import 'package:solidus/dom_ui/action_dispatch.dart';
import 'package:solidus/dom_ui/component.dart';
import 'package:solidus/dom_ui/dom.dart' as dom;

import './config.dart';
import './counter_component.dart';
import './route.dart' as route;
import './todos_component.dart';
import './users_component.dart';
import './users_state.dart';

abstract final class AppDomActions {
  static const toggleUsersEndpoint = 'app-toggle-users-endpoint';
  static const toggleUsersVisible = 'app-toggle-users-visible';
}

final class AppComponent extends Component {
  AppComponent({
    required this.counter,
    required this.todos,
    required this.usersFactory,
  });

  final CounterComponent counter;
  final TodosComponent todos;
  final UsersComponent Function() usersFactory;

  UsersComponent? _users;
  String _usersEndpoint = UsersState.usersAll;
  bool _showUsers = false;

  @override
  void onMount() {
    provide<AppConfig>(
      AppConfig.contextKey,
      const AppConfig(
        usersAll: UsersState.usersAll,
        usersLimited: UsersState.usersLimited,
      ),
    );

    mountChild(counter, queryOrThrow<web.Element>('#counter-root'));
    mountChild(todos, queryOrThrow<web.Element>('#todos-root'));
    _applyRoute();
    listen(root.onClick, _onClick);
    listen(web.window.onPopState, (_) => _applyRoute());
  }

  void _applyRoute() {
    final config = useContext<AppConfig>(AppConfig.contextKey);
    final state = route.readRoute(config);
    final endpoint = state.usersEndpoint;
    final showUsers = state.showUsers;

    if (endpoint != _usersEndpoint) {
      _usersEndpoint = endpoint;
      final users = _users;
      if (users != null) users.setEndpoint(endpoint);
    }

    final usersMount = queryOrThrow<web.Element>('#users-root');
    if (!showUsers) {
      _showUsers = false;
      final users = _users;
      if (users != null) {
        unmountChild(users);
        usersMount.textContent = '';
        _users = null;
      }
      invalidate();
      return;
    }

    _showUsers = true;

    final existing = _users;
    if (existing != null) {
      existing.setEndpoint(_usersEndpoint);
      invalidate();
      return;
    }

    final users = usersFactory()..setEndpoint(_usersEndpoint);
    _users = users;
    usersMount.textContent = '';
    mountChild(users, usersMount);
    invalidate();
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      AppDomActions.toggleUsersEndpoint: (_) => _toggleUsersEndpoint(),
      AppDomActions.toggleUsersVisible: (_) => _toggleUsersVisible(),
    });
  }

  void _toggleUsersEndpoint() {
    final config = useContext<AppConfig>(AppConfig.contextKey);
    final next = _usersEndpoint == config.usersAll ? 'limited' : 'all';
    route.setUsersMode(next);
    _applyRoute();
  }

  void _toggleUsersVisible() {
    route.setShowUsers(!_showUsers);
    _applyRoute();
  }

  @override
  web.Element render() {
    return dom.div(id: 'app-root', className: 'container', children: [
      dom.header(
        title: 'Dart + Vite (DOM demo)',
        subtitle:
            'Counter + Todos (localStorage) + Fetch (async) to validate the integration.',
        actions: [
          dom.linkButton('Home', href: './'),
          dom.linkButton('Docs', href: 'docs.html#/'),
          dom.linkButton('Labs', href: 'labs.html?lab=catalog'),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Solidus labs demos',
        subtitle:
            'Quick links to the Solidus DOM demos (query-based routes).',
        children: [
          dom.spacer(),
          dom.row(children: [
            dom.linkButton('Demos', href: '?demos=1'),
            dom.linkButton('Docs', href: 'docs.html#/'),
            dom.linkButton('Catalog', href: 'labs.html?lab=catalog'),
            dom.linkButton('DropdownMenu', href: 'labs.html?lab=dropdownmenu'),
            dom.linkButton('Menubar', href: 'labs.html?lab=menubar'),
            dom.linkButton('ContextMenu', href: 'labs.html?lab=contextmenu'),
            dom.linkButton('Dialog', href: 'labs.html?lab=dialog'),
            dom.linkButton('Popover', href: 'labs.html?lab=popover'),
            dom.linkButton('Tooltip', href: 'labs.html?lab=tooltip'),
            dom.linkButton('Select', href: 'labs.html?lab=select'),
            dom.linkButton('Listbox', href: 'labs.html?lab=listbox'),
            dom.linkButton('Combobox', href: 'labs.html?lab=combobox'),
            dom.linkButton('Tabs', href: 'labs.html?lab=tabs'),
            dom.linkButton('Accordion', href: 'labs.html?lab=accordion'),
            dom.linkButton('Switch', href: 'labs.html?lab=switch'),
            dom.linkButton('Selection', href: 'labs.html?lab=selection'),
            dom.linkButton('Toast', href: 'labs.html?lab=toast'),
            dom.linkButton('Toast+Modal', href: 'labs.html?lab=toast-modal'),
            dom.linkButton('Roving', href: 'labs.html?lab=roving'),
            dom.linkButton('Overlay', href: 'labs.html?lab=overlay'),
            dom.linkButton('Nesting', href: 'labs.html?lab=nesting'),
            dom.linkButton('OptionBuilder', href: 'labs.html?lab=optionbuilder'),
            dom.linkButton('DOM', href: 'labs.html?lab=dom'),
          ]),
        ],
      ),
      dom.spacer(),
      dom.mountPoint('counter-root'),
      dom.spacer(),
      dom.mountPoint('todos-root'),
      dom.spacer(),
      dom.section(
        title: 'Users demo',
        subtitle: 'Fetch demo to validate async + routing.',
        children: [
          dom.spacer(),
          dom.row(children: [
            dom.secondaryButton(
              'Toggle users endpoint',
              action: AppDomActions.toggleUsersEndpoint,
            ),
            dom.secondaryButton(
              _showUsers ? 'Hide users' : 'Show users',
              action: AppDomActions.toggleUsersVisible,
            ),
          ]),
          dom.spacer(),
          dom.mountPoint('users-root'),
        ],
      ),
    ]);
  }
}

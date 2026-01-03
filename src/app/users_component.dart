import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import './user.dart';
import 'package:dart_web_test/vite_ui/component.dart';
import 'package:dart_web_test/vite_ui/action_dispatch.dart';
import 'package:dart_web_test/vite_ui/dom.dart' as dom;

abstract final class _UsersActions {
  static const load = 'users-load';
  static const clear = 'users-clear';
}

sealed class _UsersAction {
  const _UsersAction();
}

final class _UsersStartLoad extends _UsersAction {
  const _UsersStartLoad();
}

final class _UsersLoaded extends _UsersAction {
  const _UsersLoaded(this.users);
  final List<User> users;
}

final class _UsersFailed extends _UsersAction {
  const _UsersFailed(this.message);
  final String message;
}

final class _UsersClear extends _UsersAction {
  const _UsersClear();
}

final class _UsersSetEndpoint extends _UsersAction {
  const _UsersSetEndpoint(this.endpoint);
  final String endpoint;
}

final class _UsersState {
  const _UsersState({
    required this.endpoint,
    required this.isLoading,
    required this.error,
    required this.users,
  });

  final String endpoint;
  final bool isLoading;
  final String? error;
  final List<User> users;

  static const usersAll = 'https://jsonplaceholder.typicode.com/users';
  static const usersLimited =
      'https://jsonplaceholder.typicode.com/users?_limit=5';

  factory _UsersState.initial() => const _UsersState(
        endpoint: usersAll,
        isLoading: false,
        error: null,
        users: [],
      );
}

final class UsersComponent extends Component {
  static const usersAll = _UsersState.usersAll;
  static const usersLimited = _UsersState.usersLimited;

  UsersComponent({
    String title = 'Fetch (async)',
    String endpoint = _UsersState.usersAll,
  }) : _title = title {
    _store.dispatch(_UsersSetEndpoint(endpoint));
  }

  String _title;

  String get title => _title;
  String get endpoint => _store.state.endpoint;

  void setTitle(String value) => update(() => _title = value);

  void setEndpoint(String value) => _store.dispatch(_UsersSetEndpoint(value));

  ReducerHandle<_UsersState, _UsersAction> get _store =>
      useReducer<_UsersState, _UsersAction>(
        'users',
        _UsersState.initial(),
        _reduce,
      );

  bool get canClear => !_store.state.isLoading && _store.state.users.isNotEmpty;

  String get endpointLabel => 'Endpoint: ${_store.state.endpoint}';

  String get statusText => switch (_store.state) {
        _UsersState(isLoading: true) => 'Loading users…',
        _UsersState(error: final e?) => e,
        _UsersState(users: final u) when u.isEmpty =>
          'Click “Load users” to fetch JSON from the network.',
        _UsersState(users: final u) => 'Loaded ${u.length} users.',
      };

  @override
  web.Element render() {
    final requestToken = useRef<int>('requestToken', 0);
    final lastEndpoint = useRef<String?>('lastEndpoint', null);

    useEffect('endpoint', [_store.state.endpoint], () {
      final previous = lastEndpoint.value;
      lastEndpoint.value = _store.state.endpoint;
      if (previous != null && previous != _store.state.endpoint) {
        requestToken.value++;
        _store.dispatch(const _UsersClear());
      }
      return null;
    });

    final status =
        _store.state.error != null ? dom.danger(statusText) : dom.muted(statusText);

    final row = dom.row(children: [
      dom.actionButton(
        _store.state.isLoading ? 'Loading…' : 'Load users',
        disabled: _store.state.isLoading,
        action: _UsersActions.load,
      ),
      dom.actionButton(
        'Clear',
        kind: 'secondary',
        disabled: !canClear,
        action: _UsersActions.clear,
      ),
    ]);

    final users = _store.state.users;

    final userRows = useMemo<List<(String, String)>>(
      'userRows',
      [users],
      () => users.map((u) => (u.name, u.email)).toList(growable: false),
    );

    final list = dom.list(
      children: userRows.map((row) {
        final (name, email) = row;
        return dom.item(children: [
          dom.textStrong(name),
          if (email.isNotEmpty) dom.textMuted(' • $email'),
        ]);
      }).toList(growable: false),
    );

    return dom.section(
      title: _title,
      children: [
        row,
        status,
        if (users.isNotEmpty) list,
        dom.muted(endpointLabel),
      ],
    );
  }

  @override
  void onMount() {
    listen(root.onClick, _onClick);
  }

  @override
  void onDispose() {
    useRef<int>('requestToken', 0).value++;
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      _UsersActions.load: (_) => _loadUsers(),
      _UsersActions.clear: (_) => _store.dispatch(const _UsersClear()),
    });
  }

  Future<void> _loadUsers() async {
    final requestToken = useRef<int>('requestToken', 0);
    final token = ++requestToken.value;
    _store.dispatch(const _UsersStartLoad());

    try {
      final response = await http.get(
        Uri.parse(_store.state.endpoint),
      );
      if (!isMounted || token != requestToken.value) return;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw FormatException('Unexpected response shape');

      final users = decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(User.fromJson)
          .toList(growable: false);

      _store.dispatch(_UsersLoaded(users));
    } catch (e) {
      if (!isMounted || token != requestToken.value) return;
      _store.dispatch(_UsersFailed('Failed to load users: $e'));
    }
  }

  static _UsersState _reduce(_UsersState state, _UsersAction action) {
    switch (action) {
      case _UsersSetEndpoint(:final endpoint):
        return _UsersState(
          endpoint: endpoint,
          isLoading: false,
          error: null,
          users: const [],
        );
      case _UsersStartLoad():
        return _UsersState(
          endpoint: state.endpoint,
          isLoading: true,
          error: null,
          users: state.users,
        );
      case _UsersLoaded(:final users):
        return _UsersState(
          endpoint: state.endpoint,
          isLoading: false,
          error: null,
          users: users,
        );
      case _UsersFailed(:final message):
        return _UsersState(
          endpoint: state.endpoint,
          isLoading: false,
          error: message,
          users: const [],
        );
      case _UsersClear():
        return _UsersState(
          endpoint: state.endpoint,
          isLoading: false,
          error: null,
          users: const [],
        );
    }
  }
}

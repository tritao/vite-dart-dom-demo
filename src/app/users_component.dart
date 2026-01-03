import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import './user.dart';
import './users_state.dart';
import 'package:dart_web_test/vite_ui/component.dart';
import 'package:dart_web_test/vite_ui/action_dispatch.dart';
import 'package:dart_web_test/vite_ui/dom.dart' as dom;

abstract final class _UsersDomActions {
  static const load = 'users-load';
  static const clear = 'users-clear';
}

final class UsersComponent extends Component {
  static const usersAll = UsersState.usersAll;
  static const usersLimited = UsersState.usersLimited;

  UsersComponent({
    String title = 'Fetch (async)',
    String endpoint = UsersState.usersAll,
  }) : _title = title {
    _store.dispatch(UsersSetEndpoint(endpoint));
  }

  String _title;

  String get title => _title;
  String get endpoint => _store.state.endpoint;

  void setTitle(String value) => update(() => _title = value);

  void setEndpoint(String value) => _store.dispatch(UsersSetEndpoint(value));

  ReducerHandle<UsersState, UsersAction> get _store =>
      useReducer<UsersState, UsersAction>(
        'users',
        UsersState.initial(),
        usersReducer,
      );

  bool get canClear => !_store.state.isLoading && _store.state.users.isNotEmpty;

  String get endpointLabel => 'Endpoint: ${_store.state.endpoint}';

  String get statusText => switch (_store.state) {
        UsersState(isLoading: true) => 'Loading users…',
        UsersState(error: final e?) => e,
        UsersState(users: final u) when u.isEmpty =>
          'Click “Load users” to fetch JSON from the network.',
        UsersState(users: final u) => 'Loaded ${u.length} users.',
      };

  @override
  web.Element render() {
    final status = _buildStatus();
    final controls = _buildControls();
    final list = _buildList();

    final requestToken = useRef<int>('requestToken', 0);
    final lastEndpoint = useRef<String?>('lastEndpoint', null);

    useEffect('endpoint', [_store.state.endpoint], () {
      final previous = lastEndpoint.value;
      lastEndpoint.value = _store.state.endpoint;
      if (previous != null && previous != _store.state.endpoint) {
        requestToken.value++;
        _store.dispatch(const UsersClear());
      }
      return null;
    });

    return dom.section(
      title: _title,
      children: [
        controls,
        status,
        if (_store.state.users.isNotEmpty) list,
        dom.muted(endpointLabel),
      ],
    );
  }

  web.Element _buildStatus() => dom.statusText(
        text: statusText,
        isError: _store.state.error != null,
      );

  web.Element _buildControls() => dom.row(children: [
        dom.actionButton(
          _store.state.isLoading ? 'Loading…' : 'Load users',
          disabled: _store.state.isLoading,
          action: _UsersDomActions.load,
        ),
        dom.secondaryButton(
          'Clear',
          disabled: !canClear,
          action: _UsersDomActions.clear,
        ),
      ]);

  web.Element _buildList() {
    final users = _store.state.users;
    final userRows = useMemo<List<(String, String)>>(
      'userRows',
      [users],
      () => users.map((u) => (u.name, u.email)).toList(growable: false),
    );
    return dom.list(
      children: userRows.map((row) {
        final (name, email) = row;
        return dom.item(children: [
          dom.textStrong(name),
          if (email.isNotEmpty) dom.textMuted(' • $email'),
        ]);
      }).toList(growable: false),
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
      _UsersDomActions.load: (_) => _loadUsers(),
      _UsersDomActions.clear: (_) => _store.dispatch(const UsersClear()),
    });
  }

  Future<void> _loadUsers() async {
    final requestToken = useRef<int>('requestToken', 0);
    final token = ++requestToken.value;
    _store.dispatch(const UsersStartLoad());

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

      _store.dispatch(UsersLoaded(users));
    } catch (e) {
      if (!isMounted || token != requestToken.value) return;
      _store.dispatch(UsersFailed('Failed to load users: $e'));
    }
  }
}

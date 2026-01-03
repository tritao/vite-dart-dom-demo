import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../ui/component.dart';
import '../ui/action_dispatch.dart';
import '../ui/dom.dart' as dom;
import '../ui/events.dart' as events;

abstract final class _UsersActions {
  static const load = 'users-load';
  static const clear = 'users-clear';
}

final class UsersComponent extends Component {
  UsersComponent({
    String title = 'Fetch (async)',
    String endpoint = 'https://jsonplaceholder.typicode.com/users',
  })  : _title = title,
        _endpoint = endpoint;

  String _title;
  String _endpoint;

  String get title => _title;
  String get endpoint => _endpoint;

  void setTitle(String value) => update(() => _title = value);

  void setEndpoint(String value) => update(() => _endpoint = value);

  bool _isLoading = false;
  String? _error;
  List<Map<String, Object?>> _users = const [];

  bool get canClear => !_isLoading && _users.isNotEmpty;

  String get endpointLabel => 'Endpoint: $_endpoint';

  String get statusText {
    if (_isLoading) return 'Loading users…';
    if (_error != null) return _error!;
    if (_users.isEmpty) return 'Click “Load users” to fetch JSON from the network.';
    return 'Loaded ${_users.length} users.';
  }

  @override
  web.Element render() {
    final requestToken = useRef<int>('requestToken', 0);
    final lastEndpoint = useRef<String?>('lastEndpoint', null);

    useEffect('endpoint', [_endpoint], () {
      final previous = lastEndpoint.value;
      lastEndpoint.value = _endpoint;
      if (previous != null && previous != _endpoint) {
        requestToken.value++;
        setState(() {
          _isLoading = false;
          _error = null;
          _users = const [];
        });
      }
      return null;
    });

    final status = dom.p('', className: _error != null ? 'muted error' : 'muted')
      ..textContent = statusText;

    final row = dom.row(children: [
      dom.actionButton(
        _isLoading ? 'Loading…' : 'Load users',
        disabled: _isLoading,
        action: _UsersActions.load,
      ),
      dom.actionButton(
        'Clear',
        kind: 'secondary',
        disabled: !canClear,
        action: _UsersActions.clear,
      ),
    ]);

    final list = dom.ul(className: 'list');
    for (final user in _users) {
      final name = (user['name'] as String?) ?? '(no name)';
      final email = (user['email'] as String?) ?? '';

      final li = dom.li(className: 'item');
      li.append(dom.span(name, className: 'user'));
      if (email.isNotEmpty) {
        li.append(dom.span(' • $email', className: 'muted'));
      }
      list.append(li);
    }

    return dom.section(
      title: _title,
      children: [
        row,
        status,
        if (_users.isNotEmpty) list,
        dom.p(endpointLabel, className: 'muted'),
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
      _UsersActions.clear: (_) => setState(() {
            _error = null;
            _users = const [];
          }),
    });
  }

  Future<void> _loadUsers() async {
    final requestToken = useRef<int>('requestToken', 0);
    final token = ++requestToken.value;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(_endpoint),
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
          .toList(growable: false);

      setState(() => _users = users);
    } catch (e) {
      if (!isMounted || token != requestToken.value) return;
      setState(() => _error = 'Failed to load users: $e');
    } finally {
      if (!isMounted || token != requestToken.value) return;
      setState(() => _isLoading = false);
    }
  }
}

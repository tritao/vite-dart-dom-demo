import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../ui/component.dart';
import '../ui/dom.dart' as dom;

abstract final class _UsersActions {
  static const load = 'users-load';
  static const clear = 'users-clear';
}

final class UsersComponent extends Component {
  UsersComponent({
    this.title = 'Fetch (async)',
    this.endpoint = 'https://jsonplaceholder.typicode.com/users',
  });

  String title;
  String endpoint;

  int _requestToken = 0;
  String? _lastEndpoint;

  bool _isLoading = false;
  String? _error;
  List<Map<String, Object?>> _users = const [];

  @override
  web.Element render() {
    useEffect('endpoint', [endpoint], () {
      final previous = _lastEndpoint;
      _lastEndpoint = endpoint;
      if (previous != null && previous != endpoint) {
        _requestToken++;
        setState(() {
          _isLoading = false;
          _error = null;
          _users = const [];
        });
      }
      return null;
    });

    final status = dom.p('', className: 'muted');
    if (_isLoading) {
      status.textContent = 'Loading users…';
    } else if (_error != null) {
      status
        ..className = 'muted error'
        ..textContent = _error!;
    } else if (_users.isEmpty) {
      status.textContent = 'Click “Load users” to fetch JSON from the network.';
    } else {
      status.textContent = 'Loaded ${_users.length} users.';
    }

    final row = dom.div(className: 'row');
    row
      ..append(dom.button(
        _isLoading ? 'Loading…' : 'Load users',
        disabled: _isLoading,
        action: _UsersActions.load,
      ))
      ..append(dom.button(
        'Clear',
        kind: 'secondary',
        disabled: _isLoading && _users.isEmpty,
        action: _UsersActions.clear,
      ));

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

    return dom.card(title: title, children: [
      row,
      status,
      if (_users.isNotEmpty) list,
      dom.p('Endpoint: $endpoint', className: 'muted'),
    ]);
  }

  @override
  void onMount() {
    listen(root.onClick, _onClick);
  }

  @override
  void onDispose() {
    _requestToken++;
  }

  void _onClick(web.MouseEvent event) {
    final target = event.target;
    if (target == null) return;

    web.Element? targetEl;
    try {
      targetEl = target as web.Element;
    } catch (_) {
      return;
    }

    final actionEl = targetEl.closest('[data-action]');
    if (actionEl == null) return;

    final action = actionEl.getAttribute('data-action');
    if (action == null) return;

    switch (action) {
      case _UsersActions.load:
        _loadUsers();
      case _UsersActions.clear:
        setState(() {
          _error = null;
          _users = const [];
        });
    }
  }

  Future<void> _loadUsers() async {
    final token = ++_requestToken;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(endpoint),
      );
      if (!isMounted || token != _requestToken) return;
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
      if (!isMounted || token != _requestToken) return;
      setState(() => _error = 'Failed to load users: $e');
    } finally {
      if (!isMounted || token != _requestToken) return;
      setState(() => _isLoading = false);
    }
  }
}

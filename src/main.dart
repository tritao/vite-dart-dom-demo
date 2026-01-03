import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import './morph_patch.dart';

void main() {
  final mount = web.document.querySelector('#app');
  if (mount == null) return;

  final app = _App(mount: mount);
  app.init();
}

class _Todo {
  _Todo({
    required this.id,
    required this.text,
    this.done = false,
  });

  final int id;
  final String text;
  final bool done;

  _Todo copyWith({String? text, bool? done}) =>
      _Todo(id: id, text: text ?? this.text, done: done ?? this.done);

  Map<String, Object?> toJson() => {"id": id, "text": text, "done": done};

  static _Todo fromJson(Map<String, Object?> json) => _Todo(
        id: (json["id"] as num).toInt(),
        text: (json["text"] as String?) ?? "",
        done: (json["done"] as bool?) ?? false,
      );
}

abstract final class _Actions {
  static const counterDec = 'counter-dec';
  static const counterInc = 'counter-inc';
  static const counterReset = 'counter-reset';

  static const todoAdd = 'todo-add';
  static const todoClearDone = 'todo-clear-done';
  static const todoToggle = 'todo-toggle';
  static const todoDelete = 'todo-delete';

  static const usersLoad = 'users-load';
  static const usersClear = 'users-clear';
}

class _App {
  _App({required this.mount});

  final web.Element mount;
  late final web.Element _root;
  web.HTMLInputElement? _todoInput;

  int counter = 0;

  int _nextTodoId = 1;
  final List<_Todo> _todos = [];

  bool _isLoadingUsers = false;
  String? _usersError;
  List<Map<String, Object?>> _users = const [];

  void init() {
    _loadTodos();
    _root = _buildShell();
    mount.append(_root);
    _attachDelegatedEvents(_root);
    _cacheRefs();
  }

  void _setState(void Function() fn) {
    fn();
    _render();
  }

  void _render() {
    final next = _buildShell();
    morphPatch(_root, next);
    _cacheRefs();
  }

  void _cacheRefs() {
    try {
      _todoInput = _root.querySelector('#todo-input') as web.HTMLInputElement?;
    } catch (_) {
      _todoInput = null;
    }
  }

  web.Element _buildShell() {
    final container = web.HTMLDivElement()
      ..id = "app-root"
      ..className = "container";

    final header = web.HTMLDivElement()
      ..className = "header"
      ..append(web.HTMLHeadingElement.h1()
        ..textContent = "Dart + Vite (DOM demo)")
      ..append(web.HTMLParagraphElement()
        ..className = "muted"
        ..textContent =
            "Counter + Todos (localStorage) + Fetch (async) to validate the integration.");

    container
      ..append(header)
      ..append(_buildCounterView())
      ..append(web.HTMLDivElement()..className = "spacer")
      ..append(_buildTodosView())
      ..append(web.HTMLDivElement()..className = "spacer")
      ..append(_buildFetchView());
    return container;
  }

  void _attachDelegatedEvents(web.Element root) {
    root.onClick.listen(_onClick);
    root.onChange.listen(_onChange);
    root.onKeyDown.listen(_onKeyDown);
  }

  web.Element? _eventTargetAsElement(web.Event event) {
    final target = event.target;
    if (target == null) return null;
    try {
      return target as web.Element;
    } catch (_) {
      return null;
    }
  }

  void _onClick(web.MouseEvent event) {
    final target = _eventTargetAsElement(event);
    if (target == null) return;

    final actionEl = target.closest('[data-action]');
    if (actionEl == null) return;

    final action = actionEl.getAttribute('data-action');
    if (action == null) return;

    switch (action) {
      case _Actions.counterDec:
        _setState(() => counter--);
      case _Actions.counterInc:
        _setState(() => counter++);
      case _Actions.counterReset:
        _setState(() => counter = 0);
      case _Actions.todoAdd:
        _addTodoFromInput();
      case _Actions.todoClearDone:
        _setState(() {
          _todos.removeWhere((t) => t.done);
          _saveTodos();
        });
      case _Actions.todoDelete:
        final idRaw = actionEl.getAttribute('data-id');
        final id = int.tryParse(idRaw ?? '');
        if (id == null) return;
        _setState(() {
          _todos.removeWhere((t) => t.id == id);
          _saveTodos();
        });
      case _Actions.usersLoad:
        _loadUsers();
      case _Actions.usersClear:
        _setState(() {
          _usersError = null;
          _users = const [];
        });
    }
  }

  void _onChange(web.Event event) {
    final target = _eventTargetAsElement(event);
    if (target == null) return;

    final actionEl = target.closest('[data-action="$_Actions.todoToggle"]');
    if (actionEl == null) return;

    final idRaw = actionEl.getAttribute('data-id');
    final id = int.tryParse(idRaw ?? '');
    if (id == null) return;

    try {
      final checkbox = actionEl as web.HTMLInputElement;
      final checked = checkbox.checked == true;
      _setState(() {
        final index = _todos.indexWhere((t) => t.id == id);
        if (index == -1) return;
        _todos[index] = _todos[index].copyWith(done: checked);
        _saveTodos();
      });
    } catch (_) {
      return;
    }
  }

  void _onKeyDown(web.KeyboardEvent event) {
    if (event.key != 'Enter') return;
    final target = _eventTargetAsElement(event);
    if (target == null) return;

    if (target.getAttribute('id') == 'todo-input') {
      _addTodoFromInput();
    }
  }

  web.Element _buildCard({
    required String title,
    required List<web.Element> children,
  }) {
    final card = web.HTMLDivElement()..className = "card";
    card.append(web.HTMLHeadingElement.h2()..textContent = title);
    for (final child in children) {
      card.append(child);
    }
    return card;
  }

  web.Element _buildCounterView() {
    final row = web.HTMLDivElement()..className = "row";
    row
      ..append(_button("−1", action: _Actions.counterDec))
      ..append(_button("+1", action: _Actions.counterInc))
      ..append(_button("Reset",
          kind: "secondary", action: _Actions.counterReset));

    return _buildCard(title: "Counter", children: [
      web.HTMLParagraphElement()
        ..className = "big"
        ..textContent = "$counter",
      row,
      web.HTMLParagraphElement()
        ..className = "muted"
        ..textContent = "Exercises DOM updates and event handlers.",
    ]);
  }

  web.Element _buildTodosView() {
    final input = web.HTMLInputElement()
      ..type = "text"
      ..placeholder = "New todo…"
      ..className = "input"
      ..id = "todo-input";

    final list = web.HTMLUListElement()..className = "list";
    if (_todos.isEmpty) {
      list.append(web.HTMLLIElement()
        ..className = "muted"
        ..textContent = "No todos yet.");
    } else {
      for (final todo in _todos) {
        list.append(_buildTodoItem(todo));
      }
    }

    final remaining = _todos.where((t) => !t.done).length;

    final row = web.HTMLDivElement()..className = "row";
    row
      ..append(input)
      ..append(_button("Add", action: _Actions.todoAdd))
      ..append(_button(
        "Clear done",
        kind: "secondary",
        disabled: _todos.every((t) => !t.done),
        action: _Actions.todoClearDone,
      ));

    return _buildCard(title: "Todos", children: [
      row,
      web.HTMLParagraphElement()
        ..className = "muted"
        ..textContent =
            "${_todos.length} total • $remaining remaining • persists to localStorage",
      list,
    ]);
  }

  web.HTMLLIElement _buildTodoItem(_Todo todo) {
    final item = web.HTMLLIElement()..className = "item";
    item.setAttribute('data-key', 'todo-${todo.id}');

    final checkbox = web.HTMLInputElement()
      ..type = "checkbox"
      ..checked = todo.done
      ..className = "checkbox"
      ..setAttribute('data-action', _Actions.todoToggle)
      ..setAttribute('data-id', '${todo.id}');

    final label = web.HTMLSpanElement()
      ..textContent = todo.text
      ..className = todo.done ? "todoText done" : "todoText";

    final remove = _button(
      "Delete",
      kind: "danger",
      action: _Actions.todoDelete,
      dataId: todo.id,
    );

    item..append(checkbox)..append(label)..append(remove);
    return item;
  }

  web.Element _buildFetchView() {
    final status = web.HTMLParagraphElement()..className = "muted";
    if (_isLoadingUsers) {
      status.textContent = "Loading users…";
    } else if (_usersError != null) {
      status
        ..className = "muted error"
        ..textContent = _usersError!;
    } else if (_users.isEmpty) {
      status.textContent = "Click “Load users” to fetch JSON from the network.";
    } else {
      status.textContent = "Loaded ${_users.length} users.";
    }

    final list = web.HTMLUListElement()..className = "list";
    for (final user in _users) {
      final name = (user["name"] as String?) ?? "(no name)";
      final email = (user["email"] as String?) ?? "";
      final li = web.HTMLLIElement()..className = "item";
      li.append(web.HTMLSpanElement()
        ..className = "user"
        ..textContent = name);
      if (email.isNotEmpty) {
        li.append(web.HTMLSpanElement()
          ..className = "muted"
          ..textContent = " • $email");
      }
      list.append(li);
    }

    final row = web.HTMLDivElement()..className = "row";
    row
      ..append(_button(
        _isLoadingUsers ? "Loading…" : "Load users",
        disabled: _isLoadingUsers,
        action: _Actions.usersLoad,
      ))
      ..append(_button(
        "Clear",
        kind: "secondary",
        disabled: _isLoadingUsers && _users.isEmpty,
        action: _Actions.usersClear,
      ));

    return _buildCard(title: "Fetch (async)", children: [
      row,
      status,
      if (_users.isNotEmpty) list,
      web.HTMLParagraphElement()
        ..className = "muted"
        ..textContent = "Endpoint: https://jsonplaceholder.typicode.com/users",
    ]);
  }

  web.HTMLButtonElement _button(
    String label, {
    String kind = "primary",
    bool disabled = false,
    required String action,
    int? dataId,
  }) {
    final button = web.HTMLButtonElement()
      ..type = "button"
      ..textContent = label
      ..disabled = disabled
      ..className = "btn $kind";
    button.setAttribute('data-action', action);
    if (dataId != null) {
      button.setAttribute('data-id', '$dataId');
    }
    return button;
  }

  void _addTodoFromInput() {
    final input = _todoInput;
    if (input == null) return;

    final text = input.value.trim();
    if (text.isEmpty) return;

    _setState(() {
      _todos.insert(0, _Todo(id: _nextTodoId++, text: text));
      _saveTodos();
    });

    input.value = '';
  }

  void _loadTodos() {
    final storage = web.window.localStorage;
    if (storage == null) return;

    final raw = storage.getItem("todos_v1");
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _todos
        ..clear()
        ..addAll(decoded.whereType<Map>().map((e) {
          final map = e.map((k, v) => MapEntry(k.toString(), v));
          return _Todo.fromJson(map);
        }));
      final maxId =
          _todos.isEmpty ? 0 : _todos.map((t) => t.id).reduce((a, b) => a > b ? a : b);
      _nextTodoId = maxId + 1;
    } catch (_) {
      // Ignore corrupted localStorage.
      _todos.clear();
      _nextTodoId = 1;
    }
  }

  void _saveTodos() {
    final storage = web.window.localStorage;
    if (storage == null) return;

    final encoded = jsonEncode(_todos.map((t) => t.toJson()).toList());
    storage.setItem("todos_v1", encoded);
  }

  Future<void> _loadUsers() async {
    _setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });

    try {
      final response = await http.get(
        Uri.parse("https://jsonplaceholder.typicode.com/users"),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("HTTP ${response.statusCode}");
      }

      final raw = response.body;
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw FormatException("Unexpected response shape");
      }
      final users = decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);
      _setState(() {
        _users = users;
      });
    } catch (e) {
      _setState(() {
        _usersError = "Failed to load users: $e";
      });
    } finally {
      _setState(() {
        _isLoadingUsers = false;
      });
    }
  }
}

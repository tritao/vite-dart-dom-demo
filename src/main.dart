import 'dart:convert';
import 'dart:html';

void main() {
  final mount = document.querySelector('#app');
  if (mount == null) return;

  final app = _App(mount: mount);
  app.init();
}

enum _Tab { counter, todos, fetch }

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

class _App {
  _App({required this.mount});

  final Element mount;

  _Tab tab = _Tab.counter;
  int counter = 0;

  int _nextTodoId = 1;
  final List<_Todo> _todos = [];

  bool _isLoadingUsers = false;
  String? _usersError;
  List<Map<String, Object?>> _users = const [];

  void init() {
    _loadTodos();
    _render();
  }

  void _setState(void Function() fn) {
    fn();
    _render();
  }

  void _render() {
    mount.children.clear();
    mount.append(_buildShell());
  }

  Element _buildShell() {
    final container = DivElement()..classes.add("container");

    final header = DivElement()
      ..classes.add("header")
      ..append(HeadingElement.h1()..text = "Dart + Vite (DOM demo)")
      ..append(ParagraphElement()
        ..classes.add("muted")
        ..text =
            "Counter + Todos (localStorage) + Fetch (async) to validate the integration.");

    container..append(header)..append(_buildTabs())..append(_buildView());
    return container;
  }

  Element _buildTabs() {
    final tabs = DivElement()..classes.add("tabs");
    tabs.append(_tabButton(_Tab.counter, "Counter"));
    tabs.append(_tabButton(_Tab.todos, "Todos"));
    tabs.append(_tabButton(_Tab.fetch, "Fetch"));
    return tabs;
  }

  ButtonElement _tabButton(_Tab value, String label) {
    final button = ButtonElement()
      ..type = "button"
      ..text = label
      ..classes.addAll(["tab", if (tab == value) "active"]);
    button.onClick.listen((_) => _setState(() => tab = value));
    return button;
  }

  Element _buildView() {
    switch (tab) {
      case _Tab.counter:
        return _buildCounterView();
      case _Tab.todos:
        return _buildTodosView();
      case _Tab.fetch:
        return _buildFetchView();
    }
  }

  Element _buildCard({required String title, required List<Element> children}) {
    final card = DivElement()..classes.add("card");
    card.append(HeadingElement.h2()..text = title);
    for (final child in children) {
      card.append(child);
    }
    return card;
  }

  Element _buildCounterView() {
    return _buildCard(title: "Counter", children: [
      ParagraphElement()
        ..classes.add("big")
        ..text = "$counter",
      DivElement()
        ..classes.add("row")
        ..children.addAll([
          _button("−1", onClick: () => _setState(() => counter--)),
          _button("+1", onClick: () => _setState(() => counter++)),
          _button("Reset", kind: "secondary", onClick: () => _setState(() => counter = 0)),
        ]),
      ParagraphElement()
        ..classes.add("muted")
        ..text = "Exercises DOM updates and event handlers.",
    ]);
  }

  Element _buildTodosView() {
    final input = TextInputElement()
      ..placeholder = "New todo…"
      ..classes.add("input");

    void addTodo() {
      final text = input.value?.trim() ?? "";
      if (text.isEmpty) return;
      _setState(() {
        _todos.insert(0, _Todo(id: _nextTodoId++, text: text));
        _saveTodos();
        input.value = "";
      });
    }

    input.onKeyDown.listen((e) {
      if (e.key == "Enter") addTodo();
    });

    final list = UListElement()..classes.add("list");
    if (_todos.isEmpty) {
      list.append(LIElement()
        ..classes.add("muted")
        ..text = "No todos yet.");
    } else {
      for (final todo in _todos) {
        list.append(_buildTodoItem(todo));
      }
    }

    final remaining = _todos.where((t) => !t.done).length;

    return _buildCard(title: "Todos", children: [
      DivElement()
        ..classes.add("row")
        ..children.addAll([
          input,
          _button("Add", onClick: addTodo),
          _button(
            "Clear done",
            kind: "secondary",
            disabled: _todos.every((t) => !t.done),
            onClick: () => _setState(() {
              _todos.removeWhere((t) => t.done);
              _saveTodos();
            }),
          ),
        ]),
      ParagraphElement()
        ..classes.add("muted")
        ..text = "${_todos.length} total • $remaining remaining • persists to localStorage",
      list,
    ]);
  }

  LIElement _buildTodoItem(_Todo todo) {
    final item = LIElement()..classes.add("item");

    final checkbox = CheckboxInputElement()
      ..checked = todo.done
      ..classes.add("checkbox");
    checkbox.onChange.listen((_) {
      _setState(() {
        final index = _todos.indexWhere((t) => t.id == todo.id);
        if (index == -1) return;
        _todos[index] = _todos[index].copyWith(done: checkbox.checked == true);
        _saveTodos();
      });
    });

    final label = SpanElement()
      ..text = todo.text
      ..classes.addAll(["todoText", if (todo.done) "done"]);

    final remove = _button("Delete", kind: "danger", onClick: () {
      _setState(() {
        _todos.removeWhere((t) => t.id == todo.id);
        _saveTodos();
      });
    });

    item..append(checkbox)..append(label)..append(remove);
    return item;
  }

  Element _buildFetchView() {
    final status = ParagraphElement()..classes.add("muted");
    if (_isLoadingUsers) {
      status.text = "Loading users…";
    } else if (_usersError != null) {
      status
        ..classes.add("error")
        ..text = _usersError!;
    } else if (_users.isEmpty) {
      status.text = "Click “Load users” to fetch JSON from the network.";
    } else {
      status.text = "Loaded ${_users.length} users.";
    }

    final list = UListElement()..classes.add("list");
    for (final user in _users) {
      final name = (user["name"] as String?) ?? "(no name)";
      final email = (user["email"] as String?) ?? "";
      final li = LIElement()..classes.add("item");
      li.append(SpanElement()
        ..classes.add("user")
        ..text = name);
      if (email.isNotEmpty) {
        li.append(SpanElement()
          ..classes.add("muted")
          ..text = " • $email");
      }
      list.append(li);
    }

    return _buildCard(title: "Fetch (async)", children: [
      DivElement()
        ..classes.add("row")
        ..children.addAll([
          _button(
            _isLoadingUsers ? "Loading…" : "Load users",
            disabled: _isLoadingUsers,
            onClick: _loadUsers,
          ),
          _button(
            "Clear",
            kind: "secondary",
            disabled: _isLoadingUsers && _users.isEmpty,
            onClick: () => _setState(() {
              _usersError = null;
              _users = const [];
            }),
          ),
        ]),
      status,
      if (_users.isNotEmpty) list,
      ParagraphElement()
        ..classes.add("muted")
        ..text = "Endpoint: https://jsonplaceholder.typicode.com/users",
    ]);
  }

  ButtonElement _button(
    String label, {
    required void Function() onClick,
    String kind = "primary",
    bool disabled = false,
  }) {
    final button = ButtonElement()
      ..type = "button"
      ..text = label
      ..disabled = disabled
      ..classes.addAll(["btn", kind]);
    button.onClick.listen((_) {
      if (!button.disabled) onClick();
    });
    return button;
  }

  void _loadTodos() {
    final raw = window.localStorage["todos_v1"];
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
    final encoded = jsonEncode(_todos.map((t) => t.toJson()).toList());
    window.localStorage["todos_v1"] = encoded;
  }

  Future<void> _loadUsers() async {
    _setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });

    try {
      final raw =
          await HttpRequest.getString("https://jsonplaceholder.typicode.com/users");
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

import 'package:web/web.dart' as web;

import './todo.dart';
import '../ui/component.dart';
import '../ui/dom.dart' as dom;
import '../ui/events.dart' as events;

abstract final class _TodosActions {
  static const add = 'todos-add';
  static const clearDone = 'todos-clear-done';
  static const toggle = 'todos-toggle';
  static const remove = 'todos-remove';
}

final class TodosComponent extends Component {
  TodosComponent();

  static const _storageKey = 'todos_v1';

  int _nextId = 1;
  final List<Todo> _todos = [];

  web.HTMLInputElement? _input;

  int get remainingCount => _todos.where((t) => !t.done).length;

  bool get canClearDone => _todos.any((t) => t.done);

  bool get isEmpty => _todos.isEmpty;

  String get summaryText =>
      '${_todos.length} total • $remainingCount remaining • persists to localStorage';

  @override
  web.Element render() {
    final input = dom.inputText(
      id: 'todos-input',
      className: 'input',
      placeholder: 'New todo…',
    );

    final list = dom.ul(className: 'list');
    if (isEmpty) {
      list.append(dom.li(className: 'muted', text: 'No todos yet.'));
    } else {
      for (final todo in _todos) {
        list.append(_todoItem(todo));
      }
    }

    final row = dom.div(className: 'row');
    row
      ..append(input)
      ..append(dom.actionButton('Add', action: _TodosActions.add))
      ..append(dom.actionButton(
        'Clear done',
        kind: 'secondary',
        disabled: !canClearDone,
        action: _TodosActions.clearDone,
      ));

    return dom.card(title: 'Todos', children: [
      row,
      dom.p(summaryText, className: 'muted'),
      list,
    ]);
  }

  @override
  void onMount() {
    _loadTodos();
    listen(root.onClick, _onClick);
    listen(root.onChange, _onChange);
    listen(root.onKeyDown, _onKeyDown);
    _cacheRefs();
    invalidate();
  }

  @override
  void onAfterPatch() => _cacheRefs();

  void _cacheRefs() {
    try {
      _input = root.querySelector('#todos-input') as web.HTMLInputElement?;
    } catch (_) {
      _input = null;
    }
  }

  void _onClick(web.MouseEvent event) {
    final actionEl = events.closestActionElement(event);
    final action = actionEl?.getAttribute('data-action');
    if (action == null) return;

    switch (action) {
      case _TodosActions.add:
        _addFromInput();
      case _TodosActions.clearDone:
        setState(() {
          _todos.removeWhere((t) => t.done);
          _saveTodos();
        });
      case _TodosActions.remove:
        final id = actionEl == null ? null : events.actionIdFromElement(actionEl);
        if (id == null) return;
        setState(() {
          _todos.removeWhere((t) => t.id == id);
          _saveTodos();
        });
    }
  }

  void _onChange(web.Event event) {
    final targetEl = events.eventTargetElement(event);
    if (targetEl == null) return;

    final actionEl = targetEl.closest('[data-action="${_TodosActions.toggle}"]');
    if (actionEl == null) return;

    final id = events.actionIdFromElement(actionEl);
    if (id == null) return;

    try {
      final checkbox = actionEl as web.HTMLInputElement;
      final checked = checkbox.checked == true;
      setState(() {
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
    final targetEl = events.eventTargetElement(event);
    if (targetEl == null) return;

    if (targetEl.getAttribute('id') == 'todos-input') {
      _addFromInput();
    }
  }

  void _addFromInput() {
    final input = _input;
    if (input == null) return;

    final text = input.value.trim();
    if (text.isEmpty) return;

    setState(() {
      _todos.insert(0, Todo(id: _nextId++, text: text));
      _saveTodos();
    });

    input.value = '';
  }

  void _loadTodos() {
    final loaded = loadTodosFromLocalStorage(key: _storageKey);
    if (loaded.isEmpty) return;

    _todos
      ..clear()
      ..addAll(loaded);

    final maxId =
        _todos.map((t) => t.id).reduce((a, b) => a > b ? a : b);
    _nextId = maxId + 1;
  }

  void _saveTodos() {
    saveTodosToLocalStorage(key: _storageKey, todos: _todos);
  }

  web.HTMLLIElement _todoItem(Todo todo) {
    final item = dom.li(
      className: 'item',
      attrs: {'data-key': 'todos-${todo.id}'},
    );

    final checkbox = dom.actionCheckbox(
      checked: todo.done,
      className: 'checkbox',
      action: _TodosActions.toggle,
      dataId: todo.id,
    );

    final label =
        dom.span(todo.text, className: todo.done ? 'todoText done' : 'todoText');

    final remove = dom.actionButton(
      'Delete',
      kind: 'danger',
      action: _TodosActions.remove,
      dataId: todo.id,
    );

    item..append(checkbox)..append(label)..append(remove);
    return item;
  }
}

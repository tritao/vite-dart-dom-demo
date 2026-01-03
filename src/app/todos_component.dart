import 'package:web/web.dart' as web;

import './todo.dart';
import 'package:dart_web_test/vite_ui/component.dart';
import 'package:dart_web_test/vite_ui/action_dispatch.dart';
import 'package:dart_web_test/vite_ui/dom.dart' as dom;
import 'package:dart_web_test/vite_ui/events.dart' as events;

abstract final class _TodosActions {
  static const add = 'todos-add';
  static const clearDone = 'todos-clear-done';
  static const toggle = 'todos-toggle';
  static const remove = 'todos-remove';
}

final class _TodosState {
  const _TodosState({
    required this.nextId,
    required this.todos,
  });

  final int nextId;
  final List<Todo> todos;

  static const empty = _TodosState(nextId: 1, todos: []);
}

sealed class _TodosAction {
  const _TodosAction();
}

final class _TodosLoad extends _TodosAction {
  const _TodosLoad(this.todos);
  final List<Todo> todos;
}

final class _TodosAdd extends _TodosAction {
  const _TodosAdd(this.text);
  final String text;
}

final class _TodosToggle extends _TodosAction {
  const _TodosToggle({required this.id, required this.done});
  final int id;
  final bool done;
}

final class _TodosRemove extends _TodosAction {
  const _TodosRemove(this.id);
  final int id;
}

final class _TodosClearDone extends _TodosAction {
  const _TodosClearDone();
}

final class TodosComponent extends Component {
  TodosComponent();

  static const _storageKey = 'todos_v1';

  web.HTMLInputElement? _input;

  ReducerHandle<_TodosState, _TodosAction> get _store =>
      useReducer<_TodosState, _TodosAction>(
        'todos',
        _TodosState.empty,
        _reduce,
      );

  List<Todo> get _todos => _store.state.todos;

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

    final todoRows = useMemo<List<(int, String, bool)>>(
      'todoRows',
      [_todos],
      () => _todos.map((t) => (t.id, t.text, t.done)).toList(growable: false),
    );

    final listChildren = isEmpty
        ? <web.Element>[dom.mutedLi('No todos yet.')]
        : todoRows.map((row) {
            final (id, text, done) = row;
            return _todoItem(Todo(id: id, text: text, done: done));
          }).toList(growable: false);

    return dom.section(
      title: 'Todos',
      subtitle: summaryText,
      children: [
        dom.row(children: [
          input,
          dom.actionButton('Add', action: _TodosActions.add),
          dom.actionButton(
            'Clear done',
            kind: 'secondary',
            disabled: !canClearDone,
            action: _TodosActions.clearDone,
          ),
        ]),
        dom.list(children: listChildren),
      ],
    );
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
  void onAfterPatch() {
    _cacheRefs();
    _saveTodos();
  }

  void _cacheRefs() {
    try {
      _input = root.querySelector('#todos-input') as web.HTMLInputElement?;
    } catch (_) {
      _input = null;
    }
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      _TodosActions.add: (_) => _addFromInput(),
      _TodosActions.clearDone: (_) => _store.dispatch(const _TodosClearDone()),
      _TodosActions.remove: (el) {
        if (el == null) return;
        final id = events.actionIdFromElement(el);
        if (id == null) return;
        _store.dispatch(_TodosRemove(id));
      },
    });
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
      _store.dispatch(_TodosToggle(id: id, done: checked));
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

    _store.dispatch(_TodosAdd(text));

    input.value = '';
  }

  void _loadTodos() {
    final loaded = loadTodosFromLocalStorage(key: _storageKey);
    if (loaded.isEmpty) return;
    _store.dispatch(_TodosLoad(loaded));
  }

  void _saveTodos() {
    saveTodosToLocalStorage(key: _storageKey, todos: _todos);
  }

  web.HTMLLIElement _todoItem(Todo todo) {
    final item = dom.item(attrs: {'data-key': 'todos-${todo.id}'});

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

  static _TodosState _reduce(_TodosState state, _TodosAction action) {
    switch (action) {
      case _TodosLoad(:final todos):
        final maxId = todos.isEmpty
            ? 0
            : todos.map((t) => t.id).reduce((a, b) => a > b ? a : b);
        return _TodosState(nextId: maxId + 1, todos: todos);

      case _TodosAdd(:final text):
        final todo = Todo(id: state.nextId, text: text);
        return _TodosState(
          nextId: state.nextId + 1,
          todos: [todo, ...state.todos],
        );

      case _TodosToggle(:final id, :final done):
        final next = state.todos
            .map((t) => t.id == id ? t.copyWith(done: done) : t)
            .toList(growable: false);
        return _TodosState(nextId: state.nextId, todos: next);

      case _TodosRemove(:final id):
        final next =
            state.todos.where((t) => t.id != id).toList(growable: false);
        return _TodosState(nextId: state.nextId, todos: next);

      case _TodosClearDone():
        final next =
            state.todos.where((t) => !t.done).toList(growable: false);
        return _TodosState(nextId: state.nextId, todos: next);
    }
  }
}

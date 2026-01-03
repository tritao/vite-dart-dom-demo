import 'package:web/web.dart' as web;

import 'package:dart_web_test/dom_ui/action_dispatch.dart';
import 'package:dart_web_test/dom_ui/component.dart';
import 'package:dart_web_test/dom_ui/dom.dart' as dom;
import 'package:dart_web_test/dom_ui/events.dart' as events;

import './todo.dart';
import './todos_state.dart';

abstract final class TodosDomActions {
  static const add = 'todos-add';
  static const clearDone = 'todos-clear-done';
  static const toggle = 'todos-toggle';
  static const remove = 'todos-remove';
}

final class TodosComponent extends Component {
  TodosComponent();

  static const _storageKey = 'todos_v1';

  web.HTMLInputElement? _input;

  ReducerHandle<TodosState, TodosAction> get _store =>
      useReducer<TodosState, TodosAction>(
        'todos',
        TodosState.empty,
        todosReducer,
      );

  List<Todo> get _todos => _store.state.todos;

  int get remainingCount => _todos.where((t) => !t.done).length;

  bool get canClearDone => _todos.any((t) => t.done);

  bool get isEmpty => _todos.isEmpty;

  String get summaryText =>
      '${_todos.length} total • $remainingCount remaining • persists to localStorage';

  @override
  web.Element render() {
    final input = _buildInput();
    final listChildren = _buildListChildren();
    return dom.section(
      title: 'Todos',
      subtitle: summaryText,
      children: [
        _buildControls(input),
        dom.list(children: listChildren),
      ],
    );
  }

  web.HTMLInputElement _buildInput() => dom.inputText(
        id: 'todos-input',
        className: 'input',
        placeholder: 'New todo…',
      );

  web.Element _buildControls(web.Element input) => dom.row(children: [
        input,
        dom.actionButton('Add', action: TodosDomActions.add),
        dom.secondaryButton(
          'Clear done',
          disabled: !canClearDone,
          action: TodosDomActions.clearDone,
        ),
      ]);

  List<web.Element> _buildListChildren() {
    if (isEmpty) return <web.Element>[dom.mutedLi('No todos yet.')];

    return useMemo<List<web.Element>>(
      'todoListItems',
      [_todos],
      () => _todos.map(_todoItem).toList(growable: false),
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
      TodosDomActions.add: (_) => _addFromInput(),
      TodosDomActions.clearDone: (_) => _store.dispatch(const TodosClearDone()),
      TodosDomActions.remove: (el) {
        if (el == null) return;
        final id = events.actionIdFromElement(el);
        if (id == null) return;
        _store.dispatch(TodosRemove(id));
      },
    });
  }

  void _onChange(web.Event event) {
    final targetEl = events.eventTargetElement(event);
    if (targetEl == null) return;

    final actionEl =
        targetEl.closest('[data-action="${TodosDomActions.toggle}"]');
    if (actionEl == null) return;

    final id = events.actionIdFromElement(actionEl);
    if (id == null) return;

    try {
      final checkbox = actionEl as web.HTMLInputElement;
      final checked = checkbox.checked == true;
      _store.dispatch(TodosToggle(id: id, done: checked));
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

    _store.dispatch(TodosAdd(text));

    input.value = '';
  }

  void _loadTodos() {
    final loaded = loadTodosFromLocalStorage(key: _storageKey);
    if (loaded.isEmpty) return;
    _store.dispatch(TodosLoad(loaded));
  }

  void _saveTodos() {
    saveTodosToLocalStorage(key: _storageKey, todos: _todos);
  }

  web.HTMLLIElement _todoItem(Todo todo) {
    final item = dom.item(attrs: {'data-key': 'todos-${todo.id}'});

    final checkbox = dom.actionCheckbox(
      checked: todo.done,
      className: 'checkbox',
      action: TodosDomActions.toggle,
      dataId: todo.id,
    );

    final label = dom.span(todo.text,
        className: todo.done ? 'todoText done' : 'todoText');

    final remove = dom.dangerButton(
      'Delete',
      action: TodosDomActions.remove,
      dataId: todo.id,
    );

    item
      ..append(checkbox)
      ..append(label)
      ..append(remove);
    return item;
  }
}

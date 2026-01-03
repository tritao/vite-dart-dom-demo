import './todo.dart';

final class TodosState {
  const TodosState({
    required this.nextId,
    required this.todos,
  });

  final int nextId;
  final List<Todo> todos;

  static const empty = TodosState(nextId: 1, todos: []);

  TodosState copyWith({
    int? nextId,
    List<Todo>? todos,
  }) =>
      TodosState(
        nextId: nextId ?? this.nextId,
        todos: todos ?? this.todos,
      );
}

sealed class TodosAction {
  const TodosAction();
}

final class TodosLoad extends TodosAction {
  const TodosLoad(this.todos);
  final List<Todo> todos;
}

final class TodosAdd extends TodosAction {
  const TodosAdd(this.text);
  final String text;
}

final class TodosToggle extends TodosAction {
  const TodosToggle({required this.id, required this.done});
  final int id;
  final bool done;
}

final class TodosRemove extends TodosAction {
  const TodosRemove(this.id);
  final int id;
}

final class TodosClearDone extends TodosAction {
  const TodosClearDone();
}

TodosState todosReducer(TodosState state, TodosAction action) {
  switch (action) {
    case TodosLoad(:final todos):
      final maxId = todos.isEmpty
          ? 0
          : todos.map((t) => t.id).reduce((a, b) => a > b ? a : b);
      return state.copyWith(nextId: maxId + 1, todos: todos);

    case TodosAdd(:final text):
      final todo = Todo(id: state.nextId, text: text);
      return state.copyWith(
        nextId: state.nextId + 1,
        todos: [todo, ...state.todos],
      );

    case TodosToggle(:final id, :final done):
      final next = state.todos
          .map((t) => t.id == id ? t.copyWith(done: done) : t)
          .toList(growable: false);
      return state.copyWith(todos: next);

    case TodosRemove(:final id):
      final next = state.todos.where((t) => t.id != id).toList(growable: false);
      return state.copyWith(todos: next);

    case TodosClearDone():
      final next = state.todos.where((t) => !t.done).toList(growable: false);
      return state.copyWith(todos: next);
  }
}

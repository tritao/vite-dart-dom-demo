import 'dart:convert';

import 'package:web/web.dart' as web;

final class Todo {
  Todo({
    required this.id,
    required this.text,
    this.done = false,
  });

  final int id;
  final String text;
  final bool done;

  Todo copyWith({String? text, bool? done}) =>
      Todo(id: id, text: text ?? this.text, done: done ?? this.done);

  Map<String, Object?> toJson() => {"id": id, "text": text, "done": done};

  static Todo fromJson(Map<String, Object?> json) => Todo(
        id: (json["id"] as num).toInt(),
        text: (json["text"] as String?) ?? "",
        done: (json["done"] as bool?) ?? false,
      );
}

List<Todo> loadTodosFromLocalStorage({
  required String key,
}) {
  final storage = web.window.localStorage;
  if (storage == null) return const [];

  final raw = storage.getItem(key);
  if (raw == null || raw.isEmpty) return const [];

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().map((e) {
      final map = e.map((k, v) => MapEntry(k.toString(), v));
      return Todo.fromJson(map);
    }).toList(growable: false);
  } catch (_) {
    return const [];
  }
}

void saveTodosToLocalStorage({
  required String key,
  required List<Todo> todos,
}) {
  final storage = web.window.localStorage;
  if (storage == null) return;
  storage.setItem(key, jsonEncode(todos.map((t) => t.toJson()).toList()));
}


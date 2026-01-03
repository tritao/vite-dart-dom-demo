# App code

- Entry point: `src/main.dart`
- App shell + routing/mount logic: `src/app/app_component.dart`
- Components:
  - `src/app/counter_component.dart`
  - `src/app/todos_component.dart` (+ `src/app/todos_state.dart`, `src/app/todo.dart`)
  - `src/app/users_component.dart` (+ `src/app/users_state.dart`, `src/app/user.dart`)
- App config (provided via context): `src/app/config.dart`
- URL/query routing helpers: `src/app/route.dart`

Reusable runtime lives in `lib/dom_ui/`.


---
title: Context
slug: runtime-context
group: Runtime
order: 50
description: createContext/useContext/provideContext for scoped values.
status: beta
tags: [runtime]
---

Context is a scoped value lookup that flows through a call tree:

## Functions

### `createContext(defaultValue)`

Defines a context key with a default value.

Use it when you want a dependency (service, config, router, theme) to be readable without threading arguments everywhere.

```dart
final apiBaseUrl = createContext<String>("https://example.com");
```

### `useContext(ctx)`

Reads the nearest provided value for a context (or the default).

Use it inside code that runs within a `provideContext` scope.

```dart
final url = useContext(apiBaseUrl);
```

### `provideContext(ctx, value, () => ...)`

Runs a function with a context value provided for everything it calls.

Use it at “composition boundaries” (mounting a subtree, rendering a route).

```dart
provideContext(apiBaseUrl, "https://api.myapp.com", () {
  // Any useContext(apiBaseUrl) called within this scope reads the provided value.
});
```

Unlike widget frameworks, this context is **not** tied to a DOM tree automatically; it’s tied to the current reactive owner/call scope when you call `provideContext`.

:::demo id=runtime-context-basic title="provideContext scope"
Shows default value vs provided value within a scope.
:::

:::code file=src/docs/examples/runtime_context_basic.dart region=snippet lang=dart
:::

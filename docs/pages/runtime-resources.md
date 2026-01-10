---
title: Resources (async)
slug: runtime-resources
group: Runtime
order: 40
description: createResource/createResourceWithSource for async data.
status: beta
tags: [runtime]
---

Resources are async reactive values with built-in `loading` and `error` signals.

## Functions

### `createResource(fetcher)`

Creates a resource that starts fetching immediately.

Use it when the data doesn’t depend on another reactive value (e.g. load “current user” on mount).

```dart
final user = createResource(() async => await fetchCurrentUser());
```

### `createResourceWithSource(source, fetcher)`

Creates a resource that refetches when `source()` changes.

Use it when the data depends on reactive state (search query, selected id, pagination).

```dart
final userId = createSignal("123");
final user = createResourceWithSource(
  () => userId.value,
  (id) async => await fetchUser(id),
);
```

## Resource fields + methods

Each resource is a `Resource<T>` with:

### `resource.value`

The resolved value (nullable until first success).

Use it in views; reads are tracked.

### `resource.loading`

Whether a fetch is in flight.

Use it to show a spinner/skeleton.

### `resource.error`

The last error (if any).

Use it to show an error state.

Example “resource-driven view” pattern:

```dart
final user = createResource(() async => await fetchCurrentUser());

return insert(root, () {
  if (user.loading) return web.Text("Loading…");
  if (user.error != null) return web.Text("Error: ${user.error}");
  return web.Text("Hello ${user.value!.name}");
});
```

### `resource.refetch((version) { ... })`

Triggers a refetch. You typically don’t call this directly unless you’re building a higher-level wrapper; prefer the built-in “start fetch” behavior from `createResource*`.

In this repo’s demos, we usually expose a “Refetch” button that calls the function returned by your own wrapper.

Each resource has:

- `value` (nullable until resolved)
- `loading`
- `error`

:::demo id=runtime-resources-basic title="createResource (simulated fetch)"
Starts loading immediately and resolves after a short delay; click “Refetch” to run again.
:::

:::code file=src/docs/examples/runtime_resources_basic.dart region=snippet lang=dart
:::

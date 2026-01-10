---
title: Ownership & cleanup
slug: runtime-ownership
group: Runtime
order: 20
description: createRoot/createChildRoot and lifecycle cleanup with onCleanup.
status: beta
tags: [runtime]
---

Ownership controls lifetimes. Any effects/listeners/resources created within an owner are disposed when that owner is disposed.

## Functions

### `createRoot((dispose) => ...)`

Creates a root owner and runs your function inside it.

Use it at integration boundaries (mounting an app, running a test) when you want a single `dispose()` handle.

```dart
final dispose = createRoot<Dispose>((dispose) {
  createEffect(() {/* ... */});
  return dispose;
});
dispose();
```

### `createChildRoot((dispose) => ...)`

Creates a child owner under the current owner.

Use it when you want a sub-scope you can dispose independently (modal subtree, per-route subtree, per-item subtree).

```dart
late Dispose disposeChild;
createRoot<void>((_) {
  createChildRoot<void>((d) {
    disposeChild = d;
    createEffect(() {/* child-only */});
  });
});
disposeChild(); // does not affect the parent
```

### `onCleanup(fn)`

Registers a cleanup callback that runs when the current computation reruns and/or the owner is disposed.

Use it to remove listeners, clear timers, cancel subscriptions, and detach DOM.

```dart
createEffect(() {
  final id = web.window.setInterval((_) {}, 200);
  onCleanup(() => web.window.clearInterval(id));
});
```

### `getOwner()` + `runWithOwner(owner, fn)`

`getOwner()` returns the current owner (or `null`). `runWithOwner` runs `fn` with the given owner as current.

Use it to “re-enter” an owner from async callbacks so ownership-scoped APIs keep working.

```dart
final owner = getOwner();
someAsyncThing().then((_) {
  runWithOwner(owner, () {
    // safe to call createChildRoot/onCleanup/etc
  });
});
```

In this codebase, `render(mount, view)` creates a root owner, and DOM helpers like `on(el, ...)` automatically register cleanups.

:::demo id=runtime-ownership-basic title="createChildRoot cleanup"
Creates a child root that increments a counter every 200ms; stopping disposes it and stops the timer.
:::

:::code file=src/docs/examples/runtime_ownership_basic.dart region=snippet lang=dart
:::

---
title: Reactivity (signals + effects)
slug: runtime-reactivity
group: Runtime
order: 10
description: Signals, memos, effects, render effects, and batching.
status: beta
tags: [runtime]
---

This runtime provides a Solid-like reactive core.

## Overview

The runtime is **fine-grained**: computations subscribe to the exact signals they read. When a signal changes, only the dependent computations rerun.

## Functions

### `createSignal(initial)`

Creates a mutable reactive value.

Use it when you need state that can change over time (counters, toggles, filters).

```dart
final count = createSignal(0);
count.value = count.value + 1;
```

### `createMemo(compute)`

Creates a derived reactive value. It caches and only recomputes when its dependencies change.

Use it when you want a computed value that can be read from many places without recomputing each time.

```dart
final first = createSignal("Ada");
final last = createSignal("Lovelace");
final full = createMemo(() => "${first.value} ${last.value}");
```

### `createEffect(fn)`

Runs `fn` whenever its dependencies change (tracked reads inside `fn`). It runs after render effects.

Use it for non-DOM side effects (logging, calling an API, syncing to storage).

```dart
createEffect(() {
  final v = full.value; // tracked
  // e.g. persist v, log it, etc.
});
```

### `createRenderEffect(fn)`

Like `createEffect`, but runs at higher priority and is intended for **DOM writes**.

Use it for DOM mutations that must stay in sync with reactive reads.

```dart
import "package:web/web.dart" as web;

createRenderEffect(() {
  web.document.title = "count=${count.value}";
});
```

### `batch(fn)`

Coalesces multiple writes into a single flush.

Use it when you want to update multiple signals “together” (avoid intermediate renders).

```dart
batch(() {
  first.value = "Grace";
  last.value = "Hopper";
});
```

### `untrack(fn)`

Runs `fn` without tracking dependencies (reads inside won’t subscribe).

Use it when you need to read reactive state but **don’t** want to rerun when it changes.

```dart
createEffect(() {
  // tracked dependency:
  final v = count.value;
  // untracked read:
  final snapshot = untrack(() => full.value);
  // ...
});
```

:::demo id=runtime-reactivity-basic title="Signals + memo"
Incrementing updates a signal; the derived memo updates automatically.
:::

:::code file=src/docs/examples/runtime_reactivity_basic.dart region=snippet lang=dart
:::

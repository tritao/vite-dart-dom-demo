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

Key primitives:

- `createSignal(initial)` → mutable reactive value
- `createMemo(compute)` → derived reactive value (cached)
- `createEffect(fn)` → runs after render effects
- `createRenderEffect(fn)` → higher-priority, intended for DOM writes
- `batch(fn)` → coalesce multiple updates into one flush
- `untrack(fn)` → run without tracking dependencies

:::demo id=runtime-reactivity-basic title="Signals + memo"
Incrementing updates a signal; the derived memo updates automatically.
:::

:::code file=src/docs/examples/runtime_reactivity_basic.dart region=snippet lang=dart
:::


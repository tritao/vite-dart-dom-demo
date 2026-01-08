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

- `createRoot((dispose) => ...)` creates a root owner (returns your function result).
- `createChildRoot((dispose) => ...)` creates a child owner under the current owner.
- `onCleanup(fn)` registers cleanup for the current computation or owner.

In this codebase, `render(mount, view)` creates a root owner, and DOM helpers like `on(el, ...)` automatically register cleanups.

:::demo id=runtime-ownership-basic title="createChildRoot cleanup"
Creates a child root that increments a counter every 200ms; stopping disposes it and stops the timer.
:::

:::code file=src/docs/examples/runtime_ownership_basic.dart region=snippet lang=dart
:::


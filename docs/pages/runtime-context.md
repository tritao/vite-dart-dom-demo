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

- `createContext(defaultValue)`
- `useContext(ctx)`
- `provideContext(ctx, value, () => ...)`

Unlike widget frameworks, this context is **not** tied to a DOM tree automatically; it’s tied to the current reactive owner/call scope when you call `provideContext`.

:::demo id=runtime-context-basic title="provideContext scope"
Shows default value vs provided value within a scope.
:::

:::code file=src/docs/examples/runtime_context_basic.dart region=snippet lang=dart
:::


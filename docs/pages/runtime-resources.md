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

- `createResource(fetcher)`
- `createResourceWithSource(source, fetcher)`

Each resource has:

- `value` (nullable until resolved)
- `loading`
- `error`

:::demo id=runtime-resources-basic title="createResource (simulated fetch)"
Starts loading immediately and resolves after a short delay; click “Refetch” to run again.
:::

:::code file=src/docs/examples/runtime_resources_basic.dart region=snippet lang=dart
:::


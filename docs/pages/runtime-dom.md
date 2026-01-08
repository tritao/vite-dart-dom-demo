---
title: DOM helpers
slug: runtime-dom
group: Runtime
order: 30
description: render/text/insert/attr/prop/style/classList/on/Portal helpers.
status: beta
tags: [runtime]
---

The `solid_dom` helpers provide “Solid-style DOM” building blocks:

- `render(mount, () => Node|Iterable<Node>)`
- `text(() => "...")` and `insert(parent, () => dynamic content)`
- `attr/prop/classList/style` for reactive bindings
- `on(target, "event", handler)` with automatic cleanup
- `Portal(children: ...)` to render outside normal layout

:::demo id=runtime-dom-basic title="text + insert"
Shows `text()` and `insert()` updating a small list reactively.
:::

:::code file=src/docs/examples/runtime_dom_basic.dart region=snippet lang=dart
:::


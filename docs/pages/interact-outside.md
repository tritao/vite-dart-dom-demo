---
title: InteractOutside
slug: interact-outside
group: Foundations
order: 30
description: Outside interaction detection (pointer + focus) for dismissable overlays.
labHref: "?lab=popover"
status: beta
tags: [overlay]
---

InteractOutside is the behavior behind dismissable overlays: detect pointer/focus interactions that occur outside a layer, and decide whether to dismiss.

In this codebase, that behavior is implemented by **dismissableLayer** (layer stack + exclusions + topmost checks) with options like:

- `dismissOnFocusOutside`
- `disableOutsidePointerEvents`
- `preventClickThrough`

:::demo id=interact-outside-basic title="Outside click dismiss + click-through prevention"
Clicking “Outside action” should **not** activate on the same click that dismisses the layer.
:::

:::code file=src/docs/examples/interact_outside_basic.dart region=snippet lang=dart
:::

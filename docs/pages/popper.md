---
title: Popper / Positioning
slug: popper
group: Foundations
order: 40
description: Position floating elements relative to anchors (via attachPopper).
labHref: "?lab=popover"
status: beta
tags: [overlay, positioning]
---

Popper is the positioning layer used by Popover/Tooltip/Menu/Select/Combobox.

The shared helper is `attachPopper(...)`, which delegates to Floating UI when available and falls back to a simple fixed-position algorithm.

Common options:

- `placement`: e.g. `bottom-start`
- `flip`: keep in viewport by flipping sides when near edges
- `slide` / `overlap`: viewport constraints behavior
- `sameWidth` / `fitViewport`: sizing behavior
- `hideWhenDetached`: hide when anchor is offscreen

:::demo id=popper-basic title="AttachPopper basic"
Open the popper, then resize the viewport or scroll to see it re-position.
:::

:::code file=src/docs/examples/popper_basic.dart region=snippet lang=dart
:::

---
title: Overlay
slug: overlay
group: Foundations
order: 10
description: Portal + presence + layer stack primitives for building overlays.
labHref: "?lab=overlay"
status: beta
tags: [overlay, a11y]
---

Overlays are UI surfaces that float above normal content (dialogs, popovers, menus, tooltips, toasts).

This project’s overlay foundation is built around:

- **Portal**: render outside normal layout to avoid clipping.
- **Presence**: mount/unmount with an exit duration for animations.
- **dismissableLayer**: outside-interaction detection + optional pointer blocking + click-through prevention.
- **scrollLock / ariaHideOthers**: modal semantics helpers.

:::demo id=overlay-basic title="Dismissable layer"
Opens a floating panel in a Portal. Clicking outside dismisses it (and prevents click-through).
:::

:::code file=src/docs/examples/overlay_basic.dart region=snippet lang=dart
:::

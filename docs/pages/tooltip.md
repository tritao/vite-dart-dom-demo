---
title: Tooltip
slug: tooltip
group: Overlays & Menus
order: 30
description: Small anchored label shown on hover or focus.
labHref: "/?solid=tooltip"
status: beta
tags: [overlay, popper, a11y]
---

A tooltip is a small, anchored label for supplemental context.

## Features

- **Hover + focus**: appears on pointer hover and keyboard focus.
- **Keyboard-friendly**: focuses show tooltip; Escape can dismiss.
- **Positioning**: Popper-driven flip/shift behavior.

## Anatomy

- **Trigger**: the element that owns the tooltip.
- **Portal**: renders outside layout.
- **Content**: floating tooltip body.

:::demo id=tooltip-basic title="Basic tooltip"
Hover or focus the button to show a tooltip.
:::

:::code file=src/docs/examples/tooltip_basic.dart region=snippet lang=dart
:::

:::props name=Tooltip
:::


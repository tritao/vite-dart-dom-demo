---
title: Popover
slug: popover
group: Overlays & Menus
order: 20
description: Anchored floating panel for non-modal interactions.
labHref: "/?solid=popover"
status: beta
tags: [overlay, popper]
---

A popover is an anchored overlay for lightweight, non-modal UI (e.g. menus, pickers, help panels).

## Features

- **Anchored positioning**: uses Popper (Floating UI) for flip/shift/size behavior.
- **Non-modal by default**: focus is not trapped; users can interact with the page.
- **Dismiss behaviors**: Escape and outside interactions can close it (configurable).
- **Click-through prevention**: the outside click that dismisses shouldn’t also “activate” what’s behind.

## Anatomy

- **Trigger / anchor**: element the popover is positioned against.
- **Portal**: the panel renders outside normal layout to avoid clipping.
- **Content/panel**: the floating surface.

:::demo id=popover-basic title="Basic popover"
Anchored panel with Escape + outside click dismiss.
:::

:::code file=src/docs/examples/popover_basic.dart region=snippet lang=dart
:::

:::props name=Popover
:::


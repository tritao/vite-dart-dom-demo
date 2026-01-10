---
title: Menubar
slug: menubar
group: Overlays & Menus
order: 50
description: Horizontal menubar with roving focus and menu popups.
labHref: "?lab=menubar"
status: beta
tags: [menu, a11y]
---

A menubar is a horizontal menu root (often app-level navigation) that opens menus per top-level item.

## Features

- **Roving focus**: ArrowLeft/ArrowRight moves between top-level menus.
- **Menu semantics**: menu content uses the shared menu behavior (typeahead, disabled skipping).
- **Submenus**: nested menu support.

## Anatomy

- **Menubar root**: the horizontal container.
- **Top-level menus**: trigger + menu content.
- **Menu items**: actions, checkbox items, radio groups, submenus.

:::demo id=menubar-basic title="Basic menubar"
Top-level menus with roving focus between triggers.
:::

:::code file=src/docs/examples/menubar_basic.dart region=snippet lang=dart
:::

:::props name=Menubar
:::

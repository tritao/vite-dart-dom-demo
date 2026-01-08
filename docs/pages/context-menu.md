---
title: ContextMenu
slug: context-menu
group: Overlays & Menus
order: 60
description: Right-click / long-press menu anchored to a point.
labHref: "/?solid=contextmenu"
status: beta
tags: [menu, overlay]
---

A context menu opens on right-click (and optionally long-press) at a point, rather than anchored to a trigger element.

## Features

- **Point positioning**: opens at the pointer location (with viewport clamping).
- **Keyboard navigation**: same menu behavior as DropdownMenu/Menubar.
- **Dismiss behaviors**: Escape, outside interactions, and selection close.

## Anatomy

- **Target area**: element that listens for contextmenu.
- **Menu content**: floating menu at a point.
- **Items**: actions, checkbox items, radio groups, submenus.

:::demo id=context-menu-basic title="Basic context menu"
Right-click in the area to open a context menu.
:::

:::code file=src/docs/examples/context_menu_basic.dart region=snippet lang=dart
:::

:::props name=ContextMenu
:::


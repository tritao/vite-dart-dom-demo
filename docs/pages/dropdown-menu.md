---
title: DropdownMenu
slug: dropdown-menu
group: Overlays & Menus
order: 40
description: Button-triggered menu with typeahead and submenus.
labHref: "?lab=dropdownmenu"
status: beta
tags: [menu, overlay, a11y]
---

A dropdown menu is a button-triggered menu pattern built on the Menu + overlay foundations.

## Features

- **Keyboard navigation**: Arrow keys, Home/End, typeahead, disabled skipping.
- **Submenus**: supports nested menus with “pointer grace” handling.
- **Dismiss behaviors**: Escape, outside interactions, and selection close.

## Anatomy

- **Trigger**: a button that opens the menu.
- **Content**: the menu surface (`role="menu"`).
- **Items**: actions, checkbox items, radio groups, submenu triggers.

:::demo id=dropdown-menu-basic title="Basic dropdown menu"
Minimal dropdown menu with a few items and typeahead.
:::

:::code file=src/docs/examples/dropdown_menu_basic.dart region=snippet lang=dart
:::

:::props name=DropdownMenu
:::

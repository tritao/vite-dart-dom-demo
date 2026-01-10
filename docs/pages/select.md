---
title: Select
slug: select
group: Selection
order: 10
description: Button-triggered listbox with typeahead and focus management.
labHref: "?lab=select"
status: beta
tags: [selection, listbox, popper]
---

A select is a button-triggered listbox popup that lets a user choose one option.

## Features

- **Keyboard navigation**: Arrow keys, Home/End, PageUp/PageDown, typeahead.
- **Virtual focus**: uses `aria-activedescendant` to keep focus on the trigger while “highlighting” options.
- **Positioning**: Popper-driven placement, with `fitViewport` to clamp height on short viewports.

## Anatomy

- **Trigger**: button that shows the current value and opens the popup.
- **Popup**: positioned surface containing the listbox.
- **Listbox + options**: options with disabled support.

## FormField integration

Wrap the trigger button directly:

- `FormField(control: trigger, a11yTarget: trigger, ...)`

:::demo id=select-basic title="Basic select"
Open, navigate with Arrow keys, press Enter to select.
:::

:::code file=src/docs/examples/select_basic.dart region=snippet lang=dart
:::

:::props name=Select
:::

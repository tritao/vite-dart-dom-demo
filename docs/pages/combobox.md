---
title: Combobox
slug: combobox
group: Selection
order: 20
description: Text input with listbox suggestions and selection.
labHref: "?solid=combobox"
status: beta
tags: [selection, listbox, popper]
---

A combobox is a text input that opens a listbox of suggestions and supports selection via keyboard/mouse.

## Features

- **Text input + popup**: input remains focused while navigating the suggestion list (virtual focus).
- **Typeahead filtering**: suggestions update as you type.
- **Keyboard navigation**: Arrow keys to move highlight; Enter to commit selection.
- **Close on selection (default)**: selecting an option commits the value and closes the popup.

## Anatomy

- **Input**: `role="combobox"` with appropriate aria wiring.
- **Popup**: positioned surface containing a listbox.
- **Listbox + options**: suggestion items.

:::demo id=combobox-basic title="Basic combobox"
Type to filter, ArrowDown to navigate, Enter/click to select (popup closes by default).
:::

:::code file=src/docs/examples/combobox_basic.dart region=snippet lang=dart
:::

:::props name=Combobox
:::

---
title: Listbox
slug: listbox
group: Selection
order: 30
description: A selectable list with keyboard navigation and virtual focus.
labHref: "/?solid=listbox"
status: beta
tags: [selection, a11y]
---

A listbox is a list of selectable options with robust keyboard interaction.

## Features

- **Selection core**: powered by the selection manager (highlightedKey + selection rules).
- **Virtual focus**: `aria-activedescendant` keeps focus on the listbox root while highlighting options.
- **Disabled handling**: disabled options are skipped during navigation.

## Anatomy

- **Listbox root**: element with `role="listbox"`.
- **Options**: elements with `role="option"` and stable ids.

:::demo id=listbox-basic title="Basic listbox"
Arrow keys move highlight; Enter selects.
:::

:::code file=src/docs/examples/listbox_basic.dart region=snippet lang=dart
:::

:::props name=Listbox
:::


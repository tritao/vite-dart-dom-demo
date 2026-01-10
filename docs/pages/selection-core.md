---
title: Selection core
slug: selection-core
group: Selection
order: 0
description: SelectionManager + selectable collection/item utilities.
labHref: "?lab=selection"
status: beta
tags: [selection, a11y]
---

Selection core is the reusable behavior behind list-style navigation:

- **SelectionManager**: tracks `focusedKey`, `selectedKeys`, selection mode/behavior.
- **createSelectableCollection**: keyboard navigation, focus tracking, typeahead.
- **createSelectableItem**: pointer/keyboard selection and focus updates per item.

This powers Listbox/Select/Combobox, and any custom “roving selection” UI.

:::demo id=selection-core-basic title="Minimal selectable collection"
Use Arrow keys to move focus (disabled is skipped); press Enter/Space to select.
:::

:::code file=src/docs/examples/selection_core_basic.dart region=snippet lang=dart
:::

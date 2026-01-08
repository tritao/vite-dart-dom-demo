---
title: Checkbox
slug: checkbox
group: Forms
order: 5
description: Accessible checkbox with indeterminate support.
status: beta
tags: [forms, a11y]
---

A checkbox is a boolean control (checked/unchecked) that can also support an indeterminate “mixed” state.

## Features

- **ARIA wiring**: uses `role="checkbox"` + `aria-checked` ("true" | "false" | "mixed").
- **Indeterminate**: optional “mixed” state for partial selection.
- **Keyboard support**: Space/Enter toggles.

## Anatomy

- **Root**: clickable element with `role="checkbox"`.
- **Label**: typically a separate element (e.g. a `<label>` wrapping the control + text).

:::demo id=checkbox-basic title="Basic checkbox"
Click or press Space/Enter to toggle.
:::

:::code file=src/docs/examples/checkbox_basic.dart region=snippet lang=dart
:::

:::props name=Checkbox
:::


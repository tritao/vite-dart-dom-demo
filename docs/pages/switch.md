---
title: Switch
slug: switch
group: Forms
order: 10
description: Accessible boolean toggle.
labHref: "/?solid=switch"
status: beta
tags: [forms, a11y]
---

A switch is a boolean control (on/off) similar to a checkbox, often styled as a toggle.

## Features

- **Keyboard support**: Space toggles; focus ring behaves like a form control.
- **ARIA wiring**: uses `role="switch"` and `aria-checked`.
- **Controlled state**: you manage the value via signals/state.

## Anatomy

- **Root**: clickable element with `role="switch"`.
- **Thumb/track**: visuals (styling is up to you).

:::demo id=switch-basic title="Basic switch"
Toggle a boolean value.
:::

:::code file=src/docs/examples/switch_basic.dart region=snippet lang=dart
:::

:::props name=Switch
:::


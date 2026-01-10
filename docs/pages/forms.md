---
title: Forms
slug: forms
group: Forms
order: -100
description: Form primitives and styling conventions.
status: beta
tags: [forms, a11y]
---

This section covers Solidus form building blocks and how to compose them accessibly.

Start with:

- [`FormField`](?docs=form-field): label/description/error wiring (`aria-describedby`, `aria-invalid`).
- [`Input`](?docs=input) and [`Textarea`](?docs=textarea): controlled text controls.
- [`Label`](?docs=label) and [`Fieldset`](?docs=fieldset): grouping + association helpers.

Then:

- [`Checkbox`](?docs=checkbox)
- [`RadioGroup`](?docs=radio-group)
- [`ToggleGroup`](?docs=toggle-group)
- [`Switch`](?docs=switch)

## Composite controls

Some controls are composite DOM structures (e.g. Combobox uses a wrapper + input + button + popup).

Guidelines:

- Wrap the **visible control UI** with `FormField(control: ...)`.
- Point accessibility wiring at the **real focusable control** with `a11yTarget` (usually the `<input>` or trigger button).

Example:

- Combobox: `FormField(control: anchor, a11yTarget: input, ...)`

## UI helpers

Use `solidus_ui` helpers to keep scaffolding consistent:

- `buildInputGroup(...)`
- `buildSelectControl(...)`
- `buildComboboxControl(...)`

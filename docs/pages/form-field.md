---
title: FormField
slug: form-field
group: Forms
order: 2
description: Label + description + error wiring for a control.
status: beta
tags: [forms, a11y]
---

`FormField` composes a label, description, and error message around a control and wires:

- `<label for=...>` → the control `id`
- `aria-describedby` → description/error ids
- `aria-invalid` → when error is present

:::demo id=form-field-basic title="Basic FormField"
Shows description and error wiring.
:::

:::code file=src/docs/examples/form_field_basic.dart region=snippet lang=dart
:::

:::props name=FormField
:::


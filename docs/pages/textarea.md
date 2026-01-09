---
title: Textarea
slug: textarea
group: Forms
order: 3
description: Multiline text input.
status: beta
tags: [forms, ui]
---

A styled `<textarea>` control.

:::demo id=textarea-basic title="Controlled textarea"
The value is stored in a signal.
:::

:::code file=src/docs/examples/textarea_basic.dart region=snippet lang=dart
:::

## Autosize

If you want the textarea to grow with its content, use:

- `Textarea(autosize: true, ...)` (recommended), or
- `TextareaAutosize(...)` (equivalent wrapper).

:::demo id=textarea-autosize-basic title="Autosize textarea"
Type multiple lines to expand the height.
:::

:::code file=src/docs/examples/textarea_autosize_basic.dart region=snippet lang=dart
:::

:::props name=Textarea
:::

:::props name=TextareaAutosize
:::

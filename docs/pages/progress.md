---
title: Progress
slug: progress
group: UI
order: 3
description: Determinate and indeterminate progress bar.
status: beta
tags: [ui, a11y]
---

A progress bar visualizes the completion of an operation.

## Features

- **Determinate**: provide `value()` to set progress (uses `aria-valuenow`).
- **Indeterminate**: return `null` from `value()` to show a looping indicator.

:::demo id=progress-basic title="Progress"
Determinate + indeterminate progress.
:::

:::code file=src/docs/examples/progress_basic.dart region=snippet lang=dart
:::

:::props name=Progress
:::


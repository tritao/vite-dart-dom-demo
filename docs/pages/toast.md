---
title: Toast
slug: toast
group: Overlays & Menus
order: 70
description: Non-blocking notifications with stacking and timeouts.
labHref: "/?solid=toast"
status: beta
tags: [overlay]
---

Toasts are transient notifications that don’t block interaction.

## Features

- **Stacking**: multiple toasts render in a viewport corner.
- **Timeouts**: auto-dismiss after a duration, with manual close support.
- **Accessible region**: toasts are intended to be screen-reader friendly (polite updates).

## Anatomy

- **Toaster controller**: creates/dismisses toasts, controls placement and durations.
- **Viewport**: where toasts render (usually fixed-position).
- **Toast item**: content + close.

:::demo id=toast-basic title="Basic toast"
Creates a toaster and pushes a toast on button press.
:::

:::code file=src/docs/examples/toast_basic.dart region=snippet lang=dart
:::

:::props name=Toast
:::


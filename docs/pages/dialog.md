---
title: Dialog
slug: dialog
group: Overlays & Menus
order: 10
description: Modal/non-modal overlay with focus management and dismiss behavior.
labHref: "/?solid=dialog"
status: beta
tags: [overlay, a11y]
---

A dialog is an overlay for focused user interaction.

:::demo id=dialog-basic title="Basic dialog"
A minimal modal dialog with backdrop, focus trap, Escape + outside-click dismiss, and focus restore.
:::

:::code file=src/docs/examples/dialog_basic.dart region=snippet lang=dart
:::

:::note
Prefer `labelledBy` and `describedBy` so assistive tech can announce a useful name/description.
:::

:::props name=Dialog
:::


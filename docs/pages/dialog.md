---
title: Dialog
slug: dialog
group: Overlays & Menus
order: 10
description: Modal/non-modal overlay with focus management and dismiss behavior.
labHref: "?lab=dialog"
status: beta
tags: [overlay, a11y]
---

A dialog is an overlay for focused user interaction.

## Features

- **Modal + non-modal**: set `modal: true` (default) for focus trapping + outside interaction blocking; set `modal: false` for a non-modal overlay.
- **Dismiss behaviors**: Escape closes; outside interactions can dismiss (depending on your usage and modal setting).
- **Focus management**: focus trap (modal), restore focus to trigger (default), `initialFocus`, and preventable autofocus hooks.
- **A11y defaults**: `role="dialog"` + `aria-modal="true"` (modal), with `aria-labelledby` / `aria-describedby` wiring.
- **Stacking**: nested dialogs should restore aria/scroll/focus state correctly when closing the topmost one.

## Anatomy

Conceptually, a dialog is made of:

- **Trigger**: the button/link that sets `open=true`.
- **Portal**: the dialog renders outside normal layout to avoid clipping.
- **Backdrop (optional)**: dimmer behind the panel (`backdrop: true`).
- **Content/panel**: the element with `role="dialog"` (or `"alertdialog"`), labelled/ described by your title/description.
- **Title + description**: referenced via `labelledBy` / `describedBy`.
- **Close action**: a button inside the panel that calls `close()` (and/or `setOpen(false)`).

A typical structure looks like:

```text
Trigger
└─ Portal
   └─ Wrapper (optional)
      ├─ Backdrop (optional)
      └─ Content (role=dialog, aria-*)
         ├─ Title (id=labelledBy)
         ├─ Description (id=describedBy)
         └─ Actions (Close, etc)
```

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

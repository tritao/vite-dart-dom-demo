---
title: Accordion
slug: accordion
group: Navigation
order: 20
description: Expand/collapse sections with keyboard support.
labHref: "/?solid=accordion"
status: beta
tags: [a11y, navigation]
---

An accordion groups content into expandable sections.

## Features

- **Single or multiple**: allow one open section or many (depending on configuration).
- **Keyboard support**: Arrow keys move between headers; Enter/Space toggles.
- **ARIA wiring**: button + region with `aria-expanded` and `aria-controls`.

## Anatomy

- **Item**: header + content region.
- **Header/trigger**: interactive element that toggles content.
- **Panel**: collapsible content region.

:::demo id=accordion-basic title="Basic accordion"
Toggle sections and navigate headers with the keyboard.
:::

:::code file=src/docs/examples/accordion_basic.dart region=snippet lang=dart
:::

:::props name=Accordion
:::


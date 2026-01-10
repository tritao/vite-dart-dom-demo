---
title: Tabs
slug: tabs
group: Navigation
order: 10
description: Tab list + tab panels with roving focus.
labHref: "?lab=tabs"
status: beta
tags: [a11y, navigation]
---

Tabs group related content into multiple panels, with only one panel visible at a time.

## Features

- **Roving focus**: Arrow keys move between tabs.
- **Selection**: Enter/Space activates a tab; active tab controls the visible panel.
- **ARIA wiring**: `role="tablist"`, `role="tab"`, `role="tabpanel"` with ids/controls.

## Anatomy

- **TabList**: container of tabs.
- **Tab**: interactive element selecting a panel.
- **TabPanel**: content region for the active tab.

:::demo id=tabs-basic title="Basic tabs"
Switch panels with keyboard or mouse.
:::

:::code file=src/docs/examples/tabs_basic.dart region=snippet lang=dart
:::

:::props name=Tabs
:::

---
title: Breadcrumbs
slug: breadcrumbs
group: Navigation
order: 5
description: Hierarchical navigation trail.
status: beta
tags: [navigation, a11y]
---

Breadcrumbs show the current page location within a hierarchy.

## Features

- **Semantic**: uses `role="navigation"` + `aria-label="breadcrumb"`.
- **Current page**: last item uses `aria-current="page"`.

:::demo id=breadcrumbs-basic title="Breadcrumbs"
A simple breadcrumb trail.
:::

:::code file=src/docs/examples/breadcrumbs_basic.dart region=snippet lang=dart
:::

:::props name=Breadcrumbs
:::


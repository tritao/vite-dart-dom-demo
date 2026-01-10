---
title: FocusScope
slug: focus-scope
group: Foundations
order: 20
description: Focus containment and trapping used by modal overlays.
labHref: "?lab=dialog"
status: beta
tags: [focus, a11y]
---

FocusScope provides focus containment and optional focus trapping.

It’s used by modal overlays (Dialog, menu subtrees) to ensure:

- Tab/Shift+Tab stays within the scope when `trapFocus: true`.
- Focus restores on unmount (unless you opt out).
- Autofocus behavior is controllable via preventable hooks.

:::demo id=focus-scope-basic title="Trap focus inside a box"
Tab should cycle within the box while it’s open; Escape closes it.
:::

:::code file=src/docs/examples/focus_scope_basic.dart region=snippet lang=dart
:::

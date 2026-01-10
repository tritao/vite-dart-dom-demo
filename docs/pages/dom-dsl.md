---
title: DOM DSL
slug: dom-dsl
group: Foundations
order: 5
description: Terse helpers for authoring DOM nodes in docs/demos and small UIs.
status: beta
tags: [dom, dsl, ui]
---

Solidus includes a small set of helper functions for authoring DOM nodes tersely.

They’re used throughout `src/docs/examples/*.dart`, but you can use them anywhere.

## Imports

If you’re already using Solidus UI components in docs/demos, you can import a single entrypoint:

```dart
import "package:solidus/solidus_ui.dart";
```

If you want foundations + primitives (overlays, positioning, etc.), this also re-exports the DSL:

```dart
import "package:solidus/solidus_dom.dart";
```

## Core helpers

- `div(...)`: `<div>`
- `p(...)`: `<p>`
- `h1(...)`, `h2(...)`
- `span(...)`
- `ul(...)`, `li(...)`
- `row(...)`: `div(className: "row", ...)` (flex row)
- `stack(...)`: `div(className: "stack", ...)` (vertical stack)
- `col(...)`: alias of `stack(...)`

All helpers accept:

- `className` (merged with the base class for `row/stack`)
- `attrs` for attributes
- `children: List<web.Node>` so you can mix elements, text nodes, and reactive `text(() => ...)`

## Example

```dart
import "package:solidus/solidus.dart";
import "package:solidus/solidus_ui.dart";
import "package:web/web.dart" as web;

Dispose mountExample(web.Element mount) {
  return render(mount, () {
    final count = createSignal(0);

    final inc = web.HTMLButtonElement()
      ..type = "button"
      ..className = "btn primary"
      ..textContent = "Increment";
    on(inc, "click", (_) => count.value++);

    return stack(children: [
      row(children: [
        inc,
        p("", className: "muted", children: [text(() => "count=${count.value}")]),
      ]),
      p("This is just DOM, not a component.", className: "muted"),
    ]);
  });
}
```

## When to use this

- Docs/demos and small interactive panels.
- Quick glue UIs around primitives (e.g. a `Popover` demo).

For reusable UI, prefer the Solidus UI primitives (Button, Dialog, Popover, etc.) and keep the DSL for layout and small bits of DOM.


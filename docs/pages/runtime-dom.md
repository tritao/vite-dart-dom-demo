---
title: DOM helpers
slug: runtime-dom
group: Runtime
order: 30
description: render/text/insert/attr/prop/style/classList/on/Portal helpers.
status: beta
tags: [runtime]
---

The `solid_dom` helpers provide “Solid-style DOM” building blocks:

## Functions

### `render(mount, view)`

Creates a root owner and mounts the nodes returned by `view()` into `mount`.

Use it as your “app mount” primitive.

```dart
Dispose dispose = render(mount, () => web.Text("Hello"));
dispose();
```

### `text(() => "...")`

Creates a text node whose contents update reactively.

Use it for reactive inline text.

```dart
final count = createSignal(0);
root.appendChild(text(() => "count=${count.value}"));
```

### `insert(parent, () => value)`

Inserts dynamic content between comment anchors.

Use it when the child content can change shape (null ↔ node ↔ list, conditional rendering, switching panels).

```dart
root.appendChild(insert(root, () => count.value.isEven ? "even" : "odd"));
```

### `attr(element, name, () => String?)`

Binds an attribute; removes it when the computed value is `null`.

Use it for ARIA and id/controls wiring.

```dart
attr(btn, "aria-expanded", () => open.value ? "true" : "false");
```

### `prop<T>(set, () => T)`

Binds an element property via a setter.

Use it for properties like `disabled`, `checked`, `value` where attributes aren’t enough.

```dart
prop<bool>((v) => input.disabled = v, () => isDisabled.value);
```

### `className(element, () => String)` / `classList(element, () => Map<String,bool>)`

Recomputes classes reactively.

Use `className` for a full string, or `classList` for toggling individual classes.

```dart
classList(root, () => {"active": open.value});
```

### `style(element, () => Map<String,String?>)`

Binds inline styles; removes a property when the computed value is `null`.

Use it for small dynamic styling without a full CSS system.

```dart
style(box, () => {"opacity": open.value ? "1" : "0.6"});
```

### `on(target, "event", handler)`

Adds an event listener with automatic cleanup.

Use it instead of `addEventListener` so listeners don’t leak when a subtree is disposed.

```dart
on(btn, "click", (_) => count.value++);
```

### `Portal(children: ...)` / `ensurePortalRoot()`

Renders into a global portal root (defaults to `#solidus-portal-root` in `document.body`).

Use it for overlays and floating UI that must escape overflow/stacking contexts.

```dart
final overlay = Portal(
  id: "my-overlay",
  children: () => web.HTMLDivElement()..textContent = "I'm on top",
);
```

### `Show(when: ..., children: ..., fallback: ...)`

Conditionally mounts/unmounts a subtree with proper disposal.

Use it for conditional UI instead of toggling `display: none` when lifecycle matters.

```dart
root.appendChild(
  Show(
    when: () => open.value,
    children: () => web.HTMLDivElement()..textContent = "Open",
    fallback: () => web.HTMLDivElement()..textContent = "Closed",
  ),
);
```

### `For(each: ..., key: ..., children: ...)`

Keyed list rendering that preserves DOM node identity across reorders.

Use it for long/lively lists where you want stable focus and minimal DOM churn.

```dart
final items = createSignal(<int>[1, 2, 3]);
root.appendChild(
  For<int, int>(
    each: () => items.value,
    key: (v) => v,
    children: (v) => web.HTMLDivElement()..textContent = "Item ${v()}",
  ),
);
```

:::demo id=runtime-dom-basic title="text + insert"
Shows `text()` and `insert()` updating a small list reactively.
:::

:::code file=src/docs/examples/runtime_dom_basic.dart region=snippet lang=dart
:::

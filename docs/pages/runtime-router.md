---
title: Routing (URL query + history)
slug: runtime-router
group: Runtime
order: 60
description: Tiny querystring router helpers for back/forward friendly state.
status: beta
tags: [runtime, router]
---

Solidus intentionally keeps routing minimal and **URL-query based**.

The helper API lives in `lib/dom_ui/router.dart` and is used by:

- the demo app route helpers (`src/app/route.dart`)
- the docs router (`src/docs/router.dart`)

For path-based routing (nested routes, params, Links), see: [Browser router (paths + params)](?docs=runtime-browser-router).

## API

### Read

#### `getQueryParam(key)`

Returns the current `?key=value` (or `null`).

Use it to read string params that drive state (tabs, filters, ids).

```dart
final tab = router.getQueryParam("tab") ?? "overview";
```

#### `getQueryFlag(key, defaultValue: false)`

Returns a boolean flag from `?key=1|true|0|false` (or a default).

Use it for feature flags and debug toggles.

```dart
final debug = router.getQueryFlag("debug");
```

### Write

#### `setQueryParam(key, value, replace: true)`

Updates the current URL querystring, keeping other params intact.

- `replace: true` (default) → `history.replaceState(...)` (does not add a new history entry)
- `replace: false` → `history.pushState(...)` (adds a history entry; back/forward will traverse it)

Passing `value: null` removes the key from the querystring.

### Back/forward

#### `listenPopState((uri) { ... })`

Lets you react to back/forward navigation.

It returns a dispose function you can call to stop listening.

### Docs slug normalization

The docs historically used `?docs=1` as “home”. `normalizeDocsSlug(slug)` treats:

- `null`, empty, or `"1"` → `"index"`
- anything else → unchanged

## Examples

### Toggle a feature flag (replaceState)

```dart
import 'package:solidus/dom_ui/router.dart' as router;

final debug = router.getQueryFlag('debug');
router.setQueryParam('debug', debug ? null : '1'); // default: replace=true
```

### Keep URLs clean (omit defaults)

```dart
import 'package:solidus/dom_ui/router.dart' as router;

// Default is "on"; only persist the non-default case.
final showUsers = router.getQueryFlag('showUsers', defaultValue: true);
router.setQueryParam('showUsers', showUsers ? null : '0');
```

### Switch between modes (preserves other params)

`setQueryParam` updates a single key while keeping the rest of the querystring intact.

```dart
import 'package:solidus/dom_ui/router.dart' as router;

// e.g. ?users=limited or ?users=all
router.setQueryParam('users', 'limited');
```

### Navigate between docs pages (pushState)

```dart
import 'package:solidus/dom_ui/router.dart' as router;

router.setQueryParam('docs', 'dialog', replace: false);
```

### Parse a typed param safely

```dart
import 'package:solidus/dom_ui/router.dart' as router;

int readPageSize({int fallback = 20}) {
  final raw = router.getQueryParam('pageSize');
  final parsed = raw == null ? null : int.tryParse(raw);
  return (parsed == null || parsed <= 0) ? fallback : parsed;
}
```

### React to back/forward

```dart
import 'package:solidus/dom_ui/router.dart' as router;

final stop = router.listenPopState((_) {
  final docs = router.normalizeDocsSlug(router.getQueryParam('docs'));
  // update your app state here
});

// later: stop();
```

### Docs-style slug signal (query → reactive state)

This is the pattern used in `src/docs/router.dart`: keep a signal in sync with the URL.

```dart
import 'package:solidus/solidus.dart';
import 'package:solidus/dom_ui/router.dart' as router;

final slug = createSignal(router.normalizeDocsSlug(router.getQueryParam('docs')));

final stop = router.listenPopState((_) {
  slug.value = router.normalizeDocsSlug(router.getQueryParam('docs'));
});

onCleanup(stop);
```

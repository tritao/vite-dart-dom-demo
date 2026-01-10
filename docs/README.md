# Docs authoring

Docs pages live in `docs/pages/**/*.md` and are compiled into static HTML under `public/assets/docs/` by `tool/build_docs.dart`.

## Routes

- `/?docs=1` → `docs/pages/index.md`
- `/?docs=<slug>` → `docs/pages/<slug>.md` (via frontmatter `slug`)

## Frontmatter

Each page starts with YAML frontmatter:

```yaml
---
title: Dialog
slug: dialog
group: Overlays & Menus
order: 10
description: ...
labHref: "?lab=dialog"
status: beta
tags: [overlay, a11y]
---
```

## Directives

### Demo

```md
:::demo id=dialog-basic title="Basic dialog"
Short description…
:::
```

This renders a placeholder `<div data-doc-demo="dialog-basic">…</div>` and the runtime mounts the matching demo from `src/docs/demos.dart`.

### Code

```md
:::code file=src/docs/examples/dialog_basic.dart region=snippet lang=dart
:::
```

The builder extracts a region between:

```dart
// #doc:region snippet
// #doc:endregion snippet
```

### Callouts

```md
:::note
...
:::
```

Also supports `:::warning` and `:::tip`.

## Props data

Props tables are driven by `docs/api/props.json`, copied to `public/assets/docs/props.json` at build time.

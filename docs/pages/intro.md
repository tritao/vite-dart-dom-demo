---
title: Introduction
slug: intro
group: Docs
order: 0
description: What this project is, and how the docs and labs are structured.
status: beta
tags: [docs]
---

This repo is a **Dart-on-the-web** playground that implements a **Solid-like reactive runtime** and a growing set of **Kobalte-inspired DOM primitives** (Dialog/Popover/Menu/Select/etc).

The goal is a robust, accessible UI foundation in Dart, with behavior parity validated by automated scenarios.

## How to navigate

- **Docs** (`/?docs=…`) are the clean, consumer-facing pages:
  - Minimal examples you’d actually copy/paste.
  - Short explanations of behavior and APIs.
  - Tables driven by `docs/api/*.json` where possible.
- **Labs** (`/?solid=…`) are the conformance harness:
  - Edge-case controls and “stress” scenarios.
  - Playwright-driven flows (`npm run debug:*`) for regression coverage.

## Structure

### Runtime

The Solid-like runtime lives under `lib/solid/` and is re-exported via `lib/solid.dart`.

Key concepts:

- **Signals / memos / effects**: `createSignal`, `createMemo`, `createEffect`, `createRenderEffect`.
- **Ownership**: `createRoot`, `createChildRoot`, `onCleanup` define lifetimes.
- **Async**: `createResource` and `createResourceWithSource` for reactive fetching.
- **Context**: `createContext`, `useContext`, `provideContext`.

### DOM helpers

DOM integration helpers live under `lib/solid_dom/solid_dom.dart` and are re-exported via `lib/solid_dom.dart`.

They provide Solid-style DOM building blocks:

- `render`, `Portal`
- `text`, `insert`
- `attr`, `prop`, `classList`, `style`
- `on` (auto-cleaned event listeners)

### UI primitives

The Kobalte-inspired primitives live under `lib/solid_dom/` (e.g. `dialog.dart`, `overlay.dart`, `menu.dart`, `select.dart`, `popper.dart`).

The most important foundations are documented under **Foundations**:

- Overlay / InteractOutside
- FocusScope
- Popper / Positioning
- Selection core

### Docs pipeline

Docs are authored in Markdown under `docs/pages/` and built via a Dart tool:

- Build: `npm run docs:build`
- Source: `docs/pages/**/*.md` + `docs/api/*.json`
- Output: `assets/docs/manifest.json`, `assets/docs/pages/*.html`, `assets/docs/props.json`
- Runtime loader: `src/docs/router.dart`

Directives supported today:

- `:::demo ...` mounts a live example from `src/docs/demos.dart`
- `:::code file=... region=...` embeds a snippet from source
- `:::props name=...` renders an API table from `docs/api/props.json`

## Contributing to docs

- Keep docs examples minimal; put edge cases in Labs.
- Prefer adding/maintaining `docs/api/*.json` so API tables stay consistent.
- Add a Playwright scenario when a behavior becomes important to guarantee.


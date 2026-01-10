# Solidus (Dart DOM) Maturity Checklist for a 3‑Panel Word Processor

This repo’s Solidus runtime (`lib/solidus/` + `lib/solidus_dom/`) is already sufficient for building the **application shell** (layout, navigation, panels, overlays, menus, forms, keyboard UX). The biggest product risk (rich-text editing) is intentionally delegated to a JS editor via interop.

Use this checklist to validate the Solid layer is “mature enough” for scaling to a real writing app.

## What “mature enough” means here

- No lifecycle leaks (listeners, timers, computations) during repeated mount/unmount.
- Predictable reactive updates under stress (large lists, frequent state changes).
- Correct focus/keyboard behavior for menus/combobox/select/dialog (a11y baseline).
- Overlay stacking and dismissal behavior remains correct with nesting.
- Debuggability: failures are reproducible and explainable.

## Existing automated confidence (current repo)

- Baseline smoke + console/network/page error capture: `npm run debug:ui`
- Labs scenarios:
  - `npm run debug:labs-dialog`
  - `npm run debug:labs-dropdownmenu`
  - `npm run debug:labs-select`
  - `npm run debug:labs-listbox`
  - `npm run debug:labs-combobox`
  - `npm run debug:labs-overlay`
  - `npm run debug:labs-toast`
  - `npm run debug:wordproc-shell` (3-panel stress shell)

## Core checklist (must-have before building “real” features)

### 1) Lifecycles + cleanup are reliable

- Toggle/mount/unmount subtrees repeatedly without accumulating:
  - document/window listeners
  - timers/microtasks that keep running
  - computations/effects that continue firing after dispose
- The new shell demo is a quick sanity check:
  - `/wordproc.html` and toggle “heavy subtree” a few times
  - or run `npm run debug:wordproc-shell` to assert cleanup happens

### 2) Reactive dependencies are explicit (no accidental coupling)

- Avoid effects that re-run because they *incidentally* read other signals.
- When you need to consult reactive state without tracking, use `untrack(...)`.
- Prefer “derived signals” (`createMemo`) for read-only computed state.

### 3) Lists don’t destroy performance

- For outliners with thousands of nodes, plan for **virtualization**:
  - don’t render 10k+ items in the DOM at once
  - keep keyed identity stable (`For(each, key, ...)`)
- Add a virtualized list primitive before you depend on large projects.

### 4) Focus + keyboard UX stays correct (a11y baseline)

- Ensure:
  - roving tabIndex groups behave predictably
  - `aria-activedescendant` patterns work for listbox/combobox
  - dialogs trap focus and restore it on close
  - escape/outside click dismiss only the topmost layer
- Existing scenarios cover most of this; expand them as you compose primitives.

### 5) Overlay stacking behaves under nesting

- Validate compositions like:
  - dialog → popover → menu
  - dialog + toast interactions (toast clickable, modal stays modal)
- Keep a dedicated “nesting demo” scenario (see `CONFIDENCE_PLAN.md`).

## Interop checklist (for JS editor integration)

- Mount the JS editor into a dedicated element (e.g. `#wordproc-editor-mount`).
- Treat the editor as an imperative widget:
  - JS owns DOM inside the mount node
  - Dart owns app state and “current section” selection
- Communication contract:
  - JS → Dart: `CustomEvent("editor:changed", { detail: {...} })`
  - Dart → JS: exported functions for `setDoc/getDoc/applyTransaction`
- Key constraints:
  - Never let both systems mutate the same DOM subtree.
  - Ensure disposal/unmount tears down editor listeners and observers.

## Debuggability checklist (should-have)

- Add stable `data-testid` hooks for tests (avoid brittle CSS selectors).
- Add a tiny per-demo “debug panel” that displays:
  - selected keys / active descendant
  - open layer stack
  - last event + last dismiss reason
- Make flaky timing bugs easier to reproduce:
  - repeat runs (`--repeat N`) and small deterministic jitter (see `CONFIDENCE_PLAN.md`)

## Practical recommendation

- Build the writing app shell (panels, navigation, storage model, agent UI) on Solid DOM now.
- Before committing to “writer-grade” features (track changes, comments, inline diff UX), add:
  - list virtualization
  - a nesting overlay scenario
  - repeat/jitter harness support

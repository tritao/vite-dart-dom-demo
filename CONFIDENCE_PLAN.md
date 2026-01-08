# Confidence Plan (Solid DOM Primitives)

Goal: increase confidence in correctness/robustness (Kobalte-style behavior) beyond the current “happy-path” Playwright smoke checks.

Related: `KOBALTE_AUDIT.md` (module order + Kobalte→Dart source mapping for the audit).

## Scope
- Selection core (`createSelectableCollection/item`, `SelectionManager`)
- Listbox core + virtual focus (`aria-activedescendant`)
- Components: `Menu`, `Listbox`, `Select`, `Combobox`
- Overlays: `Dialog`, `Popover`, `Tooltip`, `Toast`, `dismissableLayer` pointer-blocking + stacking

## Phase 1 — Add missing invariants (Playwright)

### 1) OptionBuilder reactivity (Listbox/Select/Combobox)
**Why:** current `optionBuilder(option, selected, active)` inputs are not guaranteed reactive; real components will style/ARIA off them.

**Deliverables**
- New demo route: `/?solid=optionbuilder` (or extend existing demos) that:
  - renders options via `optionBuilder` using `active/selected` props to set:
    - `data-active-from-builder`
    - `data-selected-from-builder`
    - visible styling/text markers (so screenshots/debug are readable)
  - exercises: keyboard navigation, hover focus, selection, disabled skipping.
- Playwright scenario:
  - asserts builder-driven markers update correctly when:
    - ArrowDown/ArrowUp moves active
    - hover moves active (mouse-only)
    - Enter selects
  - asserts invariants:
    - `activeId == aria-activedescendant == [data-active=true].id` (virtual focus components)

### 2) Modal pointer-blocking + top-layer clickability (Dialog + Toast)
**Why:** modal pointer-blocking is easy to regress; toasts must remain clickable and must not dismiss the modal.

**Deliverables**
- Extend `/?solid=dialog` or `/?solid=toast` to include:
  - “Open modal dialog” button
  - “Show toast” button while modal is open
  - toast includes a clickable dismiss button
  - dialog has a visible “outside click counter” (or last dismiss reason)
- Playwright scenario:
  - open modal dialog (pointer-blocking active)
  - show toast
  - click toast dismiss button
  - assert:
    - toast count decreases
    - dialog remains open
    - dialog dismiss reason is unchanged (no accidental outside-dismiss)

### 3) Nested layer stacking correctness
**Why:** most subtle bugs happen with nested overlays (dialog → popover → menu).

**Deliverables**
- Add a demo composition:
  - open dialog
  - open popover inside dialog
  - open menu inside popover
- Playwright scenario asserts:
  - outside click dismisses only the topmost open layer
  - Escape dismisses only the topmost open layer
  - focus-outside behaves like Kobalte expectations (no parent dismissal)

## Phase 2 — Flake hunting (repeat + jitter)

### 4) Loop runs
**Why:** timing bugs show up as flakes.

**Deliverables**
- Add a `--repeat N` option to `scripts/debug-ui.mjs` (default 1).
- Run key scenarios with `--repeat 50` locally:
  - `solid-select`, `solid-combobox`, `solid-dialog`, `solid-overlay`, `solid-dropdownmenu`.

### 5) Seeded random jitter
**Why:** microtask/effect ordering issues often need event timing variance.

**Deliverables**
- Add `--jitter-ms <max>` (seeded) that introduces small delays between scripted interactions.
- Keep deterministic by printing the seed in the report.

## Phase 3 — Browser coverage

### 6) Multi-engine runs (if available)
**Why:** focus + pointer event semantics differ across engines.

**Deliverables**
- Add `--browser chromium|firefox|webkit` to `scripts/debug-ui.mjs`.
- Run at least:
  - `chromium` (baseline)
  - `firefox` (focus quirks)
  - `webkit` (pointer/focus edge cases)

## Phase 4 — Make failures debuggable

### 7) Always-on debug state (in demos)
**Why:** when a scenario fails, we want the UI to show internal state quickly.

**Deliverables**
- Small “Debug” panel per demo showing:
  - `open`, `focusedKey`, `selectedKeys`, `activeDescendant`, `lastEvent`
- Add stable `data-testid` hooks for scenario queries.

## Acceptance criteria
- New scenarios pass locally in a loop (`--repeat 50`) without flakes.
- No regression in existing scenarios:
  - `npm run debug:solid-select`
  - `npm run debug:solid-combobox`
  - `npm run debug:solid-listbox`
  - `npm run debug:solid-dropdownmenu`
  - `npm run debug:solid-dialog`
  - `npm run debug:solid-toast`
  - `npm run debug:solid-overlay`

## Suggested execution order
1. OptionBuilder reactivity demo + test (highest product risk).
2. Modal pointer-blocking + toast clickability test.
3. Nested layer stacking demo + test.
4. Repeat + jitter harness enhancements.
5. Multi-browser support (if CI/runtime supports it).

# Kobalte Parity Audit (Solid DOM in Dart)

Goal: systematically compare our Solid DOM primitives/components to Kobalte’s “core” behavior and close gaps without chasing regressions.

This is intentionally **test-driven**: every parity claim should map to a Playwright scenario in `scripts/debug-ui.mjs`.

## Local reference repos

These are cloned into `.cache/refs/` (ignored by git) to make source comparison easy:

- Kobalte: `.cache/refs/kobalte`
- Corvu (inspiration): `.cache/refs/corvu`
- solid-primitives (inspiration): `.cache/refs/solid-primitives`

If you need to re-clone:

- `git clone --depth 1 https://github.com/kobaltedev/kobalte .cache/refs/kobalte`
- `git clone --depth 1 https://github.com/corvudev/corvu .cache/refs/corvu`
- `git clone --depth 1 https://github.com/solidjs-community/solid-primitives .cache/refs/solid-primitives`

## Strategy (module order)

Audit in dependency order: **foundations → selection core → composed components**.

1) Foundations (fix once, benefits everything)
   - Event/listener lifecycle glue: `lib/solid_dom/solid_dom.dart`
   - Focus management (stack + sentinels + trap/loop + restore): `lib/solid_dom/focus_scope.dart`
   - Outside interaction + stacking + pointer-blocking: `lib/solid_dom/overlay.dart`
   - Positioning: `lib/solid_dom/floating.dart` + `vendor/floating_ui_bridge.js`

2) Selection/navigation core (shared by menu/listbox/select/combobox)
   - `lib/solid_dom/selection/selection_manager.dart`
   - `lib/solid_dom/selection/create_selectable_collection.dart`
   - `lib/solid_dom/selection/create_selectable_item.dart`
   - Typeahead: `lib/solid_dom/selection/create_type_select.dart`

3) Reference components (compose the above)
   - Listbox: `lib/solid_dom/listbox.dart`
   - Select: `lib/solid_dom/select.dart`
   - Combobox: `lib/solid_dom/combobox.dart`
   - Menu core: `lib/solid_dom/menu.dart`
   - DropdownMenu wrapper: `lib/solid_dom/dropdown_menu.dart`
   - Popover/Tooltip: `lib/solid_dom/popover.dart`, `lib/solid_dom/tooltip.dart`
   - Dialog: `lib/solid_dom/dialog.dart`
   - Toast: `lib/solid_dom/toast.dart`

## Kobalte → Dart mapping (starting point)

Use this as the “what file should I read?” index during the audit.

### Foundations

- Focus scope
  - Kobalte: `.cache/refs/kobalte/packages/core/src/primitives/create-focus-scope/create-focus-scope.tsx`
  - Dart: `lib/solid_dom/focus_scope.dart`
  - Tests: `npm run debug:solid-dialog`, `npm run debug:solid-overlay`

- Interact-outside
  - Kobalte: `.cache/refs/kobalte/packages/core/src/primitives/create-interact-outside/create-interact-outside.ts`
  - Dart: `lib/solid_dom/overlay.dart` (`dismissableLayer`)
  - Tests: `npm run debug:solid-dialog`, `npm run debug:solid-popover`, `npm run debug:solid-tooltip`, `npm run debug:solid-dropdownmenu`, `npm run debug:solid-select`

- Dismissable layer stacking / pointer blocking
  - Kobalte: `.cache/refs/kobalte/packages/core/src/dismissable-layer/*`
  - Dart: `lib/solid_dom/overlay.dart` (`dismissableLayer`, `data-solid-top-layer` rules)
  - Tests: `npm run debug:solid-dialog`, `npm run debug:solid-overlay`, `npm run debug:solid-toast`

- Hide outside (aria-hidden / inert)
  - Kobalte: `.cache/refs/kobalte/packages/core/src/primitives/create-hide-outside/*`
  - Dart: `lib/solid_dom/overlay.dart` (`ariaHideOthers`)
  - Tests: `npm run debug:solid-overlay`, `npm run debug:solid-dialog`

- Positioning (Popper)
  - Kobalte: `.cache/refs/kobalte/packages/core/src/popper/*`
  - Dart: `lib/solid_dom/floating.dart` (Floating UI bridge preferred, fallback algo)
  - Tests: `npm run debug:solid-popover-position`, `npm run debug:solid-popover-flip`

### Selection core

- Selection manager + selectable collection/item + typeahead
  - Kobalte: `.cache/refs/kobalte/packages/core/src/selection/*`
  - Dart: `lib/solid_dom/selection/*`
  - Tests: `npm run debug:solid-selection`, `npm run debug:solid-listbox`, `npm run debug:solid-select`, `npm run debug:solid-combobox`, `npm run debug:solid-dropdownmenu`

### Components

- Dialog
  - Kobalte: `.cache/refs/kobalte/packages/core/src/dialog/*`
  - Dart: `lib/solid_dom/dialog.dart` (+ `overlay.dart`, `focus_scope.dart`)
  - Tests: `npm run debug:solid-dialog`, `npm run debug:solid-overlay`

- Popover
  - Kobalte: `.cache/refs/kobalte/packages/core/src/popover/*`
  - Dart: `lib/solid_dom/popover.dart` (+ `overlay.dart`, `floating.dart`, `focus_scope.dart`)
  - Tests: `npm run debug:solid-popover`, `npm run debug:solid-popover-position`, `npm run debug:solid-popover-flip`

- Tooltip
  - Kobalte: `.cache/refs/kobalte/packages/core/src/tooltip/*`
  - Dart: `lib/solid_dom/tooltip.dart` (+ `overlay.dart`, `floating.dart`)
  - Tests: `npm run debug:solid-tooltip`

- Menu / DropdownMenu
  - Kobalte: `.cache/refs/kobalte/packages/core/src/menu/*` and `.cache/refs/kobalte/packages/core/src/dropdown-menu/*`
  - Dart: `lib/solid_dom/menu.dart` + `lib/solid_dom/dropdown_menu.dart`
  - Tests: `npm run debug:solid-dropdownmenu`

- Listbox
  - Kobalte: `.cache/refs/kobalte/packages/core/src/listbox/*`
  - Dart: `lib/solid_dom/listbox.dart`
  - Tests: `npm run debug:solid-listbox`

- Select
  - Kobalte: `.cache/refs/kobalte/packages/core/src/select/*`
  - Dart: `lib/solid_dom/select.dart` (+ `listbox.dart`)
  - Tests: `npm run debug:solid-select`

- Combobox
  - Kobalte: `.cache/refs/kobalte/packages/core/src/combobox/*`
  - Dart: `lib/solid_dom/combobox.dart` (+ `listbox.dart`)
  - Tests: `npm run debug:solid-combobox`

- Toast
  - Kobalte: `.cache/refs/kobalte/packages/core/src/toast/*`
  - Dart: `lib/solid_dom/toast.dart` (+ `overlay.dart` top-layer rules)
  - Tests: `npm run debug:solid-toast`

## Audit workflow (how we’ll run it)

For each module in order:

1) Read the Kobalte reference file(s) (paths above) and write down:
   - keyboard map
   - pointer/touch timing rules
   - focus rules (mount/unmount, trap/loop, restore)
   - nesting/stacking rules
   - role/aria expectations
2) Ensure there is a Playwright scenario that proves each behavior:
   - add scenarios to `scripts/debug-ui.mjs` (preferred)
   - add demo hooks if needed (stable `id`/`data-testid`)
3) Only then change implementation to match, and keep the scenario as regression coverage.

## What “done” looks like

- Every foundation has at least one “nasty” scenario (nesting, mixed input types, timing variance) that passes reliably.
- Selection components (Listbox/Select/Combobox/Menu) share one core behavior model (no bespoke re-implementations).
- Positioning uses Floating UI by default (fallback only for debugging/offline), and positioning scenarios cover flip/scroll/resize.

# Kobalte Parity Audit (Solidus DOM in Dart)

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
   - Event/listener lifecycle glue: `lib/solidus_dom/solid_dom.dart`
   - Focus management (stack + sentinels + trap/loop + restore): `lib/solidus_dom/focus_scope.dart`
   - Outside interaction + stacking + pointer-blocking: `lib/solidus_dom/overlay.dart`
   - Positioning: `lib/solidus_dom/floating.dart` + `vendor/floating_ui_bridge.js`

2) Selection/navigation core (shared by menu/listbox/select/combobox)
   - `lib/solidus_dom/selection/selection_manager.dart`
   - `lib/solidus_dom/selection/create_selectable_collection.dart`
   - `lib/solidus_dom/selection/create_selectable_item.dart`
   - Typeahead: `lib/solidus_dom/selection/create_type_select.dart`

3) Reference components (compose the above)
   - Listbox (core): `lib/solidus_dom/core/listbox.dart`
   - Select (core): `lib/solidus_dom/core/select.dart`
   - Combobox (core): `lib/solidus_dom/core/combobox.dart`
   - UI wrappers: `lib/solidus_ui/listbox.dart`, `lib/solidus_ui/select.dart`, `lib/solidus_ui/combobox.dart`
   - Menu core: `lib/solidus_dom/core/menu.dart`
   - DropdownMenu core: `lib/solidus_dom/core/dropdown_menu.dart`
   - UI wrappers: `lib/solidus_ui/dropdown_menu.dart`, `lib/solidus_ui/menubar.dart`, `lib/solidus_ui/context_menu.dart`
   - Popover/Tooltip (core): `lib/solidus_dom/core/popover.dart`, `lib/solidus_dom/core/tooltip.dart`
   - Dialog (core): `lib/solidus_dom/core/dialog.dart`
   - Toast (core): `lib/solidus_dom/core/toast.dart`
   - UI wrappers: `lib/solidus_ui/popover.dart`, `lib/solidus_ui/tooltip.dart`, `lib/solidus_ui/dialog.dart`, `lib/solidus_ui/toast.dart`

## Kobalte → Dart mapping (starting point)

Use this as the “what file should I read?” index during the audit.

### Foundations

- Focus scope
  - Kobalte: `.cache/refs/kobalte/packages/core/src/primitives/create-focus-scope/create-focus-scope.tsx`
  - Dart: `lib/solidus_dom/focus_scope.dart`
  - Tests: `npm run debug:labs-dialog`, `npm run debug:labs-overlay`

- Interact-outside
  - Kobalte: `.cache/refs/kobalte/packages/core/src/primitives/create-interact-outside/create-interact-outside.ts`
  - Dart: `lib/solidus_dom/overlay.dart` (`dismissableLayer`)
  - Tests: `npm run debug:labs-dialog`, `npm run debug:labs-popover`, `npm run debug:labs-tooltip`, `npm run debug:labs-dropdownmenu`, `npm run debug:labs-select`

- Dismissable layer stacking / pointer blocking
  - Kobalte: `.cache/refs/kobalte/packages/core/src/dismissable-layer/*`
  - Dart: `lib/solidus_dom/overlay.dart` (`dismissableLayer`, top-layer rules)
  - Tests: `npm run debug:labs-dialog`, `npm run debug:labs-overlay`, `npm run debug:labs-toast`

- Hide outside (aria-hidden / inert)
  - Kobalte: `.cache/refs/kobalte/packages/core/src/primitives/create-hide-outside/*`
  - Dart: `lib/solidus_dom/overlay.dart` (`ariaHideOthers`)
  - Tests: `npm run debug:labs-overlay`, `npm run debug:labs-dialog`

- Positioning (Popper)
  - Kobalte: `.cache/refs/kobalte/packages/core/src/popper/*`
  - Dart: `lib/solidus_dom/floating.dart` (Floating UI bridge preferred, fallback algo)
  - Tests: `npm run debug:labs-popover-position`, `npm run debug:labs-popover-flip`

### Selection core

- Selection manager + selectable collection/item + typeahead
  - Kobalte: `.cache/refs/kobalte/packages/core/src/selection/*`
  - Dart: `lib/solidus_dom/selection/*`
  - Tests: `npm run debug:labs-selection`, `npm run debug:labs-listbox`, `npm run debug:labs-select`, `npm run debug:labs-combobox`, `npm run debug:labs-dropdownmenu`

### Components

- Dialog
  - Kobalte: `.cache/refs/kobalte/packages/core/src/dialog/*`
  - Dart: `lib/solidus_dom/core/dialog.dart` (+ `overlay.dart`, `focus_scope.dart`)
  - Tests: `npm run debug:labs-dialog`, `npm run debug:labs-overlay`

- Popover
  - Kobalte: `.cache/refs/kobalte/packages/core/src/popover/*`
  - Dart: `lib/solidus_dom/core/popover.dart` (+ `overlay.dart`, `floating.dart`, `focus_scope.dart`)
  - Tests: `npm run debug:labs-popover`, `npm run debug:labs-popover-position`, `npm run debug:labs-popover-flip`

- Tooltip
  - Kobalte: `.cache/refs/kobalte/packages/core/src/tooltip/*`
  - Dart: `lib/solidus_dom/core/tooltip.dart` (+ `overlay.dart`, `floating.dart`)
  - Tests: `npm run debug:labs-tooltip`

- Menu / DropdownMenu
  - Kobalte: `.cache/refs/kobalte/packages/core/src/menu/*` and `.cache/refs/kobalte/packages/core/src/dropdown-menu/*`
  - Dart: `lib/solidus_dom/core/menu.dart` + `lib/solidus_dom/core/dropdown_menu.dart`
  - Tests: `npm run debug:labs-dropdownmenu`

- Listbox
  - Kobalte: `.cache/refs/kobalte/packages/core/src/listbox/*`
  - Dart: `lib/solidus_dom/core/listbox.dart`
  - Tests: `npm run debug:labs-listbox`

- Select
  - Kobalte: `.cache/refs/kobalte/packages/core/src/select/*`
  - Dart: `lib/solidus_dom/core/select.dart` (+ `lib/solidus_dom/core/listbox.dart`)
  - Tests: `npm run debug:labs-select`

- Combobox
  - Kobalte: `.cache/refs/kobalte/packages/core/src/combobox/*`
  - Dart: `lib/solidus_dom/core/combobox.dart` (+ `lib/solidus_dom/core/listbox.dart`)
  - Tests: `npm run debug:labs-combobox`

- Toast
  - Kobalte: `.cache/refs/kobalte/packages/core/src/toast/*`
  - Dart: `lib/solidus_dom/core/toast.dart` (+ `overlay.dart` top-layer rules)
  - Tests: `npm run debug:labs-toast`

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

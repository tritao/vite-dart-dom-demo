# Architecture

## Overview

This repo is a Vite app that imports Dart entrypoints via `vite-plugin-dart`.

- Reusable runtime lives in `lib/vite_ui/` (components, hooks, DOM DSL, routing helpers).
- App-specific code lives in `src/app/` (components + reducers + models).
- Vite JS entry lives in `src/main.js` and imports Dart (`src/main.dart`).
- The morphdom JS bridge lives in `vendor/morph_patch.js` and is exposed as `globalThis.morphPatch`.

## Key pieces

- `lib/vite_ui/component.dart`: `Component` base class, scheduler, hooks (`useEffect`, `useRef`, `useMemo`, `useReducer`), context (`provide`/`useContext`)
- `lib/vite_ui/dom.dart`: small DOM builder DSL
- `src/app/app_component.dart`: app shell + routing-driven mount/unmount
- `src/app/*_state.dart`: reducer state/action definitions


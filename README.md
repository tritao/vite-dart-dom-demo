# Dart + Vite (vite-plugin-dart) Hello World

## Prerequisites

- Node.js `^20.19.0 || >=22.12.0` (required by the latest Vite)
- Dart SDK (`dart` on your PATH)

## Provision Dart (Linux x64)

If you don't have `dart` installed, you can provision Dart SDK 3.10.7 locally:

```bash
npm run provision:dart
```

## Install

```bash
npm install
```

## Run

First time (or after changing `pubspec.yaml`):

```bash
dart pub get
```

```bash
npm run dev
```

Open the URL Vite prints and you should see: **Hello from Dart (compiled by Vite)!**

## Troubleshooting

- If you have Flutter but not standalone Dart, set `DART` to Flutter's Dart binary, e.g. `DART="$(flutter sdk-path)/bin/dart" npm run dev`.

## Demo UI

The demo app is plain `dart:html` (no framework) and includes:

- Counter tab (state + re-render)
- Todos tab (CRUD + `localStorage`)
- Fetch tab (async network call + loading/error states)

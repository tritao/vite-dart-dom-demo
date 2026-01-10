#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

log() {
  printf "\n==> %s\n" "$1"
}

usage() {
  cat <<'EOF'
Usage: bash scripts/ci.sh [options]

Options:
  --no-playwright   Skip Playwright suites (still builds and runs Dart tests)
  --help            Show this help
EOF
}

RUN_PLAYWRIGHT=1
for arg in "$@"; do
  case "$arg" in
    --no-playwright) RUN_PLAYWRIGHT=0 ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

OS_RAW="$(uname -s | tr '[:upper:]' '[:lower:]')"
IS_LINUX=0
if [[ "$OS_RAW" == linux* ]]; then
  IS_LINUX=1
fi

log "env"
node -v
npm -v

log "install dependencies"
if [[ "${CI:-}" == "true" || "${CI:-}" == "1" ]]; then
  npm ci
else
  npm install
fi

log "provision Dart SDK"
npm run provision:dart

export DART="$ROOT_DIR/.dart-sdk/dart-sdk/bin/dart"
if [[ ! -x "$DART" ]]; then
  echo "Error: expected Dart at $DART" >&2
  exit 1
fi
"$DART" --version || true

log "dart pub get"
npm run dart:get

log "dart tests"
node scripts/dart-run.mjs test

log "docs build"
npm run docs:build

log "vite build"
npm run build

if [[ "$IS_LINUX" -eq 1 && "$RUN_PLAYWRIGHT" -eq 1 ]]; then
  log "install Playwright browsers"
  if [[ "${CI:-}" == "true" || "${CI:-}" == "1" ]]; then
    npx playwright install --with-deps chromium
  else
    npx playwright install chromium
  fi

  log "playwright: app smoke (preview)"
  npm run debug:ui:ci

  log "playwright: solid demos"
  npm run debug:solid-dom:ci
  npm run debug:solid-for:ci
  npm run debug:solid-overlay:ci
  npm run debug:solid-dialog:ci
  npm run debug:solid-roving:ci
  npm run debug:solid-popover:ci
  npm run debug:solid-popover-position:ci
  npm run debug:solid-popover-flip:ci
  npm run debug:solid-toast:ci

  log "playwright: docs suites"
  npm run docs:ci
else
  log "skipping Playwright"
fi

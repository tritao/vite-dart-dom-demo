#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DART="${DART:-$ROOT/../../.dart-sdk/dart-sdk/bin/dart}"
if [[ ! -x "$DART" ]]; then
  echo "dart not found; set DART=... (tried: $DART)" >&2
  exit 1
fi

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 1; }
}

require curl
require openssl
require python3

export SOLIDUS_AUTH_MASTER_KEY="${SOLIDUS_AUTH_MASTER_KEY:-$(openssl rand -base64 32)}"
export SOLIDUS_BACKEND_HOST="${SOLIDUS_BACKEND_HOST:-127.0.0.1}"
if [[ -z "${SOLIDUS_BACKEND_PORT:-}" ]]; then
  SOLIDUS_BACKEND_PORT="$(python3 -c '
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
')"
fi
export SOLIDUS_BACKEND_PORT
export SOLIDUS_BACKEND_DB="${SOLIDUS_BACKEND_DB:-$ROOT/.cache/smoke/solidus.sqlite}"
export SOLIDUS_AUTO_CREATE_DEFAULT_TENANT="${SOLIDUS_AUTO_CREATE_DEFAULT_TENANT:-1}"
export SOLIDUS_DEFAULT_TENANT_SLUG="${SOLIDUS_DEFAULT_TENANT_SLUG:-default}"
export SOLIDUS_DEFAULT_TENANT_NAME="${SOLIDUS_DEFAULT_TENANT_NAME:-Default}"
export SOLIDUS_DEFAULT_SIGNUP_MODE="${SOLIDUS_DEFAULT_SIGNUP_MODE:-invite_only}"
export SOLIDUS_EXPOSE_INVITE_TOKENS="${SOLIDUS_EXPOSE_INVITE_TOKENS:-1}"
export SOLIDUS_EXPOSE_DEV_TOKENS="${SOLIDUS_EXPOSE_DEV_TOKENS:-1}"

mkdir -p "$(dirname "$SOLIDUS_BACKEND_DB")"
rm -f "$SOLIDUS_BACKEND_DB" "$SOLIDUS_BACKEND_DB-wal" "$SOLIDUS_BACKEND_DB-shm"

echo "[smoke] pub get"
(cd "$ROOT" && "$DART" pub get >/dev/null)

echo "[smoke] build_runner"
(cd "$ROOT" && "$DART" run build_runner build -d >/dev/null)

echo "[smoke] start server"
LOG="$ROOT/.cache/smoke/server.log"
mkdir -p "$(dirname "$LOG")"
rm -f "$LOG"
(cd "$ROOT" && "$DART" run bin/server.dart >"$LOG" 2>&1) &
PID=$!
cleanup() { kill "$PID" >/dev/null 2>&1 || true; }
trap cleanup EXIT

BASE="http://$SOLIDUS_BACKEND_HOST:$SOLIDUS_BACKEND_PORT"
for _ in $(seq 1 60); do
  if ! kill -0 "$PID" >/dev/null 2>&1; then
    echo "[smoke] server exited early" >&2
    cat "$LOG" >&2 || true
    exit 1
  fi
  if curl -fsS "$BASE/healthz" >/dev/null 2>&1; then break; fi
  sleep 0.25
done
curl -fsS "$BASE/healthz" >/dev/null

JAR1="$ROOT/.cache/smoke/cookies-1.txt"
JAR2="$ROOT/.cache/smoke/cookies-2.txt"
rm -f "$JAR1" "$JAR2"

json_get() {
  local key="$1"
  python3 -c '
import json,sys
key = sys.argv[1]
data = json.load(sys.stdin)
cur = data
for part in key.split("."):
  cur = cur[part]
print(cur)
' "$key"
}

echo "[smoke] bootstrap first user"
curl -fsS -X POST "$BASE/bootstrap" \
  -H 'content-type: application/json' \
  -d '{"email":"owner@example.com","password":"passw0rd!"}' >/dev/null

echo "[smoke] login (expect mfaRequired=false)"
LOGIN_JSON="$(curl -fsS -c "$JAR1" -X POST "$BASE/login" \
  -H 'content-type: application/json' \
  -d '{"email":"owner@example.com","password":"passw0rd!"}')"
CSRF1="$(printf '%s' "$LOGIN_JSON" | json_get csrfToken)"

curl -fsS -b "$JAR1" "$BASE/me" >/dev/null

TENANTS_JSON="$(curl -fsS -b "$JAR1" "$BASE/tenants")"
DEFAULT_SLUG="$(printf '%s' "$TENANTS_JSON" | python3 -c '
import json,sys
data = json.load(sys.stdin)
print(data["tenants"][0]["slug"])
')"
[[ "$DEFAULT_SLUG" == "$SOLIDUS_DEFAULT_TENANT_SLUG" ]]

echo "[smoke] select default tenant"
curl -fsS -b "$JAR1" -X POST "$BASE/tenants/select" \
  -H 'content-type: application/json' \
  -H "x-csrf-token: $CSRF1" \
  -d "{\"slug\":\"$SOLIDUS_DEFAULT_TENANT_SLUG\"}" >/dev/null

curl -fsS -b "$JAR1" "$BASE/t/$SOLIDUS_DEFAULT_TENANT_SLUG/me" >/dev/null

echo "[smoke] create tenant acme"
curl -fsS -b "$JAR1" -X POST "$BASE/tenants" \
  -H 'content-type: application/json' \
  -H "x-csrf-token: $CSRF1" \
  -d '{"slug":"acme","name":"Acme Inc","signupMode":"invite_only"}' >/dev/null

echo "[smoke] invite new user to acme"
INVITE_JSON="$(curl -fsS -b "$JAR1" -X POST "$BASE/t/acme/admin/invites" \
  -H 'content-type: application/json' \
  -H "x-csrf-token: $CSRF1" \
  -d '{"email":"newuser@example.com","role":"member"}')"
INVITE_TOKEN="$(printf '%s' "$INVITE_JSON" | json_get token)"

echo "[smoke] accept invite"
ACCEPT_JSON="$(curl -fsS -c "$JAR2" -X POST "$BASE/t/acme/invites/accept" \
  -H 'content-type: application/json' \
  -d "{\"token\":\"$INVITE_TOKEN\",\"password\":\"passw0rd!\"}")"
CSRF2="$(printf '%s' "$ACCEPT_JSON" | json_get csrfToken)"

curl -fsS -b "$JAR2" "$BASE/t/acme/me" >/dev/null

echo "[smoke] start 2FA enrollment (owner)"
ENROLL_JSON="$(curl -fsS -b "$JAR1" -X POST "$BASE/mfa/enroll/start" \
  -H 'content-type: application/json' \
  -H "x-csrf-token: $CSRF1" \
  -d '{}')"
SECRET_B32="$(printf '%s' "$ENROLL_JSON" | json_get secret)"
CODE="$("$DART" run "$ROOT/tool/gen_totp.dart" "$SECRET_B32")"

echo "[smoke] confirm 2FA enrollment"
CONFIRM_JSON="$(curl -fsS -b "$JAR1" -X POST "$BASE/mfa/enroll/confirm" \
  -H 'content-type: application/json' \
  -H "x-csrf-token: $CSRF1" \
  -d "{\"code\":\"$CODE\"}")"
printf '%s' "$CONFIRM_JSON" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d["ok"] is True
assert len(d["recoveryCodes"]) == 10
'

echo "[smoke] request email verification token"
EV_REQ="$(curl -fsS -b "$JAR1" -X POST "$BASE/email/verify/request" \
  -H 'content-type: application/json' \
  -H "x-csrf-token: $CSRF1" \
  -d '{}')"
EV_TOKEN="$(printf '%s' "$EV_REQ" | json_get token)"
curl -fsS -X POST "$BASE/email/verify" -H 'content-type: application/json' -d "{\"token\":\"$EV_TOKEN\"}" >/dev/null

echo "[smoke] logout + login (expect mfaRequired=true)"
curl -fsS -b "$JAR1" -X POST "$BASE/logout" -H "x-csrf-token: $CSRF1" >/dev/null || true
LOGIN2_JSON="$(curl -fsS -c "$JAR1" -X POST "$BASE/login" \
  -H 'content-type: application/json' \
  -d '{"email":"owner@example.com","password":"passw0rd!"}')"
CSRF1="$(printf '%s' "$LOGIN2_JSON" | json_get csrfToken)"
CODE2="$("$DART" run "$ROOT/tool/gen_totp.dart" "$SECRET_B32")"
VERIFY_JSON="$(curl -fsS -b "$JAR1" -c "$JAR1" -X POST "$BASE/mfa/verify" \
  -H 'content-type: application/json' \
  -H "x-csrf-token: $CSRF1" \
  -d "{\"code\":\"$CODE2\"}")"
printf '%s' "$VERIFY_JSON" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d["ok"] is True
assert d["session"]["mfaVerified"] is True
'

echo "[smoke] password reset flow"
FORGOT_JSON="$(curl -fsS -X POST "$BASE/password/forgot" \
  -H 'content-type: application/json' \
  -d '{"email":"owner@example.com"}')"
RESET_TOKEN="$(printf '%s' "$FORGOT_JSON" | json_get token)"
curl -fsS -X POST "$BASE/password/reset" \
  -H 'content-type: application/json' \
  -d "{\"token\":\"$RESET_TOKEN\",\"password\":\"newpassw0rd!\"}" >/dev/null

echo "[smoke] OK"

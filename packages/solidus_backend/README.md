# solidus_backend

Minimal `shelf` + `drift` backend package with:

- Cookie sessions (server-side session storage)
- Multi-tenancy (select tenant, `/t/:slug/...` routes)
- Per-tenant roles (`owner`, `admin`, `member`)
- TOTP 2FA + recovery codes

This is an initial scaffold intended to be adapted to your app needs.

## Run

From `packages/solidus_backend`:

```bash
dart pub get
dart run build_runner build -d
dart run bin/server.dart
```

If `dart` isn't on your PATH, this repo usually has a provisioned SDK at `../../.dart-sdk/dart-sdk/bin/dart`.

## Test

- `../../.dart-sdk/dart-sdk/bin/dart test`
- End-to-end flow test: `packages/solidus_backend/test/flow_test.dart`
- Shell smoke script (optional): `bash packages/solidus_backend/scripts/smoke.sh`
- Example client: `../../.dart-sdk/dart-sdk/bin/dart run packages/solidus_backend/example/client.dart --base http://127.0.0.1:8080 --email owner@example.com --password 'passw0rd!pass'`

## Minimal API surface

- Auth: `POST /bootstrap`, `POST /login`, `POST /logout`, `GET /me`
- Email/password: `POST /password/forgot`, `POST /password/reset`
- Email verification: `POST /email/verify/request`, `POST /email/verify`
- Tenants: `GET /tenants`, `POST /tenants`, `POST /tenants/select`
- Sessions: `GET /sessions`, `POST /sessions/<id>/revoke`, `POST /sessions/revoke_others`
- 2FA: `POST /mfa/enroll/start`, `POST /mfa/enroll/confirm`, `POST /mfa/verify`, `POST /mfa/disable`, `POST /mfa/recovery/regenerate`
- Tenant admin: `POST /t/<slug>/admin/invites`, `GET /t/<slug>/admin/members`, `POST /t/<slug>/admin/members/<userId>/role`, `POST /t/<slug>/admin/settings/mfa`

## Config

Env vars (most useful):

- `SOLIDUS_AUTH_MASTER_KEY` (required): base64-encoded 32 bytes (used for token hashing + encrypting TOTP secrets)
- `SOLIDUS_BACKEND_HOST` (default `127.0.0.1`)
- `SOLIDUS_BACKEND_PORT` (default `8080`)
- `SOLIDUS_BACKEND_DB` (default `.cache/solidus_backend/solidus.sqlite`)
- `SOLIDUS_BACKEND_ALLOWED_ORIGINS` (comma-separated exact origins, enables CORS)
- `SOLIDUS_EXPOSE_DEV_TOKENS=1` (dev/test only): include password reset + email verify tokens in JSON responses

Email delivery:

- `SOLIDUS_EMAIL_TRANSPORT=disabled|log|smtp|resend` (default `disabled`)
- `SOLIDUS_EMAIL_DELIVERY_MODE=async|sync` (default `async`): `async` writes to `email_outbox` (SQLite) and retries delivery in the background
- `SOLIDUS_EMAIL_FROM` (required for `smtp`, recommended for `log`)
- `SOLIDUS_PUBLIC_BASE_URL` (recommended): used to build links, e.g. `https://app.example.com`
- `SOLIDUS_FRONTEND_RESET_PATH` (default `/reset-password`)
- `SOLIDUS_FRONTEND_VERIFY_EMAIL_PATH` (default `/verify-email`)
- `SOLIDUS_FRONTEND_INVITE_PATH` (default `/accept-invite`)
- `SOLIDUS_URL_TOKEN_PLACEMENT=query|fragment` (default `query`)
- Outbox: `SOLIDUS_EMAIL_OUTBOX_POLL_MS` (default `500`), `SOLIDUS_EMAIL_MAX_ATTEMPTS` (default `5`), status `pending|sent|failed`
- SMTP: `SOLIDUS_SMTP_HOST`, `SOLIDUS_SMTP_PORT`, `SOLIDUS_SMTP_USERNAME`, `SOLIDUS_SMTP_PASSWORD`, `SOLIDUS_SMTP_SSL=1`, `SOLIDUS_SMTP_ALLOW_INSECURE=0`
- Resend: `SOLIDUS_RESEND_API_KEY`, `SOLIDUS_RESEND_ENDPOINT` (default `https://api.resend.com/emails`)

Password + lockout:

- `SOLIDUS_PASSWORD_MIN_LENGTH` (default `12`)
- Backoff: `SOLIDUS_AUTH_BACKOFF_BASE_SECONDS` (default `2`), `SOLIDUS_AUTH_BACKOFF_MAX_SECONDS` (default `300`)

## Production notes

- Prefer `SOLIDUS_URL_TOKEN_PLACEMENT=fragment` to reduce token leakage via `Referer` headers.
- Set `SOLIDUS_PUBLIC_BASE_URL` so reset/verify/invite links point to the frontend (not the backend host/port).
- `SOLIDUS_EMAIL_DELIVERY_MODE=async` is durable (DB-backed), but still runs in-process; if the process is down, delivery pauses until it restarts.

Bootstrap the first user (only works when there are no users yet):

- `POST /bootstrap { "email": "...", "password": "..." }`

Config is loaded in `lib/src/config.dart`.

---
title: Backend
slug: backend
group: Backend
order: 0
description: "Solidus backend package (shelf + drift): sessions, tenants, roles, 2FA, email + password reset."
status: beta
tags: [backend, auth, tenancy]
---

`packages/solidus_backend` is a minimal Dart backend built on:

- `shelf` (HTTP server + middleware)
- `drift` + SQLite (schema, queries, migrations)

It provides:

- Cookie sessions + CSRF
- Global login + tenant selection (`/tenants/select`) and tenant routes (`/t/:slug/...`)
- Per-tenant roles (`owner`, `admin`, `member`)
- TOTP 2FA + recovery codes
- Email verification + password reset
- Durable email outbox + retry (DB-backed)
- Rate limiting + durable auth backoff (DB-backed)

## Quick start (dev)

From `packages/solidus_backend`:

```bash
../../.dart-sdk/dart-sdk/bin/dart pub get
../../.dart-sdk/dart-sdk/bin/dart run build_runner build -d

export SOLIDUS_AUTH_MASTER_KEY=$(openssl rand -base64 32)
export SOLIDUS_EXPOSE_DEV_TOKENS=1
export SOLIDUS_EMAIL_TRANSPORT=log
export SOLIDUS_EMAIL_FROM='Solidus <no-reply@example.com>'

../../.dart-sdk/dart-sdk/bin/dart run bin/server.dart
```

Bootstrap the first user:

```bash
curl -X POST http://127.0.0.1:8080/bootstrap \
  -H 'content-type: application/json' \
  -d '{"email":"owner@example.com","password":"passw0rd!pass"}'
```

## Backend playground (Solidus web app)

This repo includes a small Solidus web page to exercise the backend:

- Open `http://localhost:5173/?backend=1`

It defaults to `Base URL = /api` and uses the Vite dev-server proxy:

- `vite.config.mjs` proxies `/api/*` → `http://127.0.0.1:8080/*` (override via `SOLIDUS_BACKEND_PROXY`)

## Email links and token leakage

By default, links are built with query params (e.g. `...?token=...`).

For safer browser flows, set:

- `SOLIDUS_URL_TOKEN_PLACEMENT=fragment`

This produces links like `/#token=...` where the token is not sent in HTTP referrers by default.

## Durable email outbox (retry / DLQ)

When `SOLIDUS_EMAIL_DELIVERY_MODE=async` (default), outgoing emails are written to `email_outbox` in SQLite and delivered by a background worker inside the server process:

- Poll interval: `SOLIDUS_EMAIL_OUTBOX_POLL_MS` (default `500`)
- Retry limit: `SOLIDUS_EMAIL_MAX_ATTEMPTS` (default `5`)
- Status: `pending | sent | failed` (failed is effectively a DLQ)

## Email providers

Choose one:

- `SOLIDUS_EMAIL_TRANSPORT=log` (dev: prints email content to logs)
- `SOLIDUS_EMAIL_TRANSPORT=smtp` (basic SMTP)
- `SOLIDUS_EMAIL_TRANSPORT=resend` (Resend HTTP API)

Resend env vars:

- `SOLIDUS_EMAIL_FROM='Solidus <no-reply@yourdomain>'`
- `SOLIDUS_RESEND_API_KEY=...`
- `SOLIDUS_PUBLIC_BASE_URL=https://app.yourdomain`

## Common endpoints

- Auth: `POST /bootstrap`, `POST /login`, `POST /logout`, `GET /me`
- Password reset: `POST /password/forgot`, `POST /password/reset`
- Email verify: `POST /email/verify/request`, `POST /email/verify`
- Tenants: `GET /tenants`, `POST /tenants`, `POST /tenants/select`
- Sessions: `GET /sessions`, `POST /sessions/<id>/revoke`, `POST /sessions/revoke_others`
- 2FA: `POST /mfa/enroll/start`, `POST /mfa/enroll/confirm`, `POST /mfa/verify`, `POST /mfa/disable`, `POST /mfa/recovery/regenerate`
- Tenant admin: `POST /t/<slug>/admin/invites`, `GET /t/<slug>/admin/members`, `POST /t/<slug>/admin/members/<userId>/role`, `POST /t/<slug>/admin/settings/mfa`

## Examples

### Dart client example

See `packages/solidus_backend/example/client.dart` for a small cookie + CSRF aware client.

### Login + CSRF (curl)

```bash
# login (stores cookies to cookiejar.txt)
curl -sS -c cookiejar.txt http://127.0.0.1:8080/login \
  -H 'content-type: application/json' \
  -d '{"email":"owner@example.com","password":"passw0rd!pass"}' \
  | tee /tmp/login.json

# extract csrfToken
CSRF=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["csrfToken"])' </tmp/login.json)

# select tenant (requires CSRF header)
curl -sS -b cookiejar.txt http://127.0.0.1:8080/tenants/select \
  -H 'content-type: application/json' \
  -H "x-csrf-token: $CSRF" \
  -d '{"slug":"default"}'
```

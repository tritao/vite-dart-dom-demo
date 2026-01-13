# Examples

## `client.dart`

A tiny Dart CLI that exercises:

- `POST /login` (cookie jar + CSRF token handling)
- `GET /tenants`
- `POST /tenants/select`
- `GET /t/<slug>/me`

Run from `packages/solidus_backend`:

```bash
../../.dart-sdk/dart-sdk/bin/dart pub get
../../.dart-sdk/dart-sdk/bin/dart run example/client.dart --base http://127.0.0.1:8080 --email owner@example.com --password 'passw0rd!pass'
```


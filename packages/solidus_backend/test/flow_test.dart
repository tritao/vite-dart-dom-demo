import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:solidus_backend/solidus_backend.dart';
import 'package:solidus_backend/src/auth/totp.dart';
import 'package:test/test.dart';

class _TestClient {
  _TestClient(this.baseUri);

  final Uri baseUri;
  final _cookies = <String, String>{};
  final _http = HttpClient();

  void close() => _http.close(force: true);

  Future<({int status, Map<String, String> headers, String body})> get(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    final req = await _http.getUrl(baseUri.resolve(path));
    _applyHeaders(req, headers);
    final resp = await req.close();
    return _read(resp);
  }

  Future<({int status, Map<String, String> headers, String body})> postJson(
    String path,
    Map<String, Object?> body, {
    Map<String, String> headers = const {},
  }) async {
    final req = await _http.postUrl(baseUri.resolve(path));
    _applyHeaders(req, {
      'content-type': 'application/json',
      ...headers,
    });
    req.write(jsonEncode(body));
    final resp = await req.close();
    return _read(resp);
  }

  void _applyHeaders(HttpClientRequest req, Map<String, String> headers) {
    if (_cookies.isNotEmpty) {
      req.headers.set('cookie', _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '));
    }
    headers.forEach(req.headers.set);
  }

  Future<({int status, Map<String, String> headers, String body})> _read(
    HttpClientResponse resp,
  ) async {
    final setCookies = resp.headers[HttpHeaders.setCookieHeader] ?? const <String>[];
    for (final raw in setCookies) {
      final cookie = Cookie.fromSetCookieValue(raw);
      if (cookie.value.isEmpty) {
        _cookies.remove(cookie.name);
      } else {
        _cookies[cookie.name] = cookie.value;
      }
    }
    final body = await resp.transform(utf8.decoder).join();
    final headers = <String, String>{};
    resp.headers.forEach((name, values) {
      headers[name.toLowerCase()] = values.join(', ');
    });
    return (status: resp.statusCode, headers: headers, body: body);
  }
}

void main() {
  test('end-to-end auth + tenants + invites + 2fa', () async {
    final tmp = await Directory.systemTemp.createTemp('solidus_backend_test_');
    addTearDown(() => tmp.delete(recursive: true));

    final masterKey = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final config = SolidusBackendConfig(
      host: '127.0.0.1',
      port: 0,
      sqliteFilePath: '${tmp.path}/db.sqlite',
      cookieName: 'sid',
      cookieSecure: false,
      cookieSameSite: 'Lax',
      allowedOrigins: const {},
      authMasterKey: masterKey,
      authKeyVersion: 1,
      sessionLifetime: const Duration(days: 30),
      recentAuthWindow: const Duration(minutes: 10),
      issuer: 'solidus-test',
      autoCreateDefaultTenant: true,
      defaultTenantSlug: 'default',
      defaultTenantName: 'Default',
      defaultSignupMode: 'invite_only',
      exposeInviteTokens: true,
      exposeDevTokens: true,
      publicBaseUrl: null,
      frontendResetPath: '/reset-password',
      frontendVerifyEmailPath: '/verify-email',
      emailTransport: 'disabled',
      emailFrom: null,
      smtpHost: null,
      smtpPort: null,
      smtpUsername: null,
      smtpPassword: null,
      smtpSsl: true,
      smtpAllowInsecure: false,
      emailDeliveryMode: 'async',
      resendApiKey: null,
      resendEndpoint: 'https://api.resend.com/emails',
    );

    final server = await SolidusBackendServer.start(config);
    addTearDown(server.stop);

    final client = _TestClient(Uri.parse('http://${server.host}:${server.port}'));
    addTearDown(client.close);

    // bootstrap
    final boot = await client.postJson('/bootstrap', {
      'email': 'owner@example.com',
      'password': 'passw0rd!',
    });
    expect(boot.status, 201);

    // login
    final login = await client.postJson('/login', {
      'email': 'owner@example.com',
      'password': 'passw0rd!',
    });
    expect(login.status, 200);
    final loginJson = jsonDecode(login.body) as Map<String, Object?>;
    final csrf = loginJson['csrfToken'] as String;
    expect((loginJson['session'] as Map<String, Object?>)['mfaRequired'], false);

    // list tenants
    final tenants = await client.get('/tenants');
    expect(tenants.status, 200);
    final tenantsJson = jsonDecode(tenants.body) as Map<String, Object?>;
    final firstSlug = ((tenantsJson['tenants'] as List).first as Map)['slug'];
    expect(firstSlug, 'default');

    // select default tenant
    final sel = await client.postJson(
      '/tenants/select',
      {'slug': 'default'},
      headers: {'x-csrf-token': csrf},
    );
    expect(sel.status, 200);

    // create tenant
    final createTenant = await client.postJson(
      '/tenants',
      {'slug': 'acme', 'name': 'Acme Inc', 'signupMode': 'invite_only'},
      headers: {'x-csrf-token': csrf},
    );
    expect(createTenant.status, 201);

    // invite
    final invite = await client.postJson(
      '/t/acme/admin/invites',
      {'email': 'newuser@example.com', 'role': 'member'},
      headers: {'x-csrf-token': csrf},
    );
    expect(invite.status, 201);
    final inviteJson = jsonDecode(invite.body) as Map<String, Object?>;
    final inviteToken = inviteJson['token'] as String;

    // accept invite as separate client
    final invited = _TestClient(Uri.parse('http://${server.host}:${server.port}'));
    addTearDown(invited.close);
    final accept = await invited.postJson('/t/acme/invites/accept', {
      'token': inviteToken,
      'password': 'passw0rd!',
    });
    expect(accept.status, 200);
    final acceptJson = jsonDecode(accept.body) as Map<String, Object?>;
    final invitedCsrf = acceptJson['csrfToken'] as String;

    // invited user can access tenant me
    final invitedMe = await invited.get('/t/acme/me');
    expect(invitedMe.status, 200);

    // accept_existing: invite existing user to default tenant and accept while logged in.
    final inviteDefault = await client.postJson(
      '/t/default/admin/invites',
      {'email': 'newuser@example.com', 'role': 'admin'},
      headers: {'x-csrf-token': csrf},
    );
    expect(inviteDefault.status, 201);
    final inviteDefaultJson = jsonDecode(inviteDefault.body) as Map<String, Object?>;
    final inviteDefaultToken = inviteDefaultJson['token'] as String;

    final acceptExisting = await invited.postJson(
      '/t/default/invites/accept_existing',
      {'token': inviteDefaultToken},
      headers: {'x-csrf-token': invitedCsrf},
    );
    expect(acceptExisting.status, 200);

    final invitedTenants = await invited.get('/tenants');
    expect(invitedTenants.status, 200);

    // Email verification request + verify (dev token exposed).
    final verifyReq = await client.postJson(
      '/email/verify/request',
      {},
      headers: {'x-csrf-token': csrf},
    );
    expect(verifyReq.status, 200);
    final verifyReqJson = jsonDecode(verifyReq.body) as Map<String, Object?>;
    final verifyToken = verifyReqJson['token'] as String;

    final emailVerify = await client.postJson('/email/verify', {'token': verifyToken});
    expect(emailVerify.status, 200);

    // owner enroll 2FA
    final enrollStart = await client.postJson(
      '/mfa/enroll/start',
      {},
      headers: {'x-csrf-token': csrf},
    );
    expect(enrollStart.status, 200);
    final enrollJson = jsonDecode(enrollStart.body) as Map<String, Object?>;
    final secretB32 = enrollJson['secret'] as String;

    final secret = Base32.decode(secretB32);
    final totp = Totp();
    final now = DateTime.now().toUtc();
    final step = now.millisecondsSinceEpoch ~/ (totp.periodSeconds * 1000);
    final code = totp.generateCode(secret: secret, timeStep: step);

    final confirm = await client.postJson(
      '/mfa/enroll/confirm',
      {'code': code},
      headers: {'x-csrf-token': csrf},
    );
    expect(confirm.status, 200);

    // logout then login again should require mfa
    final logout = await client.postJson(
      '/logout',
      {},
      headers: {'x-csrf-token': csrf},
    );
    expect(logout.status, 200);

    final login2 = await client.postJson('/login', {
      'email': 'owner@example.com',
      'password': 'passw0rd!',
    });
    expect(login2.status, 200);
    final login2Json = jsonDecode(login2.body) as Map<String, Object?>;
    final csrf2 = login2Json['csrfToken'] as String;
    expect((login2Json['session'] as Map<String, Object?>)['mfaRequired'], true);
    expect((login2Json['session'] as Map<String, Object?>)['mfaVerified'], false);

    final now2 = DateTime.now().toUtc();
    final step2 = now2.millisecondsSinceEpoch ~/ (totp.periodSeconds * 1000);
    final code2 = totp.generateCode(secret: secret, timeStep: step2);
    final mfaVerify = await client.postJson(
      '/mfa/verify',
      {'code': code2},
      headers: {'x-csrf-token': csrf2},
    );
    expect(mfaVerify.status, 200);

    // Password reset: request + reset should revoke sessions.
    final forgot = await client.postJson('/password/forgot', {'email': 'owner@example.com'});
    expect(forgot.status, 200);
    final forgotJson = jsonDecode(forgot.body) as Map<String, Object?>;
    final resetToken = forgotJson['token'] as String;

    final reset = await client.postJson('/password/reset', {
      'token': resetToken,
      'password': 'newpassw0rd!',
    });
    expect(reset.status, 200);

    // Existing session should be revoked; /me now unauthorized.
    final meAfterReset = await client.get('/me');
    expect(meAfterReset.status, 401);

    // Login with new password works.
    final loginAfterReset = await client.postJson('/login', {
      'email': 'owner@example.com',
      'password': 'newpassw0rd!',
    });
    expect(loginAfterReset.status, 200);

    // invited user needs CSRF for state changes
    final selectAcme = await invited.postJson(
      '/tenants/select',
      {'slug': 'acme'},
      headers: {'x-csrf-token': invitedCsrf},
    );
    expect(selectAcme.status, 200);
  });
}

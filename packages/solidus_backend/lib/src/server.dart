import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'auth/crypto_primitives.dart';
import 'auth/password_hasher.dart';
import 'auth/totp.dart';
import 'config.dart';
import 'db/app_db.dart';
import 'email/email_dispatcher.dart';
import 'email/email_sender.dart';
import 'email/resend_email_sender.dart';
import 'email/templates.dart';
import 'http/cookies.dart';
import 'http/http_utils.dart';
import 'http/rate_limiter.dart';
import 'http/request_info.dart';

const _ctxAuth = 'solidus_backend.auth';
const _ctxClearCookie = 'solidus_backend.clear_cookie';

class SolidusBackendServer {
  SolidusBackendServer._({
    required this.config,
    required this.db,
    required HttpServer httpServer,
    required EmailDispatcher emailDispatcher,
  })  : _httpServer = httpServer,
        _emailDispatcher = emailDispatcher;

  final SolidusBackendConfig config;
  final AppDatabase db;
  final HttpServer _httpServer;
  final EmailDispatcher _emailDispatcher;

  String get host => _httpServer.address.host;
  int get port => _httpServer.port;

  Future<void> stop() async {
    await _httpServer.close(force: true);
    await _emailDispatcher.close();
    await db.close();
  }

  static Future<SolidusBackendServer> start(SolidusBackendConfig config) async {
    final db = AppDatabase(sqliteFilePath: config.sqliteFilePath);
    final logger = Logger('solidus_backend');

    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((r) {
      // ignore: avoid_print
      print('${r.level.name} ${r.time.toIso8601String()} ${r.loggerName}: ${r.message}');
    });

    if (config.autoCreateDefaultTenant) {
      await _ensureDefaultTenant(db, config);
    }

    final emailSender = _buildEmailSender(config: config, logger: logger);
    final dispatcher = EmailDispatcher(sender: emailSender, logger: logger);
    final handler = _buildHandler(
      db: db,
      config: config,
      logger: logger,
      emailDispatcher: dispatcher,
    );
    final server = await shelf_io.serve(
      handler,
      config.host,
      config.port,
    );

    return SolidusBackendServer._(
      config: config,
      db: db,
      httpServer: server,
      emailDispatcher: dispatcher,
    );
  }
}

class AuthContext {
  AuthContext({
    required this.session,
    required this.user,
  });

  final Session session;
  final User user;
}

extension _AuthRequestX on Request {
  AuthContext? get auth => context[_ctxAuth] as AuthContext?;
  bool get shouldClearCookie => context[_ctxClearCookie] == true;
}

Handler _buildHandler({
  required AppDatabase db,
  required SolidusBackendConfig config,
  required Logger logger,
  required EmailDispatcher emailDispatcher,
}) {
  final router = Router();

  final passwordHasher = PasswordHasher(iterations: 210000, bits: 256);
  final encryptor = AesGcmEncryptor(config.authMasterKey);
  final totp = Totp();
  final rateLimiter = InMemoryRateLimiter();

  router.get('/healthz', (Request request) {
    return Response.ok('ok');
  });

  router.post('/password/forgot', (Request request) async {
    final json = await readJsonObject(request);
    final email = (getString(json, 'email') ?? '').trim().toLowerCase();
    if (email.isEmpty) return jsonError(400, 'email required');

    final user = await db.getUserByEmail(email);
    final now = DateTime.now().toUtc();
    if (user == null || user.disabledAt != null) {
      await _audit(
        db,
        action: 'auth.password_reset_requested',
        metadata: {'email': email, 'created': false},
        ip: remoteIp(request),
        userAgent: request.headers['user-agent'],
      );
      // Avoid account enumeration.
      return jsonResponse({'ok': true});
    }

    final token = base64UrlNoPad(randomBytes(32));
    final tokenHash = _hashRecoveryOrInviteToken(config, token);
    final expiresAt = now.add(const Duration(minutes: 30));

    // Keep one active reset token per user.
    await (db.delete(db.passwordResetTokens)..where((t) => t.userId.equals(user.id) & t.usedAt.isNull())).go();
    await db.into(db.passwordResetTokens).insert(
          PasswordResetTokensCompanion.insert(
            id: const Uuid().v4(),
            userId: user.id,
            tokenHash: tokenHash,
            expiresAt: expiresAt,
            usedAt: const Value.absent(),
            createdAt: now,
          ),
        );

    await _audit(
      db,
        action: 'auth.password_reset_requested',
        actorUserId: user.id,
        metadata: {'created': true},
        ip: remoteIp(request),
        userAgent: request.headers['user-agent'],
      );

    final resetUrl = _buildFrontendUrl(
      config: config,
      request: request,
      path: config.frontendResetPath,
      query: {'token': token},
    );
    final tpl = EmailTemplates.passwordReset(
      appName: config.issuer,
      resetUrl: resetUrl.toString(),
      expiresIn: const Duration(minutes: 30),
    );
    final delivery = await _deliverEmail(
      emailDispatcher: emailDispatcher,
      config: config,
      to: user.email,
      subject: tpl.subject,
      text: tpl.text,
      html: tpl.html,
    );
    await _audit(
      db,
      action: 'auth.password_reset_email_delivery',
      actorUserId: user.id,
      metadata: {'delivery': delivery},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse({
      'ok': true,
      if (config.exposeDevTokens) 'token': token,
      if (config.exposeDevTokens) 'resetUrl': resetUrl.toString(),
      if (config.exposeDevTokens) 'delivery': delivery,
      'expiresAt': expiresAt.toIso8601String(),
    });
  });

  router.post('/password/reset', (Request request) async {
    final json = await readJsonObject(request);
    final token = (getString(json, 'token') ?? '').trim();
    final password = (getString(json, 'password') ?? '').trim();
    if (token.isEmpty || password.isEmpty) {
      return jsonError(400, 'token and password required');
    }

    final tokenHash = _hashRecoveryOrInviteToken(config, token);
    final row = await (db.select(db.passwordResetTokens)
          ..where((t) => t.tokenHash.equals(tokenHash) & t.usedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return jsonError(401, 'invalid token');
    final now = DateTime.now().toUtc();
    if (row.expiresAt.isBefore(now)) return jsonError(401, 'token expired');

    final user = await db.getUserById(row.userId);
    if (user.disabledAt != null) return jsonError(403, 'account disabled');

    final pwHash = await passwordHasher.hash(password);
    await db.transaction(() async {
      await (db.update(db.users)..where((u) => u.id.equals(user.id))).write(
        UsersCompanion(passwordHash: Value(pwHash)),
      );
      await (db.update(db.passwordResetTokens)..where((t) => t.id.equals(row.id))).write(
        PasswordResetTokensCompanion(usedAt: Value(now)),
      );
      await (db.delete(db.passwordResetTokens)..where((t) => t.userId.equals(user.id) & t.usedAt.isNull())).go();
      // Revoke all sessions on password reset.
      await (db.delete(db.sessions)..where((s) => s.userId.equals(user.id))).go();
    });

    await _audit(
      db,
      action: 'auth.password_reset_ok',
      actorUserId: user.id,
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse(
      {'ok': true},
      headers: {
        HttpHeaders.setCookieHeader: buildClearCookie(
          name: config.cookieName,
          secure: config.cookieSecure,
          sameSite: config.cookieSameSite,
        ),
      },
    );
  });

  router.post('/login', (Request request) async {
    final json = await readJsonObject(request);
    final email = (getString(json, 'email') ?? '').trim().toLowerCase();
    final password = (getString(json, 'password') ?? '').toString();
    if (email.isEmpty || password.isEmpty) {
      return jsonError(400, 'email and password required');
    }

    final user = await db.getUserByEmail(email);
    if (user == null) {
      await _audit(
        db,
        action: 'auth.login_failed',
        metadata: {'email': email, 'reason': 'not_found'},
        ip: remoteIp(request),
        userAgent: request.headers['user-agent'],
      );
      return jsonError(401, 'invalid credentials');
    }
    if (user.disabledAt != null) {
      await _audit(
        db,
        action: 'auth.login_failed',
        actorUserId: user.id,
        metadata: {'email': email, 'reason': 'disabled'},
        ip: remoteIp(request),
        userAgent: request.headers['user-agent'],
      );
      return jsonError(403, 'account disabled');
    }

    final ok = await passwordHasher.verify(password, user.passwordHash);
    if (!ok) {
      await _audit(
        db,
        action: 'auth.login_failed',
        actorUserId: user.id,
        metadata: {'reason': 'bad_password'},
        ip: remoteIp(request),
        userAgent: request.headers['user-agent'],
      );
      return jsonError(401, 'invalid credentials');
    }

    // Best-effort rehash if params changed.
    // ignore: unawaited_futures
    _maybeUpgradePasswordHash(db, passwordHasher: passwordHasher, user: user, password: password);

    final has2fa = await _isTotpEnabled(db, userId: user.id);
    final now = DateTime.now().toUtc();
    final session = await _createSession(
      db: db,
      config: config,
      userId: user.id,
      activeTenantId: null,
      mfaVerified: !has2fa,
      recentAuthAt: now,
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
      now: now,
    );

    final csrfToken = _csrfTokenFor(session);
    await _audit(
      db,
      action: 'auth.login_ok',
      actorUserId: user.id,
      metadata: {'mfaRequired': has2fa},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );
    return jsonResponse(
      {
        'user': {'id': user.id, 'email': user.email},
        'session': {
          'mfaRequired': has2fa,
          'mfaVerified': session.mfaVerified,
          'activeTenantId': session.activeTenantId,
        },
        'csrfToken': csrfToken,
      },
      headers: {
        HttpHeaders.setCookieHeader: buildSetCookie(
          name: config.cookieName,
          value: session.id,
          secure: config.cookieSecure,
          sameSite: config.cookieSameSite,
          maxAge: config.sessionLifetime,
        ),
      },
    );
  });

  router.post('/bootstrap', (Request request) async {
    // Create the very first user and make them owner of the default tenant.
    final existing = await (db.selectOnly(db.users)
          ..addColumns([db.users.id])
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return jsonError(409, 'already bootstrapped');

    final tenant = await db.maybeGetTenantBySlug(config.defaultTenantSlug);
    if (tenant == null) {
      return jsonError(
        500,
        'default tenant not found',
        details: {'hint': 'Enable SOLIDUS_AUTO_CREATE_DEFAULT_TENANT=1.'},
      );
    }

    final json = await readJsonObject(request);
    final email = (getString(json, 'email') ?? '').trim().toLowerCase();
    final password = (getString(json, 'password') ?? '').trim();
    if (email.isEmpty || password.isEmpty) {
      return jsonError(400, 'email and password required');
    }

    final now = DateTime.now().toUtc();
    final userId = const Uuid().v4();
    final pwHash = await passwordHasher.hash(password);

    await db.transaction(() async {
      await db.into(db.users).insert(
            UsersCompanion.insert(
              id: userId,
              email: email,
              passwordHash: pwHash,
              emailVerifiedAt: const Value.absent(),
              disabledAt: const Value.absent(),
              createdAt: now,
            ),
          );
      await db.into(db.memberships).insert(
            MembershipsCompanion.insert(
              tenantId: tenant.id,
              userId: userId,
              role: 'owner',
              createdAt: now,
            ),
          );
    });

    await _audit(
      db,
      action: 'auth.bootstrap',
      actorUserId: userId,
      metadata: {'email': email, 'tenantId': tenant.id},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );
    return jsonResponse(
      {'ok': true, 'tenant': {'slug': tenant.slug}},
      statusCode: 201,
    );
  });

  router.post('/logout', (Request request) async {
    final auth = request.auth;
    if (auth != null) {
      await db.deleteSession(auth.session.id);
      await _audit(
        db,
        action: 'auth.logout',
        actorUserId: auth.user.id,
        tenantId: auth.session.activeTenantId,
        metadata: {'sessionId': auth.session.id},
        ip: remoteIp(request),
        userAgent: request.headers['user-agent'],
      );
    }
    return jsonResponse(
      {'ok': true},
      headers: {
        HttpHeaders.setCookieHeader: buildClearCookie(
          name: config.cookieName,
          secure: config.cookieSecure,
          sameSite: config.cookieSameSite,
        ),
      },
    );
  });

  router.get('/me', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');
    final user = auth.user;
    final session = auth.session;
    return jsonResponse({
      'user': {
        'id': user.id,
        'email': user.email,
        'emailVerifiedAt': user.emailVerifiedAt?.toIso8601String(),
      },
      'session': {
        'id': session.id,
        'mfaVerified': session.mfaVerified,
        'recentAuthAt': session.recentAuthAt?.toIso8601String(),
        'activeTenantId': session.activeTenantId,
        'expiresAt': session.expiresAt.toIso8601String(),
      },
      'csrfToken': _csrfTokenFor(session),
    });
  });

  router.get('/tenants', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');

    final rows = await (db.select(db.memberships).join([
      innerJoin(db.tenants, db.tenants.id.equalsExp(db.memberships.tenantId)),
    ])..where(db.memberships.userId.equals(auth.user.id)))
        .get();

    final tenants = rows.map((row) {
      final t = row.readTable(db.tenants);
      final m = row.readTable(db.memberships);
      return {
        'id': t.id,
        'slug': t.slug,
        'name': t.name,
        'role': m.role,
      };
    }).toList();

    return jsonResponse({'tenants': tenants});
  });

  router.post('/tenants/select', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');

    final json = await readJsonObject(request);
    final slug = (getString(json, 'slug') ?? '').trim();
    if (slug.isEmpty) return jsonError(400, 'slug required');

    final tenant = await db.maybeGetTenantBySlug(slug);
    if (tenant == null) return jsonError(404, 'tenant not found');

    final membership = await db.getMembership(tenantId: tenant.id, userId: auth.user.id);
    if (membership == null) return jsonError(403, 'not a member of tenant');

    await (db.update(db.sessions)..where((s) => s.id.equals(auth.session.id))).write(
      SessionsCompanion(activeTenantId: Value(tenant.id)),
    );
    await _audit(
      db,
      action: 'tenant.selected',
      actorUserId: auth.user.id,
      tenantId: tenant.id,
      metadata: {'slug': tenant.slug},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse({
      'ok': true,
      'activeTenant': {'id': tenant.id, 'slug': tenant.slug},
    });
  });

  router.post('/tenants', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');

    final json = await readJsonObject(request);
    final slug = (getString(json, 'slug') ?? '').trim();
    final name = (getString(json, 'name') ?? '').trim();
    final signupMode = (getString(json, 'signupMode') ?? config.defaultSignupMode).trim();
    if (slug.isEmpty || name.isEmpty) return jsonError(400, 'slug and name required');

    final existing = await db.maybeGetTenantBySlug(slug);
    if (existing != null) return jsonError(409, 'tenant slug already exists');

    final tenantId = const Uuid().v4();
    final now = DateTime.now().toUtc();
    await db.transaction(() async {
      await db.into(db.tenants).insert(
            TenantsCompanion.insert(
              id: tenantId,
              slug: slug,
              name: name,
              createdAt: now,
            ),
          );
      await db.into(db.tenantSettings).insert(
            TenantSettingsCompanion.insert(
              tenantId: tenantId,
              signupMode: signupMode,
              requireMfaForAdmins: const Value(false),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.memberships).insert(
            MembershipsCompanion.insert(
              tenantId: tenantId,
              userId: auth.user.id,
              role: 'owner',
              createdAt: now,
            ),
          );
    });

    return jsonResponse(
      {'ok': true, 'tenant': {'id': tenantId, 'slug': slug, 'name': name}},
      statusCode: 201,
    );
  });

  router.get('/sessions', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');
    final rows = await (db.select(db.sessions)..where((s) => s.userId.equals(auth.user.id))).get();
    final sessions = rows
        .map((s) => {
              'id': s.id,
              'createdAt': s.createdAt.toIso8601String(),
              'lastSeenAt': s.lastSeenAt.toIso8601String(),
              'expiresAt': s.expiresAt.toIso8601String(),
              'activeTenantId': s.activeTenantId,
              'mfaVerified': s.mfaVerified,
              'ip': s.ip,
              'userAgent': s.userAgent,
              'isCurrent': s.id == auth.session.id,
            })
        .toList();
    return jsonResponse({'sessions': sessions});
  });

  router.post('/sessions/<id>/revoke', (Request request, String id) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');
    final row = await db.getSessionById(id);
    if (row == null || row.userId != auth.user.id) return jsonError(404, 'session not found');
    await db.deleteSession(id);
    final headers = <String, String>{};
    if (id == auth.session.id) {
      headers[HttpHeaders.setCookieHeader] = buildClearCookie(
        name: config.cookieName,
        secure: config.cookieSecure,
        sameSite: config.cookieSameSite,
      );
    }
    await _audit(
      db,
      action: 'auth.session_revoked',
      actorUserId: auth.user.id,
      tenantId: auth.session.activeTenantId,
      metadata: {'sessionId': id, 'self': id == auth.session.id},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );
    return jsonResponse({'ok': true}, headers: headers);
  });

  router.post('/sessions/revoke_others', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');
    final others = await (db.select(db.sessions)
          ..where((s) => s.userId.equals(auth.user.id) & s.id.isNotValue(auth.session.id)))
        .get();
    for (final s in others) {
      await db.deleteSession(s.id);
    }
    await _audit(
      db,
      action: 'auth.sessions_revoked_others',
      actorUserId: auth.user.id,
      tenantId: auth.session.activeTenantId,
      metadata: {'count': others.length},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );
    return jsonResponse({'ok': true, 'revoked': others.length});
  });

  // 2FA enrollment
  router.post('/mfa/enroll/start', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');
    final recentOk = _isRecent(auth.session, window: config.recentAuthWindow);
    if (!recentOk) return jsonError(403, 'recent login required');

    final existing = await (db.select(db.totpCredentials)
          ..where((c) => c.userId.equals(auth.user.id)))
        .getSingleOrNull();
    if (existing?.enabledAt != null) {
      return jsonError(409, '2fa already enabled');
    }

    final secret = randomBytes(20);
    final secretB32 = Base32.encode(secret);
    final label = Uri.encodeComponent('${config.issuer}:${auth.user.email}');
    final issuer = Uri.encodeComponent(config.issuer);
    final otpauthUri =
        'otpauth://totp/$label?secret=$secretB32&issuer=$issuer&digits=${totp.digits}&period=${totp.periodSeconds}';

    final encrypted = await encryptor.encrypt(secret);
    final now = DateTime.now().toUtc();

    await db.into(db.totpCredentials).insertOnConflictUpdate(
          TotpCredentialsCompanion(
            userId: Value(auth.user.id),
            keyVersion: Value(config.authKeyVersion),
            secretNonce: Value(encrypted.nonce),
            secretCiphertext: Value(encrypted.ciphertext),
            enabledAt: const Value<DateTime?>(null),
            createdAt: Value(existing?.createdAt ?? now),
            updatedAt: Value(now),
          ),
        );

    return jsonResponse({
      'ok': true,
      'secret': secretB32,
      'otpauthUri': otpauthUri,
    });
  });

  router.post('/mfa/enroll/confirm', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');
    final recentOk = _isRecent(auth.session, window: config.recentAuthWindow);
    if (!recentOk) return jsonError(403, 'recent login required');

    final json = await readJsonObject(request);
    final code = (getString(json, 'code') ?? '').trim();
    if (code.isEmpty) return jsonError(400, 'code required');

    final cred = await (db.select(db.totpCredentials)
          ..where((c) => c.userId.equals(auth.user.id)))
        .getSingleOrNull();
    if (cred == null) return jsonError(409, '2fa not started');
    if (cred.enabledAt != null) return jsonError(409, '2fa already enabled');

    final secret = await encryptor.decrypt(
      nonce: cred.secretNonce,
      ciphertext: cred.secretCiphertext,
    );
    final ok = totp.verifyCode(
      secret: secret,
      code: code,
      now: DateTime.now().toUtc(),
    );
    if (!ok) return jsonError(401, 'invalid code');

    final now = DateTime.now().toUtc();
    final recoveryCodes = _generateRecoveryCodes(config: config, count: 10);
    await db.transaction(() async {
      await (db.update(db.totpCredentials)..where((c) => c.userId.equals(auth.user.id))).write(
        TotpCredentialsCompanion(
          enabledAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await (db.delete(db.recoveryCodes)..where((c) => c.userId.equals(auth.user.id))).go();
      for (final code in recoveryCodes) {
        await db.into(db.recoveryCodes).insert(
              RecoveryCodesCompanion.insert(
                id: const Uuid().v4(),
                userId: auth.user.id,
                codeHash: _hashRecoveryOrInviteToken(config, code),
                createdAt: now,
                usedAt: const Value.absent(),
              ),
            );
      }
      await (db.update(db.sessions)..where((s) => s.id.equals(auth.session.id))).write(
        SessionsCompanion(
          mfaVerified: const Value(true),
          recentAuthAt: Value(now),
        ),
      );
    });

    return jsonResponse({
      'ok': true,
      'recoveryCodes': recoveryCodes,
    });
  });

  router.post('/mfa/verify', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');
    if (auth.session.mfaVerified) return jsonError(409, 'mfa already verified');
    final enabled = await _isTotpEnabled(db, userId: auth.user.id);
    if (!enabled) return jsonError(409, '2fa not enabled');

    final json = await readJsonObject(request);
    final code = (getString(json, 'code') ?? '').trim();
    final recovery = (getString(json, 'recoveryCode') ?? '').trim();
    if (code.isEmpty && recovery.isEmpty) {
      return jsonError(400, 'code or recoveryCode required');
    }

    var ok = false;
    if (recovery.isNotEmpty) {
      ok = await _useRecoveryCode(db, config: config, userId: auth.user.id, code: recovery);
    } else {
      ok = await _verifyTotp(db, encryptor: encryptor, totp: totp, userId: auth.user.id, code: code);
    }
    if (!ok) return jsonError(401, 'invalid code');

    final now = DateTime.now().toUtc();
    final rotated = await _rotateSession(
      db: db,
      config: config,
      old: auth.session,
      now: now,
      markMfaVerified: true,
      recentAuthAt: now,
    );
    await _audit(
      db,
      action: 'auth.mfa_verified',
      actorUserId: auth.user.id,
      tenantId: auth.session.activeTenantId,
      metadata: {'via': recovery.isNotEmpty ? 'recovery' : 'totp'},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse(
      {
        'ok': true,
        'session': {'mfaVerified': true},
        'csrfToken': _csrfTokenFor(rotated),
      },
      headers: {
        HttpHeaders.setCookieHeader: buildSetCookie(
          name: config.cookieName,
          value: rotated.id,
          secure: config.cookieSecure,
          sameSite: config.cookieSameSite,
          maxAge: config.sessionLifetime,
        ),
      },
    );
  });

  router.post('/mfa/recovery/regenerate', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');
    if (!auth.session.mfaVerified) return jsonError(403, 'mfa required');
    if (!_isRecent(auth.session, window: config.recentAuthWindow)) {
      return jsonError(403, 'recent login required');
    }
    final enabled = await _isTotpEnabled(db, userId: auth.user.id);
    if (!enabled) return jsonError(409, '2fa not enabled');

    final now = DateTime.now().toUtc();
    final recoveryCodes = _generateRecoveryCodes(config: config, count: 10);
    await db.transaction(() async {
      await (db.delete(db.recoveryCodes)..where((c) => c.userId.equals(auth.user.id))).go();
      for (final code in recoveryCodes) {
        await db.into(db.recoveryCodes).insert(
              RecoveryCodesCompanion.insert(
                id: const Uuid().v4(),
                userId: auth.user.id,
                codeHash: _hashRecoveryOrInviteToken(config, code),
                createdAt: now,
                usedAt: const Value.absent(),
              ),
            );
      }
    });
    await _audit(
      db,
      action: 'auth.recovery_regenerated',
      actorUserId: auth.user.id,
      tenantId: auth.session.activeTenantId,
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );
    return jsonResponse({'ok': true, 'recoveryCodes': recoveryCodes});
  });

  router.post('/mfa/disable', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');
    if (!_isRecent(auth.session, window: config.recentAuthWindow)) {
      return jsonError(403, 'recent login required');
    }

    final enabled = await _isTotpEnabled(db, userId: auth.user.id);
    if (!enabled) return jsonError(409, '2fa not enabled');

    final json = await readJsonObject(request);
    final code = (getString(json, 'code') ?? '').trim();
    final recovery = (getString(json, 'recoveryCode') ?? '').trim();
    if (code.isEmpty && recovery.isEmpty) return jsonError(400, 'code or recoveryCode required');

    var ok = false;
    if (recovery.isNotEmpty) {
      ok = await _useRecoveryCode(db, config: config, userId: auth.user.id, code: recovery);
    } else {
      ok = await _verifyTotp(db, encryptor: encryptor, totp: totp, userId: auth.user.id, code: code);
    }
    if (!ok) return jsonError(401, 'invalid code');

    await db.transaction(() async {
      await (db.delete(db.totpCredentials)..where((c) => c.userId.equals(auth.user.id))).go();
      await (db.delete(db.recoveryCodes)..where((c) => c.userId.equals(auth.user.id))).go();
      await (db.update(db.sessions)..where((s) => s.id.equals(auth.session.id))).write(
        const SessionsCompanion(mfaVerified: Value(false)),
      );
    });

    await _audit(
      db,
      action: 'auth.mfa_disabled',
      actorUserId: auth.user.id,
      tenantId: auth.session.activeTenantId,
      metadata: {'via': recovery.isNotEmpty ? 'recovery' : 'totp'},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse({'ok': true});
  });

  // Tenant-scoped: signup + invites + admin
  router.post('/t/<slug>/signup', (Request request, String slug) async {
    final json = await readJsonObject(request);
    final email = (getString(json, 'email') ?? '').trim().toLowerCase();
    final password = (getString(json, 'password') ?? '').trim();
    if (email.isEmpty || password.isEmpty) {
      return jsonError(400, 'email and password required');
    }

    final tenant = await db.maybeGetTenantBySlug(slug);
    if (tenant == null) return jsonError(404, 'tenant not found');
    final settings = await db.getTenantSettings(tenant.id);
    final mode = settings?.signupMode ?? 'invite_only';
    if (mode != 'public') return jsonError(403, 'signup is not enabled');

    final existing = await db.getUserByEmail(email);
    if (existing != null) return jsonError(409, 'account already exists');

    final now = DateTime.now().toUtc();
    final userId = const Uuid().v4();
    final pwHash = await passwordHasher.hash(password);

    await db.transaction(() async {
      await db.into(db.users).insert(
            UsersCompanion.insert(
              id: userId,
              email: email,
              passwordHash: pwHash,
              emailVerifiedAt: const Value.absent(),
              disabledAt: const Value.absent(),
              createdAt: now,
            ),
          );
      await db.into(db.memberships).insert(
            MembershipsCompanion.insert(
              tenantId: tenant.id,
              userId: userId,
              role: 'member',
              createdAt: now,
            ),
          );
    });

    return jsonResponse({'ok': true}, statusCode: 201);
  });

  router.post('/t/<slug>/invites/accept', (Request request, String slug) async {
    final json = await readJsonObject(request);
    final token = (getString(json, 'token') ?? '').trim();
    final password = (getString(json, 'password') ?? '').trim();
    if (token.isEmpty || password.isEmpty) {
      return jsonError(400, 'token and password required');
    }

    final tenant = await db.maybeGetTenantBySlug(slug);
    if (tenant == null) return jsonError(404, 'tenant not found');

    final tokenHash = _hashRecoveryOrInviteToken(config, token);
    final invite = await (db.select(db.invites)
          ..where((i) => i.tenantId.equals(tenant.id) & i.tokenHash.equals(tokenHash)))
        .getSingleOrNull();
    if (invite == null) return jsonError(401, 'invalid invite token');
    if (invite.acceptedAt != null) return jsonError(409, 'invite already used');
    if (invite.expiresAt.isBefore(DateTime.now().toUtc())) {
      return jsonError(401, 'invite expired');
    }

    final email = invite.email;
    final existing = await db.getUserByEmail(email);
    if (existing != null) {
      return jsonError(409, 'account already exists; login and accept via admin flow');
    }

    final now = DateTime.now().toUtc();
    final userId = const Uuid().v4();
    final pwHash = await passwordHasher.hash(password);

    late final Session session;
    await db.transaction(() async {
      await db.into(db.users).insert(
            UsersCompanion.insert(
              id: userId,
              email: email,
              passwordHash: pwHash,
              emailVerifiedAt: const Value.absent(),
              disabledAt: const Value.absent(),
              createdAt: now,
            ),
          );
      await db.into(db.memberships).insert(
            MembershipsCompanion.insert(
              tenantId: tenant.id,
              userId: userId,
              role: invite.role,
              createdAt: now,
            ),
          );
      await (db.update(db.invites)..where((i) => i.id.equals(invite.id))).write(
        InvitesCompanion(acceptedAt: Value(now)),
      );
      session = await _createSession(
        db: db,
        config: config,
        userId: userId,
        activeTenantId: tenant.id,
        mfaVerified: true,
        recentAuthAt: now,
        ip: null,
        userAgent: request.headers['user-agent'],
        now: now,
      );
    });

    return jsonResponse(
      {
        'ok': true,
        'csrfToken': _csrfTokenFor(session),
        'activeTenant': {'id': tenant.id, 'slug': tenant.slug},
      },
      headers: {
        HttpHeaders.setCookieHeader: buildSetCookie(
          name: config.cookieName,
          value: session.id,
          secure: config.cookieSecure,
          sameSite: config.cookieSameSite,
          maxAge: config.sessionLifetime,
        ),
      },
    );
  });

  router.post('/email/verify/request', (Request request) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');
    if (!_isRecent(auth.session, window: config.recentAuthWindow)) {
      return jsonError(403, 'recent login required');
    }

    if (auth.user.emailVerifiedAt != null) {
      return jsonError(409, 'email already verified');
    }

    final token = base64UrlNoPad(randomBytes(32));
    final tokenHash = _hashRecoveryOrInviteToken(config, token);
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(hours: 24));

    await (db.delete(db.emailVerificationTokens)
          ..where((t) => t.userId.equals(auth.user.id) & t.usedAt.isNull()))
        .go();
    await db.into(db.emailVerificationTokens).insert(
          EmailVerificationTokensCompanion.insert(
            id: const Uuid().v4(),
            userId: auth.user.id,
            tokenHash: tokenHash,
            expiresAt: expiresAt,
            usedAt: const Value.absent(),
            createdAt: now,
          ),
        );

    await _audit(
      db,
      action: 'auth.email_verification_requested',
      actorUserId: auth.user.id,
      metadata: {'created': true},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    final verifyUrl = _buildFrontendUrl(
      config: config,
      request: request,
      path: config.frontendVerifyEmailPath,
      query: {'token': token},
    );
    final tpl = EmailTemplates.emailVerification(
      appName: config.issuer,
      verifyUrl: verifyUrl.toString(),
      expiresIn: const Duration(hours: 24),
    );
    final delivery = await _deliverEmail(
      emailDispatcher: emailDispatcher,
      config: config,
      to: auth.user.email,
      subject: tpl.subject,
      text: tpl.text,
      html: tpl.html,
    );
    await _audit(
      db,
      action: 'auth.email_verification_email_delivery',
      actorUserId: auth.user.id,
      metadata: {'delivery': delivery},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse({
      'ok': true,
      if (config.exposeDevTokens) 'token': token,
      if (config.exposeDevTokens) 'verifyUrl': verifyUrl.toString(),
      if (config.exposeDevTokens) 'delivery': delivery,
      'expiresAt': expiresAt.toIso8601String(),
    });
  });

  router.post('/email/verify', (Request request) async {
    final json = await readJsonObject(request);
    final token = (getString(json, 'token') ?? '').trim();
    if (token.isEmpty) return jsonError(400, 'token required');

    final tokenHash = _hashRecoveryOrInviteToken(config, token);
    final row = await (db.select(db.emailVerificationTokens)
          ..where((t) => t.tokenHash.equals(tokenHash) & t.usedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return jsonError(401, 'invalid token');
    final now = DateTime.now().toUtc();
    if (row.expiresAt.isBefore(now)) return jsonError(401, 'token expired');

    final user = await db.getUserById(row.userId);
    if (user.disabledAt != null) return jsonError(403, 'account disabled');

    await db.transaction(() async {
      await (db.update(db.users)..where((u) => u.id.equals(user.id))).write(
        UsersCompanion(emailVerifiedAt: Value(now)),
      );
      await (db.update(db.emailVerificationTokens)..where((t) => t.id.equals(row.id))).write(
        EmailVerificationTokensCompanion(usedAt: Value(now)),
      );
      await (db.delete(db.emailVerificationTokens)..where((t) => t.userId.equals(user.id) & t.usedAt.isNull())).go();
    });

    await _audit(
      db,
      action: 'auth.email_verified',
      actorUserId: user.id,
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse({'ok': true});
  });

  router.post('/t/<slug>/invites/accept_existing', (Request request, String slug) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');

    final json = await readJsonObject(request);
    final token = (getString(json, 'token') ?? '').trim();
    if (token.isEmpty) return jsonError(400, 'token required');

    final tenant = await db.maybeGetTenantBySlug(slug);
    if (tenant == null) return jsonError(404, 'tenant not found');

    final tokenHash = _hashRecoveryOrInviteToken(config, token);
    final invite = await (db.select(db.invites)
          ..where((i) => i.tenantId.equals(tenant.id) & i.tokenHash.equals(tokenHash)))
        .getSingleOrNull();
    if (invite == null) return jsonError(401, 'invalid invite token');
    if (invite.acceptedAt != null) return jsonError(409, 'invite already used');
    if (invite.expiresAt.isBefore(DateTime.now().toUtc())) return jsonError(401, 'invite expired');
    if (invite.email != auth.user.email) {
      return jsonError(403, 'invite email mismatch');
    }

    final existingMembership = await db.getMembership(tenantId: tenant.id, userId: auth.user.id);
    if (existingMembership != null) return jsonError(409, 'already a member of tenant');

    final now = DateTime.now().toUtc();
    await db.transaction(() async {
      await db.into(db.memberships).insert(
            MembershipsCompanion.insert(
              tenantId: tenant.id,
              userId: auth.user.id,
              role: invite.role,
              createdAt: now,
            ),
          );
      await (db.update(db.invites)..where((i) => i.id.equals(invite.id))).write(
        InvitesCompanion(acceptedAt: Value(now)),
      );
      await (db.update(db.sessions)..where((s) => s.id.equals(auth.session.id))).write(
        SessionsCompanion(activeTenantId: Value(tenant.id)),
      );
    });

    await _audit(
      db,
      action: 'tenant.invite_accepted_existing',
      actorUserId: auth.user.id,
      tenantId: tenant.id,
      metadata: {'role': invite.role},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse({'ok': true, 'activeTenant': {'id': tenant.id, 'slug': tenant.slug}});
  });

  router.post('/t/<slug>/admin/invites', (Request request, String slug) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');

    final tenant = await db.maybeGetTenantBySlug(slug);
    if (tenant == null) return jsonError(404, 'tenant not found');
    final membership = await db.getMembership(tenantId: tenant.id, userId: auth.user.id);
    if (membership == null) return jsonError(403, 'not a member of tenant');
    if (membership.role != 'owner' && membership.role != 'admin') {
      return jsonError(403, 'insufficient role');
    }
    final mfaPolicyError = await _enforceAdminMfaPolicy(db, auth: auth, tenantId: tenant.id);
    if (mfaPolicyError != null) return mfaPolicyError;
    if (!_isRecent(auth.session, window: config.recentAuthWindow)) {
      return jsonError(403, 'recent login required');
    }

    final json = await readJsonObject(request);
    final email = (getString(json, 'email') ?? '').trim().toLowerCase();
    final role = (getString(json, 'role') ?? 'member').trim();
    if (email.isEmpty) return jsonError(400, 'email required');

    final token = base64UrlNoPad(randomBytes(32));
    final tokenHash = _hashRecoveryOrInviteToken(config, token);
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(days: 7));

    await db.into(db.invites).insert(
          InvitesCompanion.insert(
            id: const Uuid().v4(),
            tenantId: tenant.id,
            email: email,
            role: role,
            tokenHash: tokenHash,
            expiresAt: expiresAt,
            acceptedAt: const Value.absent(),
            createdAt: now,
          ),
        );
    await _audit(
      db,
      action: 'tenant.invite_created',
      actorUserId: auth.user.id,
      tenantId: tenant.id,
      metadata: {'email': email, 'role': role},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse(
      {
        'ok': true,
        if (config.exposeInviteTokens) 'token': token,
        'expiresAt': expiresAt.toIso8601String(),
      },
      statusCode: 201,
    );
  });

  router.get('/t/<slug>/me', (Request request, String slug) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');

    final tenant = await db.maybeGetTenantBySlug(slug);
    if (tenant == null) return jsonError(404, 'tenant not found');
    final membership = await db.getMembership(tenantId: tenant.id, userId: auth.user.id);
    if (membership == null) return jsonError(403, 'not a member of tenant');

    if (auth.session.activeTenantId != tenant.id) {
      return jsonError(409, 'tenant not selected', code: 'TENANT_NOT_SELECTED', details: {
        'hint': 'Call POST /tenants/select with this tenant slug first.',
      });
    }

    return jsonResponse({
      'user': {'id': auth.user.id, 'email': auth.user.email},
      'tenant': {'id': tenant.id, 'slug': tenant.slug, 'name': tenant.name},
      'role': membership.role,
    });
  });

  router.get('/t/<slug>/admin/members', (Request request, String slug) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');

    final tenant = await db.maybeGetTenantBySlug(slug);
    if (tenant == null) return jsonError(404, 'tenant not found');
    final me = await db.getMembership(tenantId: tenant.id, userId: auth.user.id);
    if (me == null) return jsonError(403, 'not a member of tenant');
    if (me.role != 'owner' && me.role != 'admin') return jsonError(403, 'insufficient role');
    final mfaPolicyError = await _enforceAdminMfaPolicy(db, auth: auth, tenantId: tenant.id);
    if (mfaPolicyError != null) return mfaPolicyError;

    final rows = await (db.select(db.memberships).join([
      innerJoin(db.users, db.users.id.equalsExp(db.memberships.userId)),
    ])..where(db.memberships.tenantId.equals(tenant.id)))
        .get();

    final members = rows.map((row) {
      final m = row.readTable(db.memberships);
      final u = row.readTable(db.users);
      return {'userId': u.id, 'email': u.email, 'role': m.role};
    }).toList();

    return jsonResponse({'members': members});
  });

  router.post('/t/<slug>/admin/members/<userId>/role',
      (Request request, String slug, String userId) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');

    final tenant = await db.maybeGetTenantBySlug(slug);
    if (tenant == null) return jsonError(404, 'tenant not found');
    final me = await db.getMembership(tenantId: tenant.id, userId: auth.user.id);
    if (me == null) return jsonError(403, 'not a member of tenant');
    if (me.role != 'owner' && me.role != 'admin') return jsonError(403, 'insufficient role');
    final mfaPolicyError = await _enforceAdminMfaPolicy(db, auth: auth, tenantId: tenant.id);
    if (mfaPolicyError != null) return mfaPolicyError;
    if (!_isRecent(auth.session, window: config.recentAuthWindow)) {
      return jsonError(403, 'recent login required');
    }

    final json = await readJsonObject(request);
    final role = (getString(json, 'role') ?? '').trim();
    if (role != 'member' && role != 'admin' && role != 'owner') {
      return jsonError(400, 'invalid role');
    }
    if (me.role != 'owner' && role == 'owner') {
      return jsonError(403, 'only owner can assign owner role');
    }

    final existing = await db.getMembership(tenantId: tenant.id, userId: userId);
    if (existing == null) return jsonError(404, 'membership not found');

    await (db.update(db.memberships)
          ..where((m) => m.tenantId.equals(tenant.id) & m.userId.equals(userId)))
        .write(MembershipsCompanion(role: Value(role)));

    await _audit(
      db,
      action: 'tenant.role_changed',
      actorUserId: auth.user.id,
      tenantId: tenant.id,
      target: userId,
      metadata: {'role': role},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse({'ok': true});
  });

  router.post('/t/<slug>/admin/settings/mfa', (Request request, String slug) async {
    final auth = request.auth;
    if (auth == null) return jsonError(401, 'not authenticated');

    final tenant = await db.maybeGetTenantBySlug(slug);
    if (tenant == null) return jsonError(404, 'tenant not found');
    final me = await db.getMembership(tenantId: tenant.id, userId: auth.user.id);
    if (me == null) return jsonError(403, 'not a member of tenant');
    if (me.role != 'owner') return jsonError(403, 'only owner can change settings');
    if (!_isRecent(auth.session, window: config.recentAuthWindow)) {
      return jsonError(403, 'recent login required');
    }

    final json = await readJsonObject(request);
    final requireMfaForAdmins = json['requireMfaForAdmins'];
    if (requireMfaForAdmins is! bool) {
      return jsonError(400, 'requireMfaForAdmins must be boolean');
    }

    if (requireMfaForAdmins) {
      final enabled = await _isTotpEnabled(db, userId: auth.user.id);
      if (!enabled) {
        return jsonError(
          409,
          'owner must enroll 2fa before enabling this setting',
          code: 'MFA_ENROLL_REQUIRED',
        );
      }
      if (!auth.session.mfaVerified) {
        return jsonError(403, 'mfa required');
      }
    }

    final now = DateTime.now().toUtc();
    await (db.update(db.tenantSettings)..where((s) => s.tenantId.equals(tenant.id))).write(
      TenantSettingsCompanion(
        requireMfaForAdmins: Value(requireMfaForAdmins),
        updatedAt: Value(now),
      ),
    );

    await _audit(
      db,
      action: 'tenant.mfa_policy_changed',
      actorUserId: auth.user.id,
      tenantId: tenant.id,
      metadata: {'requireMfaForAdmins': requireMfaForAdmins},
      ip: remoteIp(request),
      userAgent: request.headers['user-agent'],
    );

    return jsonResponse({'ok': true, 'requireMfaForAdmins': requireMfaForAdmins});
  });

  final handler = Pipeline()
      .addMiddleware(_errorMiddleware(logger))
      .addMiddleware(
        rateLimitMiddleware(
          limiter: rateLimiter,
          rules: [
            RateLimitRule(key: 'global', window: const Duration(minutes: 1), maxHits: 120),
          ],
          keyFor: (req) => remoteIp(req) ?? 'unknown',
          appliesTo: (req) => true,
          onLimited: () => jsonError(429, 'rate limit exceeded'),
        ),
      )
      .addMiddleware(
        rateLimitMiddleware(
          limiter: rateLimiter,
          rules: [
            RateLimitRule(key: 'login_ip', window: const Duration(minutes: 1), maxHits: 20),
          ],
          keyFor: (req) => remoteIp(req) ?? 'unknown',
          appliesTo: (req) => req.method == 'POST' && req.url.path == 'login',
          onLimited: () => jsonError(429, 'too many login attempts'),
        ),
      )
      .addMiddleware(
        rateLimitMiddleware(
          limiter: rateLimiter,
          rules: [
            RateLimitRule(key: 'mfa_ip', window: const Duration(minutes: 1), maxHits: 30),
          ],
          keyFor: (req) => remoteIp(req) ?? 'unknown',
          appliesTo: (req) => req.method == 'POST' && req.url.path.startsWith('mfa/'),
          onLimited: () => jsonError(429, 'too many attempts'),
        ),
      )
      .addMiddleware(
        rateLimitMiddleware(
          limiter: rateLimiter,
          rules: [
            RateLimitRule(key: 'pw_ip', window: const Duration(minutes: 1), maxHits: 30),
          ],
          keyFor: (req) => remoteIp(req) ?? 'unknown',
          appliesTo: (req) =>
              req.method == 'POST' &&
              (req.url.path == 'password/forgot' || req.url.path == 'password/reset'),
          onLimited: () => jsonError(429, 'too many attempts'),
        ),
      )
      .addMiddleware(_corsMiddleware(config))
      .addMiddleware(_sessionMiddleware(db: db, config: config))
      .addMiddleware(_csrfMiddleware(config))
      .addHandler(router.call);

  return handler;
}

Middleware _errorMiddleware(Logger logger) {
  return (inner) {
    return (request) async {
      try {
        return await inner(request);
      } on FormatException catch (e) {
        return jsonError(400, 'invalid request', details: {'message': e.message});
      } catch (e, st) {
        logger.severe('unhandled error: $e\n$st');
        return jsonError(500, 'internal error');
      }
    };
  };
}

Middleware _corsMiddleware(SolidusBackendConfig config) {
  return (inner) {
    return (request) async {
      final origin = request.headers['origin'];
      final allowed =
          origin != null && config.allowedOrigins.isNotEmpty && config.allowedOrigins.contains(origin);
      if (request.method == 'OPTIONS') {
        if (!allowed) return Response(204);
        return Response(
          204,
          headers: {
            'access-control-allow-origin': origin,
            'access-control-allow-credentials': 'true',
            'access-control-allow-methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
            'access-control-allow-headers': 'content-type,x-csrf-token',
            'vary': 'origin',
          },
        );
      }

      final resp = await inner(request);
      if (!allowed) return resp;
      return resp.change(headers: {
        ...resp.headers,
        'access-control-allow-origin': origin,
        'access-control-allow-credentials': 'true',
        'vary': 'origin',
      });
    };
  };
}

Middleware _sessionMiddleware({
  required AppDatabase db,
  required SolidusBackendConfig config,
}) {
  return (inner) {
    return (request) async {
      final cookies = parseCookieHeader(request.headers[HttpHeaders.cookieHeader]);
      final sid = cookies[config.cookieName];
      if (sid == null || sid.isEmpty) {
        return await inner(request);
      }

      final session = await db.getSessionById(sid);
      if (session == null) {
        final resp = await inner(request.change(context: {_ctxClearCookie: true}));
        return _maybeClearCookie(resp, request, config);
      }

      final now = DateTime.now().toUtc();
      if (session.expiresAt.isBefore(now)) {
        await db.deleteSession(session.id);
        final resp = await inner(request.change(context: {_ctxClearCookie: true}));
        return _maybeClearCookie(resp, request, config);
      }

      final user = await db.getUserById(session.userId);
      if (user.disabledAt != null) {
        await db.deleteSession(session.id);
        final resp = await inner(request.change(context: {_ctxClearCookie: true}));
        return _maybeClearCookie(resp, request, config);
      }

      // Best-effort lastSeen update.
      if (now.difference(session.lastSeenAt) > const Duration(minutes: 1)) {
        // ignore: unawaited_futures
        (db.update(db.sessions)..where((s) => s.id.equals(session.id))).write(
          SessionsCompanion(lastSeenAt: Value(now)),
        );
      }

      final auth = AuthContext(session: session, user: user);
      final resp = await inner(request.change(context: {_ctxAuth: auth}));
      return resp;
    };
  };
}

Response _maybeClearCookie(Response resp, Request request, SolidusBackendConfig config) {
  if (!request.shouldClearCookie) return resp;
  return resp.change(headers: {
    ...resp.headers,
    HttpHeaders.setCookieHeader: buildClearCookie(
      name: config.cookieName,
      secure: config.cookieSecure,
      sameSite: config.cookieSameSite,
    ),
  });
}

Middleware _csrfMiddleware(SolidusBackendConfig config) {
  const exempt = <String>{
    '/login',
    '/logout',
    '/bootstrap',
    '/password/forgot',
    '/password/reset',
    '/email/verify',
  };

  return (inner) {
    return (request) async {
      final auth = request.auth;
      final isUnsafe = request.method != 'GET' && request.method != 'HEAD' && request.method != 'OPTIONS';
      if (auth == null || !isUnsafe) return inner(request);
      final path = '/${request.url.path}';
      if (exempt.contains(path)) {
        return inner(request);
      }

      final provided = request.headers['x-csrf-token'] ?? '';
      final expected = _csrfTokenFor(auth.session);
      if (provided.isEmpty || provided != expected) {
        return jsonError(403, 'csrf token required');
      }
      return inner(request);
    };
  };
}

String _csrfTokenFor(Session session) {
  return hmacSha256Base64UrlNoPad(
    key: base64Url.decode(_padBase64Url(session.csrfSecret)),
    message: utf8.encode(session.id),
  );
}

String _padBase64Url(String input) {
  final mod = input.length % 4;
  if (mod == 0) return input;
  return input + '=' * (4 - mod);
}

Future<Session> _createSession({
  required AppDatabase db,
  required SolidusBackendConfig config,
  required String userId,
  required String? activeTenantId,
  required bool mfaVerified,
  required DateTime recentAuthAt,
  required String? ip,
  required String? userAgent,
  required DateTime now,
}) async {
  final id = base64UrlNoPad(randomBytes(32));
  final csrfSecret = base64UrlNoPad(randomBytes(32));
  final expiresAt = now.add(config.sessionLifetime);
  final sessionCompanion = SessionsCompanion.insert(
    id: id,
    userId: userId,
    activeTenantId: activeTenantId == null ? const Value.absent() : Value(activeTenantId),
    mfaVerified: Value(mfaVerified),
    recentAuthAt: Value(recentAuthAt),
    csrfSecret: csrfSecret,
    createdAt: now,
    lastSeenAt: now,
    expiresAt: expiresAt,
    ip: ip == null ? const Value.absent() : Value(ip),
    userAgent: userAgent == null ? const Value.absent() : Value(userAgent),
  );
  await db.into(db.sessions).insert(sessionCompanion);
  final created = await db.getSessionById(id);
  if (created == null) throw StateError('failed to create session');
  return created;
}

Future<Session> _rotateSession({
  required AppDatabase db,
  required SolidusBackendConfig config,
  required Session old,
  required DateTime now,
  required bool markMfaVerified,
  required DateTime recentAuthAt,
}) async {
  final rotated = await _createSession(
    db: db,
    config: config,
    userId: old.userId,
    activeTenantId: old.activeTenantId,
    mfaVerified: markMfaVerified,
    recentAuthAt: recentAuthAt,
    ip: old.ip,
    userAgent: old.userAgent,
    now: now,
  );
  await db.deleteSession(old.id);
  return rotated;
}

bool _isRecent(Session session, {required Duration window}) {
  final ts = session.recentAuthAt;
  if (ts == null) return false;
  return DateTime.now().toUtc().difference(ts) <= window;
}

Future<bool> _isTotpEnabled(AppDatabase db, {required String userId}) async {
  final row = await (db.select(db.totpCredentials)
        ..where((c) => c.userId.equals(userId) & c.enabledAt.isNotNull()))
      .getSingleOrNull();
  return row != null;
}

Future<bool> _verifyTotp(
  AppDatabase db, {
  required AesGcmEncryptor encryptor,
  required Totp totp,
  required String userId,
  required String code,
}) async {
  final row = await (db.select(db.totpCredentials)
        ..where((c) => c.userId.equals(userId) & c.enabledAt.isNotNull()))
      .getSingleOrNull();
  if (row == null) return false;
  final secret = await encryptor.decrypt(nonce: row.secretNonce, ciphertext: row.secretCiphertext);
  return totp.verifyCode(secret: secret, code: code, now: DateTime.now().toUtc());
}

List<String> _generateRecoveryCodes({
  required SolidusBackendConfig config,
  required int count,
}) {
  return List<String>.generate(
    count,
    (_) => base64UrlNoPad(randomBytes(12)),
  );
}

String _hashRecoveryOrInviteToken(SolidusBackendConfig config, String token) {
  return hmacSha256Base64UrlNoPad(
    key: config.authMasterKey,
    message: utf8.encode(token),
  );
}

EmailSender _buildEmailSender({
  required SolidusBackendConfig config,
  required Logger logger,
}) {
  switch (config.emailTransport) {
    case 'log':
      return LogEmailSender(logger);
    case 'resend':
      final from = config.emailFrom;
      final apiKey = config.resendApiKey;
      if (from == null) {
        throw StateError('Resend email transport requires SOLIDUS_EMAIL_FROM');
      }
      if (apiKey == null) {
        throw StateError('Resend email transport requires SOLIDUS_RESEND_API_KEY');
      }
      return ResendEmailSender(
        apiKey: apiKey,
        endpoint: Uri.parse(config.resendEndpoint),
      );
    case 'smtp':
      final from = config.emailFrom;
      final host = config.smtpHost;
      final port = config.smtpPort;
      if (from == null || host == null || port == null) {
        throw StateError(
          'SMTP email transport requires SOLIDUS_EMAIL_FROM, SOLIDUS_SMTP_HOST, SOLIDUS_SMTP_PORT',
        );
      }
      return SmtpEmailSender(
        host: host,
        port: port,
        ssl: config.smtpSsl,
        allowInsecure: config.smtpAllowInsecure,
        username: config.smtpUsername,
        password: config.smtpPassword,
      );
    case 'disabled':
    default:
      return _NoopEmailSender();
  }
}

class _NoopEmailSender extends EmailSender {
  @override
  Future<void> send(OutboundEmail email) async {}
}

Uri _buildFrontendUrl({
  required SolidusBackendConfig config,
  required Request request,
  required String path,
  required Map<String, String> query,
}) {
  final base = config.publicBaseUrl;
  if (base != null && base.isNotEmpty) {
    final baseUri = Uri.parse(base);
    return baseUri.replace(
      path: _joinPath(baseUri.path, path),
      queryParameters: query,
    );
  }

  final host = request.headers['host'];
  if (host != null && host.isNotEmpty) {
    return Uri(
      scheme: request.requestedUri.scheme,
      host: host.contains(':') ? host.split(':').first : host,
      port: host.contains(':') ? int.tryParse(host.split(':').last) : null,
      path: path.startsWith('/') ? path : '/$path',
      queryParameters: query,
    );
  }

  return Uri(
    scheme: 'http',
    host: config.host,
    port: config.port,
    path: path.startsWith('/') ? path : '/$path',
    queryParameters: query,
  );
}

String _joinPath(String basePath, String add) {
  final a = basePath.endsWith('/') ? basePath.substring(0, basePath.length - 1) : basePath;
  final b = add.startsWith('/') ? add : '/$add';
  if (a.isEmpty) return b;
  return '$a$b';
}

Future<String> _deliverEmail({
  required EmailDispatcher emailDispatcher,
  required SolidusBackendConfig config,
  required String to,
  required String subject,
  required String text,
  String? html,
}) async {
  if (config.emailTransport == 'disabled') return 'skipped_disabled';
  final from = config.emailFrom;
  if (from == null || from.isEmpty) return 'skipped_no_from';

  final email = OutboundEmail(
    to: to,
    from: from,
    subject: subject,
    text: text,
    html: html,
  );

  if (config.emailDeliveryMode == 'sync') {
    // Synchronous delivery is only recommended for dev; it makes requests slower.
    try {
      await emailDispatcher.sendNow(email);
      return 'sent';
    } catch (_) {
      return 'failed';
    }
  }

  emailDispatcher.enqueue(email);
  return 'queued';
}

Future<bool> _useRecoveryCode(
  AppDatabase db, {
  required SolidusBackendConfig config,
  required String userId,
  required String code,
}) async {
  final hash = _hashRecoveryOrInviteToken(config, code);
  final row = await (db.select(db.recoveryCodes)
        ..where((c) => c.userId.equals(userId) & c.usedAt.isNull() & c.codeHash.equals(hash)))
      .getSingleOrNull();
  if (row == null) return false;
  await (db.update(db.recoveryCodes)..where((c) => c.id.equals(row.id))).write(
    RecoveryCodesCompanion(usedAt: Value(DateTime.now().toUtc())),
  );
  return true;
}

Future<void> _ensureDefaultTenant(AppDatabase db, SolidusBackendConfig config) async {
  final existing = await db.maybeGetTenantBySlug(config.defaultTenantSlug);
  if (existing != null) return;

  final id = const Uuid().v4();
  final now = DateTime.now().toUtc();
  await db.transaction(() async {
    await db.into(db.tenants).insert(
          TenantsCompanion.insert(
            id: id,
            slug: config.defaultTenantSlug,
            name: config.defaultTenantName,
            createdAt: now,
          ),
        );
    await db.into(db.tenantSettings).insert(
          TenantSettingsCompanion.insert(
            tenantId: id,
            signupMode: config.defaultSignupMode,
            requireMfaForAdmins: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
        );
  });
}

Future<Response?> _enforceAdminMfaPolicy(
  AppDatabase db, {
  required AuthContext auth,
  required String tenantId,
}) async {
  final settings = await db.getTenantSettings(tenantId);
  final requireMfaForAdmins = settings?.requireMfaForAdmins ?? false;
  if (requireMfaForAdmins) {
    final enabled = await _isTotpEnabled(db, userId: auth.user.id);
    if (!enabled) {
      return jsonError(403, 'mfa enrollment required', code: 'MFA_ENROLL_REQUIRED');
    }
    if (!auth.session.mfaVerified) {
      return jsonError(403, 'mfa required');
    }
    return null;
  }

  // If the user has 2FA enabled, enforce step-up for admin actions.
  if (!auth.session.mfaVerified && await _isTotpEnabled(db, userId: auth.user.id)) {
    return jsonError(403, 'mfa required');
  }
  return null;
}

Future<void> _audit(
  AppDatabase db, {
  required String action,
  String? tenantId,
  String? actorUserId,
  String? target,
  Map<String, Object?>? metadata,
  String? ip,
  String? userAgent,
}) async {
  // ignore: unawaited_futures
  db.into(db.auditLogs).insert(
        AuditLogsCompanion.insert(
          id: const Uuid().v4(),
          tenantId: tenantId == null ? const Value.absent() : Value(tenantId),
          actorUserId: actorUserId == null ? const Value.absent() : Value(actorUserId),
          action: action,
          target: target == null ? const Value.absent() : Value(target),
          metadataJson: metadata == null ? const Value.absent() : Value(jsonEncode(metadata)),
          ip: ip == null ? const Value.absent() : Value(ip),
          userAgent: userAgent == null ? const Value.absent() : Value(userAgent),
          createdAt: DateTime.now().toUtc(),
        ),
      )
      .catchError((_) => 0);
}

Future<void> _maybeUpgradePasswordHash(
  AppDatabase db, {
  required PasswordHasher passwordHasher,
  required User user,
  required String password,
}) async {
  final parts = user.passwordHash.split(r'$');
  if (parts.length != 4) return;
  final iters = int.tryParse(parts[1]);
  if (iters == null) return;
  if (iters >= passwordHasher.iterations) return;
  final newHash = await passwordHasher.hash(password);
  // ignore: unawaited_futures
  (db.update(db.users)..where((u) => u.id.equals(user.id))).write(
    UsersCompanion(passwordHash: Value(newHash)),
  );
}

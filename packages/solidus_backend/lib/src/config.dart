import 'dart:convert';
import 'dart:io';

class SolidusBackendConfig {
  SolidusBackendConfig({
    required this.host,
    required this.port,
    required this.sqliteFilePath,
    required this.cookieName,
    required this.cookieSecure,
    required this.cookieSameSite,
    required this.allowedOrigins,
    required this.authMasterKey,
    required this.authKeyVersion,
    required this.sessionLifetime,
    required this.recentAuthWindow,
    required this.issuer,
    required this.autoCreateDefaultTenant,
    required this.defaultTenantSlug,
    required this.defaultTenantName,
    required this.defaultSignupMode,
    required this.exposeInviteTokens,
    required this.exposeDevTokens,
    required this.publicBaseUrl,
    required this.frontendResetPath,
    required this.frontendVerifyEmailPath,
    required this.emailTransport,
    required this.emailFrom,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.smtpSsl,
    required this.smtpAllowInsecure,
  });

  final String host;
  final int port;
  final String sqliteFilePath;

  final String cookieName;
  final bool cookieSecure;
  final String cookieSameSite; // Lax|Strict|None

  final Set<String> allowedOrigins; // exact origins, e.g. https://app.example.com

  final List<int> authMasterKey; // 32 bytes
  final int authKeyVersion;

  final Duration sessionLifetime;
  final Duration recentAuthWindow;
  final String issuer;

  final bool autoCreateDefaultTenant;
  final String defaultTenantSlug;
  final String defaultTenantName;
  final String defaultSignupMode; // public|invite_only|disabled

  final bool exposeInviteTokens;
  final bool exposeDevTokens;

  final String? publicBaseUrl; // e.g. https://app.example.com
  final String frontendResetPath; // e.g. /reset-password
  final String frontendVerifyEmailPath; // e.g. /verify-email

  final String emailTransport; // disabled|log|smtp
  final String? emailFrom;
  final String? smtpHost;
  final int? smtpPort;
  final String? smtpUsername;
  final String? smtpPassword;
  final bool smtpSsl;
  final bool smtpAllowInsecure;

  static SolidusBackendConfig fromEnv({Map<String, String>? env}) {
    final e = env ?? Platform.environment;
    final host = e['SOLIDUS_BACKEND_HOST'] ?? '127.0.0.1';
    final port = int.tryParse(e['SOLIDUS_BACKEND_PORT'] ?? '') ?? 8080;

    final sqliteFilePath =
        e['SOLIDUS_BACKEND_DB'] ?? '.cache/solidus_backend/solidus.sqlite';

    final cookieName = e['SOLIDUS_BACKEND_COOKIE'] ?? 'sid';
    final cookieSecure = (e['SOLIDUS_BACKEND_COOKIE_SECURE'] ?? '1') != '0';
    final cookieSameSite = e['SOLIDUS_BACKEND_COOKIE_SAMESITE'] ?? 'Lax';

    final allowedOrigins = (e['SOLIDUS_BACKEND_ALLOWED_ORIGINS'] ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final keyB64 = e['SOLIDUS_AUTH_MASTER_KEY'] ?? '';
    if (keyB64.isEmpty) {
      throw StateError(
        'Missing SOLIDUS_AUTH_MASTER_KEY (base64, 32 bytes).',
      );
    }
    final authMasterKey = base64.decode(keyB64);
    if (authMasterKey.length != 32) {
      throw StateError('SOLIDUS_AUTH_MASTER_KEY must decode to 32 bytes.');
    }

    final authKeyVersion =
        int.tryParse(e['SOLIDUS_AUTH_KEY_VERSION'] ?? '') ?? 1;

    final sessionLifetimeSeconds =
        int.tryParse(e['SOLIDUS_SESSION_LIFETIME_SECONDS'] ?? '') ??
            (60 * 60 * 24 * 30);
    final sessionLifetime = Duration(seconds: sessionLifetimeSeconds);

    final recentAuthWindowSeconds =
        int.tryParse(e['SOLIDUS_RECENT_AUTH_WINDOW_SECONDS'] ?? '') ?? (60 * 10);
    final recentAuthWindow = Duration(seconds: recentAuthWindowSeconds);

    final issuer = e['SOLIDUS_AUTH_ISSUER'] ?? 'solidus';

    final autoCreateDefaultTenant =
        (e['SOLIDUS_AUTO_CREATE_DEFAULT_TENANT'] ?? '1') != '0';
    final defaultTenantSlug = e['SOLIDUS_DEFAULT_TENANT_SLUG'] ?? 'default';
    final defaultTenantName = e['SOLIDUS_DEFAULT_TENANT_NAME'] ?? 'Default';
    final defaultSignupMode =
        e['SOLIDUS_DEFAULT_SIGNUP_MODE'] ?? 'invite_only';

    final exposeInviteTokens = (e['SOLIDUS_EXPOSE_INVITE_TOKENS'] ?? '0') == '1';
    final exposeDevTokens = (e['SOLIDUS_EXPOSE_DEV_TOKENS'] ?? '0') == '1';

    final publicBaseUrl = (e['SOLIDUS_PUBLIC_BASE_URL'] ?? '').trim();
    final frontendResetPath =
        (e['SOLIDUS_FRONTEND_RESET_PATH'] ?? '/reset-password').trim();
    final frontendVerifyEmailPath =
        (e['SOLIDUS_FRONTEND_VERIFY_EMAIL_PATH'] ?? '/verify-email').trim();

    final emailTransport = (e['SOLIDUS_EMAIL_TRANSPORT'] ?? 'disabled').trim();
    final emailFrom = (e['SOLIDUS_EMAIL_FROM'] ?? '').trim();
    final smtpHost = (e['SOLIDUS_SMTP_HOST'] ?? '').trim();
    final smtpPort = int.tryParse((e['SOLIDUS_SMTP_PORT'] ?? '').trim());
    final smtpUsername = (e['SOLIDUS_SMTP_USERNAME'] ?? '').trim();
    final smtpPassword = (e['SOLIDUS_SMTP_PASSWORD'] ?? '').trim();
    final smtpSsl = (e['SOLIDUS_SMTP_SSL'] ?? '1') != '0';
    final smtpAllowInsecure = (e['SOLIDUS_SMTP_ALLOW_INSECURE'] ?? '0') == '1';

    return SolidusBackendConfig(
      host: host,
      port: port,
      sqliteFilePath: sqliteFilePath,
      cookieName: cookieName,
      cookieSecure: cookieSecure,
      cookieSameSite: cookieSameSite,
      allowedOrigins: allowedOrigins,
      authMasterKey: authMasterKey,
      authKeyVersion: authKeyVersion,
      sessionLifetime: sessionLifetime,
      recentAuthWindow: recentAuthWindow,
      issuer: issuer,
      autoCreateDefaultTenant: autoCreateDefaultTenant,
      defaultTenantSlug: defaultTenantSlug,
      defaultTenantName: defaultTenantName,
      defaultSignupMode: defaultSignupMode,
      exposeInviteTokens: exposeInviteTokens,
      exposeDevTokens: exposeDevTokens,
      publicBaseUrl: publicBaseUrl.isEmpty ? null : publicBaseUrl,
      frontendResetPath: frontendResetPath.isEmpty ? '/reset-password' : frontendResetPath,
      frontendVerifyEmailPath:
          frontendVerifyEmailPath.isEmpty ? '/verify-email' : frontendVerifyEmailPath,
      emailTransport: emailTransport,
      emailFrom: emailFrom.isEmpty ? null : emailFrom,
      smtpHost: smtpHost.isEmpty ? null : smtpHost,
      smtpPort: smtpPort,
      smtpUsername: smtpUsername.isEmpty ? null : smtpUsername,
      smtpPassword: smtpPassword.isEmpty ? null : smtpPassword,
      smtpSsl: smtpSsl,
      smtpAllowInsecure: smtpAllowInsecure,
    );
  }
}

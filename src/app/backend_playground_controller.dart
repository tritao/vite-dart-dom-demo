import 'dart:async';
import 'dart:convert';

import './backend_api.dart';

const String backendPlaygroundControllerKey = 'backend.playground.controller';

enum BackendPlaygroundTopic {
  connection,
  auth,
  tenants,
  sessions,
  mfa,
  email,
  password,
  invites,
  output,
}

final class BackendPlaygroundEvent {
  BackendPlaygroundEvent(this.topic);
  final BackendPlaygroundTopic topic;
}

final class BackendPlaygroundController {
  BackendPlaygroundController({String baseUrl = '/api'})
      : _baseUrl = baseUrl,
        api = SolidusBackendApi(baseUrl: baseUrl);

  final SolidusBackendApi api;

  final StreamController<BackendPlaygroundEvent> _events =
      StreamController<BackendPlaygroundEvent>.broadcast(sync: true);

  Stream<BackendPlaygroundEvent> get events => _events.stream;

  bool get busy => _busy;
  String? get busyAction => _busyAction;
  String get baseUrl => _baseUrl;
  String get status => _status;
  String get lastJson => _lastJson;
  String? get csrfToken => _csrfToken;
  String? get activeTenantSlug => _activeTenantSlug;
  String? get totpSecret => _totpSecret;
  String? get otpauthUri => _otpauthUri;

  bool _busy = false;
  String? _busyAction;

  String _baseUrl;
  String _status = 'Ready.';
  String _lastJson = 'No requests yet.';

  String? _csrfToken;
  String? _activeTenantSlug;
  String? _totpSecret;
  String? _otpauthUri;

  void dispose() {
    api.close();
    _events.close();
  }

  void _emit(BackendPlaygroundTopic topic) {
    if (_events.isClosed) return;
    _events.add(BackendPlaygroundEvent(topic));
  }

  void _setStatus(String value) {
    _status = value;
    _emit(BackendPlaygroundTopic.output);
  }

  void _setLastJson(Object? obj) {
    try {
      _lastJson = const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      _lastJson = '${obj ?? ''}';
    }
    _emit(BackendPlaygroundTopic.output);
  }

  void _setBaseUrl(String next) {
    _baseUrl = next;
    api.baseUrl = next;
    _emit(BackendPlaygroundTopic.connection);
  }

  void _setCsrfToken(String? next) {
    _csrfToken = next;
    api.csrfToken = next;
    _emit(BackendPlaygroundTopic.connection);
  }

  void _setActiveTenantSlug(String? next) {
    _activeTenantSlug = next;
    _emit(BackendPlaygroundTopic.tenants);
  }

  void _setTotp({required String? secret, required String? otpauthUri}) {
    _totpSecret = secret;
    _otpauthUri = otpauthUri;
    _emit(BackendPlaygroundTopic.mfa);
  }

  void clearAuthState() {
    _setCsrfToken(null);
    _setActiveTenantSlug(null);
    _setTotp(secret: null, otpauthUri: null);
  }

  Future<T?> _run<T>({
    required BackendPlaygroundTopic topic,
    required String actionName,
    required Future<T> Function() action,
  }) async {
    if (_busy) return null;
    _busy = true;
    _busyAction = actionName;
    _emit(topic);
    _setStatus('Working…');

    try {
      api.baseUrl = _baseUrl;
      api.csrfToken = _csrfToken;
      return await action();
    } on BackendApiException catch (e) {
      _setStatus('Error: ${e.toString()}');
      _setLastJson({
        'error': e.toString(),
        'statusCode': e.statusCode,
        'body': e.body,
      });
      return null;
    } catch (e) {
      _setStatus('Error: $e');
      _setLastJson({'error': '$e'});
      return null;
    } finally {
      _busy = false;
      _busyAction = null;
      _emit(topic);
    }
  }

  bool isDisabledFor(String actionName) => _busy && _busyAction == actionName;

  void setBaseUrlFromInput(String next) {
    if (next.trim().isEmpty) return;
    _setBaseUrl(next.trim());
    _setStatus('Base URL set to $baseUrl');
  }

  Future<void> bootstrap(
      {required String email, required String password}) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.auth,
      actionName: BackendDomActions.bootstrap,
      action: () =>
          api.postJson('/bootstrap', {'email': email, 'password': password}),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Bootstrapped.');
  }

  Future<void> login({required String email, required String password}) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.auth,
      actionName: BackendDomActions.login,
      action: () =>
          api.postJson('/login', {'email': email, 'password': password}),
    );
    if (res == null) return;
    final token = res['csrfToken'];
    _setCsrfToken(token is String ? token : null);
    _setLastJson(res);
    _setStatus('Logged in.');
  }

  Future<void> logout() async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.auth,
      actionName: BackendDomActions.logout,
      action: () => api.postJson('/logout', {}),
    );
    if (res == null) return;
    clearAuthState();
    _setLastJson(res);
    _setStatus('Logged out.');
  }

  Future<void> me() async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.auth,
      actionName: BackendDomActions.refreshMe,
      action: () => api.getJson('/me'),
    );
    if (res == null) return;
    final token = res['csrfToken'];
    if (token is String) _setCsrfToken(token);
    _setLastJson(res);
    _setStatus('Fetched /me.');
  }

  Future<void> listTenants() async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.tenants,
      actionName: BackendDomActions.listTenants,
      action: () => api.getJson('/tenants'),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Fetched /tenants.');
  }

  Future<void> selectTenant({required String slug}) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.tenants,
      actionName: BackendDomActions.selectTenant,
      action: () => api.postJson('/tenants/select', {'slug': slug}, csrf: true),
    );
    if (res == null) return;
    _setActiveTenantSlug(slug);
    _setLastJson(res);
    _setStatus('Selected tenant.');
  }

  Future<void> tenantMe({required String slug}) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.tenants,
      actionName: BackendDomActions.tenantMe,
      action: () => api.getJson('/t/$slug/me'),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Fetched tenant /me.');
  }

  Future<void> listSessions() async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.sessions,
      actionName: BackendDomActions.listSessions,
      action: () => api.getJson('/sessions'),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Fetched /sessions.');
  }

  Future<void> revokeOthers() async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.sessions,
      actionName: BackendDomActions.revokeOthers,
      action: () => api.postJson('/sessions/revoke_others', {}, csrf: true),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Revoked other sessions.');
  }

  Future<void> enroll2faStart() async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.mfa,
      actionName: BackendDomActions.enroll2faStart,
      action: () => api.postJson('/mfa/enroll/start', {}, csrf: true),
    );
    if (res == null) return;
    _setTotp(
      secret: res['secret'] as String?,
      otpauthUri: res['otpauthUri'] as String?,
    );
    _setLastJson(res);
    _setStatus('2FA enroll started.');
  }

  Future<void> enroll2faConfirm({required String code}) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.mfa,
      actionName: BackendDomActions.enroll2faConfirm,
      action: () =>
          api.postJson('/mfa/enroll/confirm', {'code': code}, csrf: true),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('2FA enrolled.');
  }

  Future<void> verify2fa(
      {required String code, required String recoveryCode}) async {
    final body = <String, Object?>{};
    if (recoveryCode.isNotEmpty) {
      body['recoveryCode'] = recoveryCode;
    } else {
      body['code'] = code;
    }
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.mfa,
      actionName: BackendDomActions.verify2fa,
      action: () => api.postJson('/mfa/verify', body, csrf: true),
    );
    if (res == null) return;
    final token = res['csrfToken'];
    if (token is String) _setCsrfToken(token);
    _setLastJson(res);
    _setStatus('2FA verified.');
  }

  Future<void> disable2fa(
      {required String code, required String recoveryCode}) async {
    final body = <String, Object?>{};
    if (recoveryCode.isNotEmpty) {
      body['recoveryCode'] = recoveryCode;
    } else {
      body['code'] = code;
    }
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.mfa,
      actionName: BackendDomActions.disable2fa,
      action: () => api.postJson('/mfa/disable', body, csrf: true),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('2FA disabled.');
  }

  Future<String?> requestEmailVerifyToken() async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.email,
      actionName: BackendDomActions.emailVerifyRequest,
      action: () => api.postJson('/email/verify/request', {}, csrf: true),
    );
    if (res == null) return null;
    _setLastJson(res);
    _setStatus('Requested email verification.');
    final token = res['token'];
    return token is String ? token : null;
  }

  Future<void> verifyEmail({required String token}) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.email,
      actionName: BackendDomActions.emailVerify,
      action: () => api.postJson('/email/verify', {'token': token}),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Email verified.');
  }

  Future<String?> passwordForgot({required String email}) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.password,
      actionName: BackendDomActions.passwordForgot,
      action: () => api.postJson('/password/forgot', {'email': email}),
    );
    if (res == null) return null;
    _setLastJson(res);
    _setStatus('Password reset requested.');
    final token = res['token'];
    return token is String ? token : null;
  }

  Future<void> passwordReset(
      {required String token, required String password}) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.password,
      actionName: BackendDomActions.passwordReset,
      action: () => api
          .postJson('/password/reset', {'token': token, 'password': password}),
    );
    if (res == null) return;
    clearAuthState();
    _setLastJson(res);
    _setStatus('Password reset complete (sessions revoked).');
  }

  Future<String?> inviteCreate({
    required String tenantSlug,
    required String email,
    required String role,
  }) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.invites,
      actionName: BackendDomActions.inviteCreate,
      action: () => api.postJson(
        '/t/$tenantSlug/admin/invites',
        {'email': email, 'role': role.isEmpty ? 'member' : role},
        csrf: true,
      ),
    );
    if (res == null) return null;
    _setLastJson(res);
    _setStatus('Invite created.');
    final token = res['token'];
    return token is String ? token : null;
  }

  Future<void> inviteAccept({
    required String tenantSlug,
    required String token,
    required String password,
  }) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.invites,
      actionName: BackendDomActions.inviteAccept,
      action: () => api.postJson(
        '/t/$tenantSlug/invites/accept',
        {'token': token, 'password': password},
      ),
    );
    if (res == null) return;
    final csrfToken = res['csrfToken'];
    if (csrfToken is String) _setCsrfToken(csrfToken);
    _setActiveTenantSlug(tenantSlug);
    _setLastJson(res);
    _setStatus('Invite accepted (new user).');
  }

  Future<void> inviteAcceptExisting({
    required String tenantSlug,
    required String token,
  }) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.invites,
      actionName: BackendDomActions.inviteAcceptExisting,
      action: () => api.postJson(
        '/t/$tenantSlug/invites/accept_existing',
        {'token': token},
        csrf: true,
      ),
    );
    if (res == null) return;
    _setActiveTenantSlug(tenantSlug);
    _setLastJson(res);
    _setStatus('Invite accepted (existing user).');
  }

  Future<void> demoBootstrapAndLogin({
    required String email,
    required String password,
  }) async {
    final res = await _run<Map<String, dynamic>>(
      topic: BackendPlaygroundTopic.auth,
      actionName: BackendDomActions.demoBootstrap,
      action: () async {
        Object? bootstrapRes;
        try {
          bootstrapRes = await api.postJson(
            '/bootstrap',
            {'email': email, 'password': password},
          );
        } on BackendApiException catch (e) {
          bootstrapRes = {
            'error': e.toString(),
            'statusCode': e.statusCode,
            'body': e.body,
          };
        }

        final loginRes = await api.postJson(
          '/login',
          {'email': email, 'password': password},
        );

        final csrf = loginRes['csrfToken'];
        if (csrf is String) {
          _setCsrfToken(csrf);
        } else {
          _setCsrfToken(null);
        }

        Object? selectTenantRes;
        try {
          selectTenantRes = await api
              .postJson('/tenants/select', {'slug': 'default'}, csrf: true);
          _setActiveTenantSlug('default');
        } catch (e) {
          selectTenantRes = {'error': '$e'};
        }

        return {
          'bootstrap': bootstrapRes,
          'login': loginRes,
          'selectTenant(default)': selectTenantRes,
        };
      },
    );

    if (res == null) return;
    _setLastJson(res);
    _setStatus('Demo user ready (logged in).');
  }
}

abstract final class BackendDomActions {
  static const setBaseUrl = 'backend-set-base';

  static const bootstrap = 'backend-bootstrap';
  static const demoBootstrap = 'backend-demo-bootstrap';
  static const login = 'backend-login';
  static const logout = 'backend-logout';
  static const refreshMe = 'backend-me';

  static const listTenants = 'backend-tenants';
  static const selectTenant = 'backend-select-tenant';
  static const tenantMe = 'backend-tenant-me';

  static const listSessions = 'backend-sessions';
  static const revokeOthers = 'backend-revoke-others';

  static const enroll2faStart = 'backend-2fa-start';
  static const enroll2faConfirm = 'backend-2fa-confirm';
  static const verify2fa = 'backend-2fa-verify';
  static const disable2fa = 'backend-2fa-disable';

  static const emailVerifyRequest = 'backend-email-verify-request';
  static const emailVerify = 'backend-email-verify';

  static const passwordForgot = 'backend-password-forgot';
  static const passwordReset = 'backend-password-reset';

  static const inviteCreate = 'backend-invite-create';
  static const inviteAccept = 'backend-invite-accept';
  static const inviteAcceptExisting = 'backend-invite-accept-existing';
}

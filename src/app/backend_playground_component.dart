import 'dart:convert';

import 'package:web/web.dart' as web;

import 'package:solidus/dom_ui/action_dispatch.dart';
import 'package:solidus/dom_ui/component.dart';
import 'package:solidus/dom_ui/dom.dart' as dom;

import './backend_api.dart';

abstract final class BackendDomActions {
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

final class BackendPlaygroundState {
  BackendPlaygroundState({
    required this.baseUrl,
    required this.busy,
    required this.status,
    required this.lastJson,
    required this.csrfToken,
    required this.activeTenantSlug,
    required this.totpSecret,
    required this.otpauthUri,
  });

  final String baseUrl;
  final bool busy;
  final String status;
  final String lastJson;
  final String? csrfToken;
  final String? activeTenantSlug;
  final String? totpSecret;
  final String? otpauthUri;

  factory BackendPlaygroundState.initial() => BackendPlaygroundState(
        baseUrl: '/api',
        busy: false,
        status: 'Ready.',
        lastJson: '',
        csrfToken: null,
        activeTenantSlug: null,
        totpSecret: null,
        otpauthUri: null,
      );

  BackendPlaygroundState copyWith({
    String? baseUrl,
    bool? busy,
    String? status,
    String? lastJson,
    String? csrfToken,
    String? activeTenantSlug,
    String? totpSecret,
    String? otpauthUri,
    bool clearCsrf = false,
    bool clearTenant = false,
    bool clearTotp = false,
  }) {
    return BackendPlaygroundState(
      baseUrl: baseUrl ?? this.baseUrl,
      busy: busy ?? this.busy,
      status: status ?? this.status,
      lastJson: lastJson ?? this.lastJson,
      csrfToken: clearCsrf ? null : (csrfToken ?? this.csrfToken),
      activeTenantSlug:
          clearTenant ? null : (activeTenantSlug ?? this.activeTenantSlug),
      totpSecret: clearTotp ? null : (totpSecret ?? this.totpSecret),
      otpauthUri: clearTotp ? null : (otpauthUri ?? this.otpauthUri),
    );
  }
}

sealed class BackendPlaygroundAction {
  const BackendPlaygroundAction();
}

final class BackendSetBusy extends BackendPlaygroundAction {
  const BackendSetBusy(this.value);
  final bool value;
}

final class BackendSetStatus extends BackendPlaygroundAction {
  const BackendSetStatus(this.value);
  final String value;
}

final class BackendSetLastJson extends BackendPlaygroundAction {
  const BackendSetLastJson(this.value);
  final String value;
}

final class BackendSetBaseUrl extends BackendPlaygroundAction {
  const BackendSetBaseUrl(this.value);
  final String value;
}

final class BackendSetCsrf extends BackendPlaygroundAction {
  const BackendSetCsrf(this.value);
  final String? value;
}

final class BackendSetActiveTenant extends BackendPlaygroundAction {
  const BackendSetActiveTenant(this.slug);
  final String? slug;
}

final class BackendSetTotp extends BackendPlaygroundAction {
  const BackendSetTotp({required this.secret, required this.otpauthUri});
  final String? secret;
  final String? otpauthUri;
}

final class BackendClearAuthState extends BackendPlaygroundAction {
  const BackendClearAuthState();
}

BackendPlaygroundState backendPlaygroundReducer(
  BackendPlaygroundState state,
  BackendPlaygroundAction action,
) {
  return switch (action) {
    BackendSetBusy(value: final v) => state.copyWith(busy: v),
    BackendSetStatus(value: final v) => state.copyWith(status: v),
    BackendSetLastJson(value: final v) => state.copyWith(lastJson: v),
    BackendSetBaseUrl(value: final v) => state.copyWith(baseUrl: v),
    BackendSetCsrf(value: final v) => state.copyWith(csrfToken: v),
    BackendSetActiveTenant(slug: final v) =>
      state.copyWith(activeTenantSlug: v),
    BackendSetTotp(secret: final s, otpauthUri: final u) => state.copyWith(
        totpSecret: s,
        otpauthUri: u,
      ),
    BackendClearAuthState() => state.copyWith(
        clearCsrf: true,
        clearTenant: true,
        clearTotp: true,
      ),
  };
}

final class BackendPlaygroundComponent extends Component {
  static const _idBaseUrl = 'backend-base-url';
  static const _idEmail = 'backend-email';
  static const _idPassword = 'backend-password';
  static const _idTenantSlug = 'backend-tenant-slug';
  static const _idInviteEmail = 'backend-invite-email';
  static const _idInviteRole = 'backend-invite-role';
  static const _idInviteTenantSlug = 'backend-invite-tenant-slug';
  static const _idInviteToken = 'backend-invite-token';
  static const _idInvitePassword = 'backend-invite-password';
  static const _idInviteAcceptTenantSlug = 'backend-invite-accept-tenant-slug';
  static const _idTotpCode = 'backend-totp-code';
  static const _idRecoveryCode = 'backend-recovery-code';
  static const _idEmailVerifyToken = 'backend-email-verify-token';
  static const _idPasswordResetEmail = 'backend-password-reset-email';
  static const _idPasswordResetToken = 'backend-password-reset-token';
  static const _idPasswordResetNewPassword = 'backend-password-reset-new-password';

  static const _demoEmail = 'demo@solidus.local';
  static const _demoPassword = 'demo-password-123456';

  SolidusBackendApi get _api {
    final ref = useRef<SolidusBackendApi?>('api', null);
    ref.value ??= SolidusBackendApi(baseUrl: '/api');
    return ref.value!;
  }

  ReducerHandle<BackendPlaygroundState, BackendPlaygroundAction> get _store =>
      useReducer<BackendPlaygroundState, BackendPlaygroundAction>(
        'backend',
        BackendPlaygroundState.initial(),
        backendPlaygroundReducer,
      );

  @override
  void onMount() {
    listen(root.onClick, _onClick);
  }

  @override
  void onDispose() {
    useRef<SolidusBackendApi?>('api', null).value?.close();
  }

  @override
  web.Element render() {
    final state = _store.state;

    // Seed base-url input from state if it's empty.
    useEffect('seedBaseUrlInput', [state.baseUrl], () {
      final input = query<web.HTMLInputElement>('#$_idBaseUrl');
      if (input != null && input.value.trim().isEmpty) input.value = state.baseUrl;
      return null;
    });

    web.Element pre(String text) {
      final el = web.document.createElement('pre') as web.HTMLElement;
      el.className = 'codeBlock';
      el.textContent = text;
      return el;
    }

    web.Element inputPassword({
      required String id,
      String placeholder = '',
    }) {
      final el = web.HTMLInputElement()
        ..id = id
        ..className = 'input'
        ..type = 'password'
        ..placeholder = placeholder;
      return el;
    }

    web.Element inputText({
      required String id,
      String placeholder = '',
    }) =>
        dom.inputText(id: id, className: 'input', placeholder: placeholder);

    return dom.div(id: 'backend-root', className: 'container containerWide', children: [
      dom.header(
        title: 'Backend playground',
        subtitle: 'Exercises `packages/solidus_backend` endpoints (cookies + CSRF + tenants + 2FA + email flows).',
        actions: [
          dom.linkButton('Home', href: './'),
          dom.linkButton('Demos', href: '?demos=1'),
          dom.linkButton('Docs', href: 'docs.html#/backend'),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Connection',
        subtitle: 'Default base URL is `/api` (use Vite proxy).',
        children: [
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idBaseUrl, placeholder: '/api or http://127.0.0.1:8080'),
            dom.secondaryButton('Use base URL', action: 'backend-set-base', disabled: state.busy),
          ]),
          dom.spacer(),
          dom.statusText(text: state.status, isError: state.status.toLowerCase().contains('error')),
          dom.muted('Base URL: ${state.baseUrl}'),
          if (state.csrfToken != null) dom.muted('CSRF token present'),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Auth',
        subtitle: 'Bootstrap (first user), demo bootstrap, login, logout, /me.',
        children: [
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idEmail, placeholder: 'email'),
            inputPassword(id: _idPassword, placeholder: 'password'),
            dom.primaryButton('Bootstrap', action: BackendDomActions.bootstrap, disabled: state.busy),
            dom.secondaryButton(
              'Demo bootstrap + login',
              action: BackendDomActions.demoBootstrap,
              disabled: state.busy,
            ),
            dom.primaryButton('Login', action: BackendDomActions.login, disabled: state.busy),
            dom.secondaryButton('Logout', action: BackendDomActions.logout, disabled: state.busy),
            dom.secondaryButton('GET /me', action: BackendDomActions.refreshMe, disabled: state.busy),
          ]),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Tenants',
        subtitle: 'List and select active tenant; then call /t/<slug>/me.',
        children: [
          dom.spacer(),
          dom.row(children: [
            dom.secondaryButton('GET /tenants', action: BackendDomActions.listTenants, disabled: state.busy),
            inputText(id: _idTenantSlug, placeholder: 'tenant slug (default)'),
            dom.primaryButton('Select tenant', action: BackendDomActions.selectTenant, disabled: state.busy),
            dom.secondaryButton('GET /t/<slug>/me', action: BackendDomActions.tenantMe, disabled: state.busy),
          ]),
          if (state.activeTenantSlug != null) dom.muted('Active tenant slug: ${state.activeTenantSlug}'),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Sessions',
        subtitle: 'List sessions and revoke others.',
        children: [
          dom.spacer(),
          dom.row(children: [
            dom.secondaryButton('GET /sessions', action: BackendDomActions.listSessions, disabled: state.busy),
            dom.dangerButton('Revoke others', action: BackendDomActions.revokeOthers, disabled: state.busy),
          ]),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: '2FA (TOTP)',
        subtitle: 'Enroll + confirm, then verify (after login if required).',
        children: [
          dom.spacer(),
          dom.row(children: [
            dom.primaryButton('Enroll start', action: BackendDomActions.enroll2faStart, disabled: state.busy),
            inputText(id: _idTotpCode, placeholder: 'TOTP code'),
            dom.primaryButton('Enroll confirm', action: BackendDomActions.enroll2faConfirm, disabled: state.busy),
          ]),
          dom.spacer(),
          if (state.totpSecret != null) dom.muted('Secret: ${state.totpSecret}'),
          if (state.otpauthUri != null) pre(state.otpauthUri!),
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idRecoveryCode, placeholder: 'recovery code (optional)'),
            dom.primaryButton('POST /mfa/verify', action: BackendDomActions.verify2fa, disabled: state.busy),
            dom.dangerButton('Disable 2FA', action: BackendDomActions.disable2fa, disabled: state.busy),
          ]),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Email verification',
        subtitle: 'Request token (requires recent login), then verify.',
        children: [
          dom.spacer(),
          dom.row(children: [
            dom.primaryButton('Request verify email', action: BackendDomActions.emailVerifyRequest, disabled: state.busy),
            inputText(id: _idEmailVerifyToken, placeholder: 'verify token'),
            dom.primaryButton('Verify', action: BackendDomActions.emailVerify, disabled: state.busy),
          ]),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Password reset',
        subtitle: 'Forgot -> reset (token may be returned when SOLIDUS_EXPOSE_DEV_TOKENS=1).',
        children: [
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idPasswordResetEmail, placeholder: 'email'),
            dom.primaryButton('Forgot', action: BackendDomActions.passwordForgot, disabled: state.busy),
          ]),
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idPasswordResetToken, placeholder: 'reset token'),
            inputPassword(id: _idPasswordResetNewPassword, placeholder: 'new password'),
            dom.primaryButton('Reset', action: BackendDomActions.passwordReset, disabled: state.busy),
          ]),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Invites',
        subtitle: 'Create invite (admin) and accept it (new or existing user).',
        children: [
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idInviteTenantSlug, placeholder: 'tenant slug (e.g. acme)'),
            inputText(id: _idInviteEmail, placeholder: 'invitee email'),
            inputText(id: _idInviteRole, placeholder: 'role (member/admin/owner)'),
            dom.primaryButton('Create invite', action: BackendDomActions.inviteCreate, disabled: state.busy),
          ]),
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idInviteAcceptTenantSlug, placeholder: 'tenant slug (e.g. acme)'),
            inputText(id: _idInviteToken, placeholder: 'invite token'),
            inputPassword(id: _idInvitePassword, placeholder: 'password (for new user)'),
            dom.primaryButton('Accept (new user)', action: BackendDomActions.inviteAccept, disabled: state.busy),
            dom.primaryButton('Accept (existing)', action: BackendDomActions.inviteAcceptExisting, disabled: state.busy),
          ]),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Last response',
        subtitle: 'Raw JSON from the last request.',
        children: [
          dom.spacer(),
          pre(state.lastJson.isEmpty ? 'No requests yet.' : state.lastJson),
        ],
      ),
    ]);
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      'backend-set-base': (_) => _setBaseUrl(),
      BackendDomActions.bootstrap: (_) => _run(_bootstrap),
      BackendDomActions.demoBootstrap: (_) => _run(_demoBootstrapAndLogin),
      BackendDomActions.login: (_) => _run(_login),
      BackendDomActions.logout: (_) => _run(_logout),
      BackendDomActions.refreshMe: (_) => _run(_me),
      BackendDomActions.listTenants: (_) => _run(_tenants),
      BackendDomActions.selectTenant: (_) => _run(_selectTenant),
      BackendDomActions.tenantMe: (_) => _run(_tenantMe),
      BackendDomActions.listSessions: (_) => _run(_sessions),
      BackendDomActions.revokeOthers: (_) => _run(_revokeOthers),
      BackendDomActions.enroll2faStart: (_) => _run(_enroll2faStart),
      BackendDomActions.enroll2faConfirm: (_) => _run(_enroll2faConfirm),
      BackendDomActions.verify2fa: (_) => _run(_verify2fa),
      BackendDomActions.disable2fa: (_) => _run(_disable2fa),
      BackendDomActions.emailVerifyRequest: (_) => _run(_emailVerifyRequest),
      BackendDomActions.emailVerify: (_) => _run(_emailVerify),
      BackendDomActions.passwordForgot: (_) => _run(_passwordForgot),
      BackendDomActions.passwordReset: (_) => _run(_passwordReset),
      BackendDomActions.inviteCreate: (_) => _run(_inviteCreate),
      BackendDomActions.inviteAccept: (_) => _run(_inviteAccept),
      BackendDomActions.inviteAcceptExisting: (_) => _run(_inviteAcceptExisting),
    });
  }

  void _setBaseUrl() {
    final input = query<web.HTMLInputElement>('#$_idBaseUrl');
    final next = input?.value.trim();
    if (next == null || next.isEmpty) return;
    _api.baseUrl = next;
    _store.dispatch(BackendSetBaseUrl(_api.baseUrl));
    _store.dispatch(BackendSetStatus('Base URL set to ${_api.baseUrl}'));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_store.state.busy) return;
    _store.dispatch(const BackendSetBusy(true));
    _store.dispatch(const BackendSetStatus('Working…'));
    try {
      _api.baseUrl = _store.state.baseUrl;
      _api.csrfToken = _store.state.csrfToken;
      await action();
    } on BackendApiException catch (e) {
      _store.dispatch(BackendSetStatus('Error: ${e.toString()}'));
      _setLastJson({'error': e.toString(), 'statusCode': e.statusCode, 'body': e.body});
    } catch (e) {
      _store.dispatch(BackendSetStatus('Error: $e'));
      _setLastJson({'error': '$e'});
    } finally {
      _store.dispatch(const BackendSetBusy(false));
    }
  }

  void _setLastJson(Object? obj) {
    final formatted = const JsonEncoder.withIndent('  ').convert(obj);
    _store.dispatch(BackendSetLastJson(formatted));
  }

  String _value(String id) => query<web.HTMLInputElement>('#$id')?.value.trim() ?? '';

  void _setValue(String id, String value) {
    final input = query<web.HTMLInputElement>('#$id');
    if (input == null) return;
    input.value = value;
  }

  Future<void> _bootstrap() async {
    final email = _value(_idEmail);
    final password = _value(_idPassword);
    final res = await _api.postJson('/bootstrap', {'email': email, 'password': password});
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Bootstrapped.'));
  }

  Future<void> _demoBootstrapAndLogin() async {
    _setValue(_idEmail, _demoEmail);
    _setValue(_idPassword, _demoPassword);

    Object? bootstrapRes;
    try {
      bootstrapRes = await _api.postJson(
        '/bootstrap',
        {'email': _demoEmail, 'password': _demoPassword},
      );
    } on BackendApiException catch (e) {
      bootstrapRes = {
        'error': e.toString(),
        'statusCode': e.statusCode,
        'body': e.body,
      };
    }

    Map<String, dynamic> loginRes;
    try {
      loginRes = await _api.postJson(
        '/login',
        {'email': _demoEmail, 'password': _demoPassword},
      );
    } on BackendApiException catch (e) {
      _store.dispatch(BackendSetStatus('Error: ${e.toString()}'));
      _setLastJson({
        'bootstrap': bootstrapRes,
        'login': {
          'error': e.toString(),
          'statusCode': e.statusCode,
          'body': e.body,
        },
      });
      return;
    }

    final csrfToken = loginRes['csrfToken'];
    _store.dispatch(BackendSetCsrf(csrfToken is String ? csrfToken : null));

    Object? selectTenantRes;
    try {
      selectTenantRes = await _api.postJson('/tenants/select', {'slug': 'default'}, csrf: true);
      _store.dispatch(const BackendSetActiveTenant('default'));
    } catch (e) {
      selectTenantRes = {'error': '$e'};
    }

    _setLastJson({
      'bootstrap': bootstrapRes,
      'login': loginRes,
      'selectTenant(default)': selectTenantRes,
    });
    _store.dispatch(const BackendSetStatus('Demo user ready (logged in).'));
  }

  Future<void> _login() async {
    final email = _value(_idEmail);
    final password = _value(_idPassword);
    final res = await _api.postJson('/login', {'email': email, 'password': password});
    final token = res['csrfToken'];
    _store.dispatch(BackendSetCsrf(token is String ? token : null));
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Logged in.'));
  }

  Future<void> _logout() async {
    final res = await _api.postJson('/logout', {});
    _store.dispatch(const BackendClearAuthState());
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Logged out.'));
  }

  Future<void> _me() async {
    final res = await _api.getJson('/me');
    final token = res['csrfToken'];
    if (token is String) _store.dispatch(BackendSetCsrf(token));
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Fetched /me.'));
  }

  Future<void> _tenants() async {
    final res = await _api.getJson('/tenants');
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Fetched /tenants.'));
  }

  Future<void> _selectTenant() async {
    final slug = _value(_idTenantSlug).isEmpty ? 'default' : _value(_idTenantSlug);
    final res = await _api.postJson('/tenants/select', {'slug': slug}, csrf: true);
    _store.dispatch(BackendSetActiveTenant(slug));
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Selected tenant.'));
  }

  Future<void> _tenantMe() async {
    final slug = _store.state.activeTenantSlug ??
        (_value(_idTenantSlug).isEmpty ? 'default' : _value(_idTenantSlug));
    final res = await _api.getJson('/t/$slug/me');
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Fetched tenant /me.'));
  }

  Future<void> _sessions() async {
    final res = await _api.getJson('/sessions');
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Fetched /sessions.'));
  }

  Future<void> _revokeOthers() async {
    final res = await _api.postJson('/sessions/revoke_others', {}, csrf: true);
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Revoked other sessions.'));
  }

  Future<void> _enroll2faStart() async {
    final res = await _api.postJson('/mfa/enroll/start', {}, csrf: true);
    _store.dispatch(
      BackendSetTotp(
        secret: res['secret'] as String?,
        otpauthUri: res['otpauthUri'] as String?,
      ),
    );
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('2FA enroll started.'));
  }

  Future<void> _enroll2faConfirm() async {
    final code = _value(_idTotpCode);
    final res = await _api.postJson('/mfa/enroll/confirm', {'code': code}, csrf: true);
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('2FA enrolled.'));
  }

  Future<void> _verify2fa() async {
    final code = _value(_idTotpCode);
    final recovery = _value(_idRecoveryCode);
    final body = <String, Object?>{};
    if (recovery.isNotEmpty) {
      body['recoveryCode'] = recovery;
    } else {
      body['code'] = code;
    }
    final res = await _api.postJson('/mfa/verify', body, csrf: true);
    final token = res['csrfToken'];
    if (token is String) _store.dispatch(BackendSetCsrf(token));
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('2FA verified.'));
  }

  Future<void> _disable2fa() async {
    final code = _value(_idTotpCode);
    final recovery = _value(_idRecoveryCode);
    final body = <String, Object?>{};
    if (recovery.isNotEmpty) {
      body['recoveryCode'] = recovery;
    } else {
      body['code'] = code;
    }
    final res = await _api.postJson('/mfa/disable', body, csrf: true);
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('2FA disabled.'));
  }

  Future<void> _emailVerifyRequest() async {
    final res = await _api.postJson('/email/verify/request', {}, csrf: true);
    final token = res['token'];
    if (token is String) {
      final input = query<web.HTMLInputElement>('#$_idEmailVerifyToken');
      if (input != null) input.value = token;
    }
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Requested email verification.'));
  }

  Future<void> _emailVerify() async {
    final token = _value(_idEmailVerifyToken);
    final res = await _api.postJson('/email/verify', {'token': token});
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Email verified.'));
  }

  Future<void> _passwordForgot() async {
    final email = _value(_idPasswordResetEmail);
    final res = await _api.postJson('/password/forgot', {'email': email});
    final token = res['token'];
    if (token is String) {
      final input = query<web.HTMLInputElement>('#$_idPasswordResetToken');
      if (input != null) input.value = token;
    }
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Password reset requested.'));
  }

  Future<void> _passwordReset() async {
    final token = _value(_idPasswordResetToken);
    final password = _value(_idPasswordResetNewPassword);
    final res = await _api.postJson('/password/reset', {'token': token, 'password': password});
    _store.dispatch(const BackendClearAuthState());
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Password reset complete (sessions revoked).'));
  }

  Future<void> _inviteCreate() async {
    final tenantSlug = _value(_idInviteTenantSlug).isEmpty ? 'default' : _value(_idInviteTenantSlug);
    final email = _value(_idInviteEmail);
    final role = _value(_idInviteRole);
    final res = await _api.postJson(
      '/t/$tenantSlug/admin/invites',
      {'email': email, 'role': role.isEmpty ? 'member' : role},
      csrf: true,
    );
    final token = res['token'];
    if (token is String) {
      final input = query<web.HTMLInputElement>('#$_idInviteToken');
      if (input != null) input.value = token;
    }
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Invite created.'));
  }

  Future<void> _inviteAccept() async {
    final tenantSlug =
        _value(_idInviteAcceptTenantSlug).isEmpty ? 'default' : _value(_idInviteAcceptTenantSlug);
    final token = _value(_idInviteToken);
    final password = _value(_idInvitePassword);
    final res = await _api.postJson(
      '/t/$tenantSlug/invites/accept',
      {'token': token, 'password': password},
    );
    final csrfToken = res['csrfToken'];
    if (csrfToken is String) _store.dispatch(BackendSetCsrf(csrfToken));
    _store.dispatch(BackendSetActiveTenant(tenantSlug));
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Invite accepted (new user).'));
  }

  Future<void> _inviteAcceptExisting() async {
    final tenantSlug =
        _value(_idInviteAcceptTenantSlug).isEmpty ? 'default' : _value(_idInviteAcceptTenantSlug);
    final token = _value(_idInviteToken);
    final res = await _api.postJson(
      '/t/$tenantSlug/invites/accept_existing',
      {'token': token},
      csrf: true,
    );
    _store.dispatch(BackendSetActiveTenant(tenantSlug));
    _setLastJson(res);
    _store.dispatch(const BackendSetStatus('Invite accepted (existing user).'));
  }
}

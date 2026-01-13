import 'dart:convert';

import 'package:web/web.dart' as web;

import 'package:solidus/dom_ui/action_dispatch.dart';
import 'package:solidus/dom_ui/component.dart';
import 'package:solidus/dom_ui/dom.dart' as dom;

import './backend_api.dart';

abstract final class BackendDomActions {
  static const bootstrap = 'backend-bootstrap';
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

  SolidusBackendApi get _api {
    final ref = useRef<SolidusBackendApi?>('api', null);
    ref.value ??= SolidusBackendApi(baseUrl: '/api');
    return ref.value!;
  }

  @override
  void onMount() {
    listen(root.onClick, _onClick);
    // Default base URL (use Vite proxy).
    useSignal<String>('baseUrl', '/api');
  }

  @override
  void onDispose() {
    useRef<SolidusBackendApi?>('api', null).value?.close();
  }

  @override
  web.Element render() {
    final busy = useSignal<bool>('busy', false);
    final status = useSignal<String>('status', 'Ready.');
    final lastJson = useSignal<String>('lastJson', '');
    final csrf = useSignal<String?>('csrf', null);
    final activeTenantSlug = useSignal<String?>('activeTenantSlug', null);
    final totpSecret = useSignal<String?>('totpSecret', null);
    final otpAuthUri = useSignal<String?>('otpauth', null);
    final baseUrl = useSignal<String>('baseUrl', '/api');

    useEffect('syncCsrf', [csrf.value], () {
      _api.csrfToken = csrf.value;
      return null;
    });

    useEffect('syncBaseUrl', [baseUrl.value], () {
      _api.baseUrl = baseUrl.value;
      return null;
    });

    useEffect('seedBaseUrlInput', [baseUrl.value], () {
      final input = query<web.HTMLInputElement>('#$_idBaseUrl');
      if (input != null && input.value.trim().isEmpty) input.value = baseUrl.value;
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
            dom.secondaryButton('Use base URL', action: 'backend-set-base', disabled: busy.value),
          ]),
          dom.spacer(),
          dom.statusText(text: status.value, isError: status.value.toLowerCase().contains('error')),
          dom.muted('Base URL: ${baseUrl.value}'),
          if (csrf.value != null) dom.muted('CSRF token present'),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Auth',
        subtitle: 'Bootstrap (first user), login, logout, /me.',
        children: [
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idEmail, placeholder: 'email'),
            inputPassword(id: _idPassword, placeholder: 'password'),
            dom.primaryButton('Bootstrap', action: BackendDomActions.bootstrap, disabled: busy.value),
            dom.primaryButton('Login', action: BackendDomActions.login, disabled: busy.value),
            dom.secondaryButton('Logout', action: BackendDomActions.logout, disabled: busy.value),
            dom.secondaryButton('GET /me', action: BackendDomActions.refreshMe, disabled: busy.value),
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
            dom.secondaryButton('GET /tenants', action: BackendDomActions.listTenants, disabled: busy.value),
            inputText(id: _idTenantSlug, placeholder: 'tenant slug (default)'),
            dom.primaryButton('Select tenant', action: BackendDomActions.selectTenant, disabled: busy.value),
            dom.secondaryButton('GET /t/<slug>/me', action: BackendDomActions.tenantMe, disabled: busy.value),
          ]),
          if (activeTenantSlug.value != null) dom.muted('Active tenant slug: ${activeTenantSlug.value}'),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Sessions',
        subtitle: 'List sessions and revoke others.',
        children: [
          dom.spacer(),
          dom.row(children: [
            dom.secondaryButton('GET /sessions', action: BackendDomActions.listSessions, disabled: busy.value),
            dom.dangerButton('Revoke others', action: BackendDomActions.revokeOthers, disabled: busy.value),
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
            dom.primaryButton('Enroll start', action: BackendDomActions.enroll2faStart, disabled: busy.value),
            inputText(id: _idTotpCode, placeholder: 'TOTP code'),
            dom.primaryButton('Enroll confirm', action: BackendDomActions.enroll2faConfirm, disabled: busy.value),
          ]),
          dom.spacer(),
          if (totpSecret.value != null) dom.muted('Secret: ${totpSecret.value}'),
          if (otpAuthUri.value != null) pre(otpAuthUri.value!),
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idRecoveryCode, placeholder: 'recovery code (optional)'),
            dom.primaryButton('POST /mfa/verify', action: BackendDomActions.verify2fa, disabled: busy.value),
            dom.dangerButton('Disable 2FA', action: BackendDomActions.disable2fa, disabled: busy.value),
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
            dom.primaryButton('Request verify email', action: BackendDomActions.emailVerifyRequest, disabled: busy.value),
            inputText(id: _idEmailVerifyToken, placeholder: 'verify token'),
            dom.primaryButton('Verify', action: BackendDomActions.emailVerify, disabled: busy.value),
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
            dom.primaryButton('Forgot', action: BackendDomActions.passwordForgot, disabled: busy.value),
          ]),
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idPasswordResetToken, placeholder: 'reset token'),
            inputPassword(id: _idPasswordResetNewPassword, placeholder: 'new password'),
            dom.primaryButton('Reset', action: BackendDomActions.passwordReset, disabled: busy.value),
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
            dom.primaryButton('Create invite', action: BackendDomActions.inviteCreate, disabled: busy.value),
          ]),
          dom.spacer(),
          dom.row(children: [
            inputText(id: _idInviteAcceptTenantSlug, placeholder: 'tenant slug (e.g. acme)'),
            inputText(id: _idInviteToken, placeholder: 'invite token'),
            inputPassword(id: _idInvitePassword, placeholder: 'password (for new user)'),
            dom.primaryButton('Accept (new user)', action: BackendDomActions.inviteAccept, disabled: busy.value),
            dom.primaryButton('Accept (existing)', action: BackendDomActions.inviteAcceptExisting, disabled: busy.value),
          ]),
        ],
      ),
      dom.spacer(),
      dom.section(
        title: 'Last response',
        subtitle: 'Raw JSON from the last request.',
        children: [
          dom.spacer(),
          if (lastJson.value.isEmpty) dom.muted('No requests yet.') else pre(lastJson.value),
        ],
      ),
    ]);
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      'backend-set-base': (_) => _setBaseUrl(),
      BackendDomActions.bootstrap: (_) => _run(_bootstrap),
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
    useSignal<String>('baseUrl', '/api').value = _api.baseUrl;
    useSignal<String>('status', 'Ready.').value = 'Base URL set to ${_api.baseUrl}';
  }

  Future<void> _run(Future<void> Function() action) async {
    final busy = useSignal<bool>('busy', false);
    if (busy.value) return;
    busy.value = true;
    useSignal<String>('status', 'Ready.').value = 'Working…';
    try {
      await action();
    } on BackendApiException catch (e) {
      useSignal<String>('status', 'Ready.').value = 'Error: ${e.toString()}';
      _setLastJson({'error': e.toString(), 'statusCode': e.statusCode, 'body': e.body});
    } catch (e) {
      useSignal<String>('status', 'Ready.').value = 'Error: $e';
      _setLastJson({'error': '$e'});
    } finally {
      busy.value = false;
    }
  }

  void _setLastJson(Object? obj) {
    final formatted = const JsonEncoder.withIndent('  ').convert(obj);
    useSignal<String>('lastJson', '').value = formatted;
  }

  String _value(String id) => query<web.HTMLInputElement>('#$id')?.value.trim() ?? '';

  Future<void> _bootstrap() async {
    final email = _value(_idEmail);
    final password = _value(_idPassword);
    final res = await _api.postJson('/bootstrap', {'email': email, 'password': password});
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Bootstrapped.';
  }

  Future<void> _login() async {
    final email = _value(_idEmail);
    final password = _value(_idPassword);
    final res = await _api.postJson('/login', {'email': email, 'password': password});
    final token = res['csrfToken'];
    useSignal<String?>('csrf', null).value = token is String ? token : null;
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Logged in.';
  }

  Future<void> _logout() async {
    final res = await _api.postJson('/logout', {});
    useSignal<String?>('csrf', null).value = null;
    useSignal<String?>('activeTenantSlug', null).value = null;
    useSignal<String?>('totpSecret', null).value = null;
    useSignal<String?>('otpauth', null).value = null;
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Logged out.';
  }

  Future<void> _me() async {
    final res = await _api.getJson('/me');
    final token = res['csrfToken'];
    if (token is String) useSignal<String?>('csrf', null).value = token;
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Fetched /me.';
  }

  Future<void> _tenants() async {
    final res = await _api.getJson('/tenants');
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Fetched /tenants.';
  }

  Future<void> _selectTenant() async {
    final slug = _value(_idTenantSlug).isEmpty ? 'default' : _value(_idTenantSlug);
    final res = await _api.postJson('/tenants/select', {'slug': slug}, csrf: true);
    useSignal<String?>('activeTenantSlug', null).value = slug;
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Selected tenant.';
  }

  Future<void> _tenantMe() async {
    final slug = useSignal<String?>('activeTenantSlug', null).value ??
        (_value(_idTenantSlug).isEmpty ? 'default' : _value(_idTenantSlug));
    final res = await _api.getJson('/t/$slug/me');
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Fetched tenant /me.';
  }

  Future<void> _sessions() async {
    final res = await _api.getJson('/sessions');
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Fetched /sessions.';
  }

  Future<void> _revokeOthers() async {
    final res = await _api.postJson('/sessions/revoke_others', {}, csrf: true);
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Revoked other sessions.';
  }

  Future<void> _enroll2faStart() async {
    final res = await _api.postJson('/mfa/enroll/start', {}, csrf: true);
    useSignal<String?>('totpSecret', null).value = res['secret'] as String?;
    useSignal<String?>('otpauth', null).value = res['otpauthUri'] as String?;
    _setLastJson(res);
    useSignal<String>('status', '').value = '2FA enroll started.';
  }

  Future<void> _enroll2faConfirm() async {
    final code = _value(_idTotpCode);
    final res = await _api.postJson('/mfa/enroll/confirm', {'code': code}, csrf: true);
    _setLastJson(res);
    useSignal<String>('status', '').value = '2FA enrolled.';
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
    if (token is String) useSignal<String?>('csrf', null).value = token;
    _setLastJson(res);
    useSignal<String>('status', '').value = '2FA verified.';
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
    useSignal<String>('status', '').value = '2FA disabled.';
  }

  Future<void> _emailVerifyRequest() async {
    final res = await _api.postJson('/email/verify/request', {}, csrf: true);
    final token = res['token'];
    if (token is String) {
      final input = query<web.HTMLInputElement>('#$_idEmailVerifyToken');
      if (input != null) input.value = token;
    }
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Requested email verification.';
  }

  Future<void> _emailVerify() async {
    final token = _value(_idEmailVerifyToken);
    final res = await _api.postJson('/email/verify', {'token': token});
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Email verified.';
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
    useSignal<String>('status', '').value = 'Password reset requested.';
  }

  Future<void> _passwordReset() async {
    final token = _value(_idPasswordResetToken);
    final password = _value(_idPasswordResetNewPassword);
    final res = await _api.postJson('/password/reset', {'token': token, 'password': password});
    useSignal<String?>('csrf', null).value = null;
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Password reset complete (sessions revoked).';
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
    useSignal<String>('status', '').value = 'Invite created.';
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
    if (csrfToken is String) useSignal<String?>('csrf', null).value = csrfToken;
    useSignal<String?>('activeTenantSlug', null).value = tenantSlug;
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Invite accepted (new user).';
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
    useSignal<String?>('activeTenantSlug', null).value = tenantSlug;
    _setLastJson(res);
    useSignal<String>('status', '').value = 'Invite accepted (existing user).';
  }
}

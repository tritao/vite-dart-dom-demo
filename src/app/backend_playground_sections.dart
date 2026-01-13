import 'package:web/web.dart' as web;

import 'package:solidus/dom_ui/action_dispatch.dart';
import 'package:solidus/dom_ui/component.dart';
import 'package:solidus/dom_ui/dom.dart' as dom;

import './backend_playground_controller.dart';

abstract final class BackendPlaygroundIds {
  static const baseUrl = 'backend-base-url';

  static const email = 'backend-email';
  static const password = 'backend-password';

  static const tenantSlug = 'backend-tenant-slug';

  static const inviteEmail = 'backend-invite-email';
  static const inviteRole = 'backend-invite-role';
  static const inviteTenantSlug = 'backend-invite-tenant-slug';
  static const inviteToken = 'backend-invite-token';
  static const invitePassword = 'backend-invite-password';
  static const inviteAcceptTenantSlug = 'backend-invite-accept-tenant-slug';

  static const totpCode = 'backend-totp-code';
  static const recoveryCode = 'backend-recovery-code';

  static const emailVerifyToken = 'backend-email-verify-token';

  static const passwordResetEmail = 'backend-password-reset-email';
  static const passwordResetToken = 'backend-password-reset-token';
  static const passwordResetNewPassword = 'backend-password-reset-new-password';
}

abstract class _BackendPlaygroundSection extends Component {
  BackendPlaygroundTopic get topic;

  BackendPlaygroundController get ctrl =>
      useContext<BackendPlaygroundController>(backendPlaygroundControllerKey);

  @override
  void onMount() {
    final c = ctrl;
    listen(c.events, (event) {
      if (event.topic != topic) return;
      invalidate();
    });
    listen(root.onClick, _onClick);
  }

  void _onClick(web.MouseEvent event) {}

  String _value(String id) =>
      query<web.HTMLInputElement>('#$id')?.value.trim() ?? '';

  void _setValue(String id, String value) {
    final input = query<web.HTMLInputElement>('#$id');
    if (input == null) return;
    input.value = value;
  }

  web.Element _inputPassword({
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

  web.Element _inputText({
    required String id,
    String placeholder = '',
  }) =>
      dom.inputText(id: id, className: 'input', placeholder: placeholder);

  web.Element _pre(String text) {
    final el = web.document.createElement('pre') as web.HTMLElement;
    el.className = 'codeBlock';
    el.textContent = text;
    return el;
  }
}

final class BackendPlaygroundConnectionSection
    extends _BackendPlaygroundSection {
  @override
  BackendPlaygroundTopic get topic => BackendPlaygroundTopic.connection;

  @override
  web.Element render() {
    final c = ctrl;

    useEffect('seedBaseUrlInput', [c.baseUrl], () {
      final input =
          query<web.HTMLInputElement>('#${BackendPlaygroundIds.baseUrl}');
      if (input != null && input.value.trim().isEmpty) input.value = c.baseUrl;
      return null;
    });

    return dom.section(
      title: 'Connection',
      subtitle: 'Default base URL is `/api` (use Vite proxy).',
      children: [
        dom.spacer(),
        dom.row(children: [
          _inputText(
            id: BackendPlaygroundIds.baseUrl,
            placeholder: '/api or http://127.0.0.1:8080',
          ),
          dom.secondaryButton(
            'Use base URL',
            action: BackendDomActions.setBaseUrl,
            disabled: c.isDisabledFor(BackendDomActions.setBaseUrl),
          ),
        ]),
        dom.spacer(),
        dom.muted('Base URL: ${c.baseUrl}'),
        if (c.csrfToken != null) dom.muted('CSRF token present'),
      ],
    );
  }

  @override
  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      BackendDomActions.setBaseUrl: (_) {
        final next = _value(BackendPlaygroundIds.baseUrl);
        ctrl.setBaseUrlFromInput(next);
      },
    });
  }
}

final class BackendPlaygroundAuthSection extends _BackendPlaygroundSection {
  static const _demoEmail = 'demo@solidus.local';
  static const _demoPassword = 'demo-password-123456';

  @override
  BackendPlaygroundTopic get topic => BackendPlaygroundTopic.auth;

  @override
  web.Element render() {
    final c = ctrl;
    return dom.section(
      title: 'Auth',
      subtitle: 'Bootstrap (first user), demo bootstrap, login, logout, /me.',
      children: [
        dom.spacer(),
        dom.row(children: [
          _inputText(id: BackendPlaygroundIds.email, placeholder: 'email'),
          _inputPassword(
            id: BackendPlaygroundIds.password,
            placeholder: 'password',
          ),
          dom.primaryButton(
            'Bootstrap',
            action: BackendDomActions.bootstrap,
            disabled: c.isDisabledFor(BackendDomActions.bootstrap),
          ),
          dom.secondaryButton(
            'Demo bootstrap + login',
            action: BackendDomActions.demoBootstrap,
            disabled: c.isDisabledFor(BackendDomActions.demoBootstrap),
          ),
          dom.primaryButton(
            'Login',
            action: BackendDomActions.login,
            disabled: c.isDisabledFor(BackendDomActions.login),
          ),
          dom.secondaryButton(
            'Logout',
            action: BackendDomActions.logout,
            disabled: c.isDisabledFor(BackendDomActions.logout),
          ),
          dom.secondaryButton(
            'GET /me',
            action: BackendDomActions.refreshMe,
            disabled: c.isDisabledFor(BackendDomActions.refreshMe),
          ),
        ]),
      ],
    );
  }

  @override
  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      BackendDomActions.bootstrap: (_) {
        ctrl.bootstrap(
          email: _value(BackendPlaygroundIds.email),
          password: _value(BackendPlaygroundIds.password),
        );
      },
      BackendDomActions.demoBootstrap: (_) {
        _setValue(BackendPlaygroundIds.email, _demoEmail);
        _setValue(BackendPlaygroundIds.password, _demoPassword);
        ctrl.demoBootstrapAndLogin(email: _demoEmail, password: _demoPassword);
      },
      BackendDomActions.login: (_) {
        ctrl.login(
          email: _value(BackendPlaygroundIds.email),
          password: _value(BackendPlaygroundIds.password),
        );
      },
      BackendDomActions.logout: (_) {
        ctrl.logout();
      },
      BackendDomActions.refreshMe: (_) {
        ctrl.me();
      },
    });
  }
}

final class BackendPlaygroundTenantsSection extends _BackendPlaygroundSection {
  @override
  BackendPlaygroundTopic get topic => BackendPlaygroundTopic.tenants;

  @override
  web.Element render() {
    final c = ctrl;
    return dom.section(
      title: 'Tenants',
      subtitle: 'List and select active tenant; then call /t/<slug>/me.',
      children: [
        dom.spacer(),
        dom.row(children: [
          dom.secondaryButton(
            'GET /tenants',
            action: BackendDomActions.listTenants,
            disabled: c.isDisabledFor(BackendDomActions.listTenants),
          ),
          _inputText(
            id: BackendPlaygroundIds.tenantSlug,
            placeholder: 'tenant slug (default)',
          ),
          dom.primaryButton(
            'Select tenant',
            action: BackendDomActions.selectTenant,
            disabled: c.isDisabledFor(BackendDomActions.selectTenant),
          ),
          dom.secondaryButton(
            'GET /t/<slug>/me',
            action: BackendDomActions.tenantMe,
            disabled: c.isDisabledFor(BackendDomActions.tenantMe),
          ),
        ]),
        if (c.activeTenantSlug != null)
          dom.muted('Active tenant slug: ${c.activeTenantSlug}'),
      ],
    );
  }

  @override
  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      BackendDomActions.listTenants: (_) => ctrl.listTenants(),
      BackendDomActions.selectTenant: (_) {
        final slug = _value(BackendPlaygroundIds.tenantSlug);
        ctrl.selectTenant(slug: slug.isEmpty ? 'default' : slug);
      },
      BackendDomActions.tenantMe: (_) {
        final slug = ctrl.activeTenantSlug ??
            (_value(BackendPlaygroundIds.tenantSlug).isEmpty
                ? 'default'
                : _value(BackendPlaygroundIds.tenantSlug));
        ctrl.tenantMe(slug: slug);
      },
    });
  }
}

final class BackendPlaygroundSessionsSection extends _BackendPlaygroundSection {
  @override
  BackendPlaygroundTopic get topic => BackendPlaygroundTopic.sessions;

  @override
  web.Element render() {
    final c = ctrl;
    return dom.section(
      title: 'Sessions',
      subtitle: 'List sessions and revoke others.',
      children: [
        dom.spacer(),
        dom.row(children: [
          dom.secondaryButton(
            'GET /sessions',
            action: BackendDomActions.listSessions,
            disabled: c.isDisabledFor(BackendDomActions.listSessions),
          ),
          dom.dangerButton(
            'Revoke others',
            action: BackendDomActions.revokeOthers,
            disabled: c.isDisabledFor(BackendDomActions.revokeOthers),
          ),
        ]),
      ],
    );
  }

  @override
  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      BackendDomActions.listSessions: (_) => ctrl.listSessions(),
      BackendDomActions.revokeOthers: (_) => ctrl.revokeOthers(),
    });
  }
}

final class BackendPlaygroundMfaSection extends _BackendPlaygroundSection {
  @override
  BackendPlaygroundTopic get topic => BackendPlaygroundTopic.mfa;

  @override
  web.Element render() {
    final c = ctrl;
    return dom.section(
      title: '2FA (TOTP)',
      subtitle: 'Enroll + confirm, then verify (after login if required).',
      children: [
        dom.spacer(),
        dom.row(children: [
          dom.primaryButton(
            'Enroll start',
            action: BackendDomActions.enroll2faStart,
            disabled: c.isDisabledFor(BackendDomActions.enroll2faStart),
          ),
          _inputText(
            id: BackendPlaygroundIds.totpCode,
            placeholder: 'TOTP code',
          ),
          dom.primaryButton(
            'Enroll confirm',
            action: BackendDomActions.enroll2faConfirm,
            disabled: c.isDisabledFor(BackendDomActions.enroll2faConfirm),
          ),
        ]),
        dom.spacer(),
        if (c.totpSecret != null) dom.muted('Secret: ${c.totpSecret}'),
        if (c.otpauthUri != null) _pre(c.otpauthUri!),
        dom.spacer(),
        dom.row(children: [
          _inputText(
            id: BackendPlaygroundIds.recoveryCode,
            placeholder: 'recovery code (optional)',
          ),
          dom.primaryButton(
            'POST /mfa/verify',
            action: BackendDomActions.verify2fa,
            disabled: c.isDisabledFor(BackendDomActions.verify2fa),
          ),
          dom.dangerButton(
            'Disable 2FA',
            action: BackendDomActions.disable2fa,
            disabled: c.isDisabledFor(BackendDomActions.disable2fa),
          ),
        ]),
      ],
    );
  }

  @override
  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      BackendDomActions.enroll2faStart: (_) => ctrl.enroll2faStart(),
      BackendDomActions.enroll2faConfirm: (_) {
        ctrl.enroll2faConfirm(code: _value(BackendPlaygroundIds.totpCode));
      },
      BackendDomActions.verify2fa: (_) {
        ctrl.verify2fa(
          code: _value(BackendPlaygroundIds.totpCode),
          recoveryCode: _value(BackendPlaygroundIds.recoveryCode),
        );
      },
      BackendDomActions.disable2fa: (_) {
        ctrl.disable2fa(
          code: _value(BackendPlaygroundIds.totpCode),
          recoveryCode: _value(BackendPlaygroundIds.recoveryCode),
        );
      },
    });
  }
}

final class BackendPlaygroundEmailVerifySection
    extends _BackendPlaygroundSection {
  @override
  BackendPlaygroundTopic get topic => BackendPlaygroundTopic.email;

  @override
  web.Element render() {
    final c = ctrl;
    return dom.section(
      title: 'Email verification',
      subtitle: 'Request token (requires recent login), then verify.',
      children: [
        dom.spacer(),
        dom.row(children: [
          dom.primaryButton(
            'Request verify email',
            action: BackendDomActions.emailVerifyRequest,
            disabled: c.isDisabledFor(BackendDomActions.emailVerifyRequest),
          ),
          _inputText(
            id: BackendPlaygroundIds.emailVerifyToken,
            placeholder: 'verify token',
          ),
          dom.primaryButton(
            'Verify',
            action: BackendDomActions.emailVerify,
            disabled: c.isDisabledFor(BackendDomActions.emailVerify),
          ),
        ]),
      ],
    );
  }

  @override
  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      BackendDomActions.emailVerifyRequest: (_) async {
        final token = await ctrl.requestEmailVerifyToken();
        if (token == null) return;
        _setValue(BackendPlaygroundIds.emailVerifyToken, token);
      },
      BackendDomActions.emailVerify: (_) {
        ctrl.verifyEmail(token: _value(BackendPlaygroundIds.emailVerifyToken));
      },
    });
  }
}

final class BackendPlaygroundPasswordResetSection
    extends _BackendPlaygroundSection {
  @override
  BackendPlaygroundTopic get topic => BackendPlaygroundTopic.password;

  @override
  web.Element render() {
    final c = ctrl;
    return dom.section(
      title: 'Password reset',
      subtitle:
          'Forgot -> reset (token may be returned when SOLIDUS_EXPOSE_DEV_TOKENS=1).',
      children: [
        dom.spacer(),
        dom.row(children: [
          _inputText(
              id: BackendPlaygroundIds.passwordResetEmail,
              placeholder: 'email'),
          dom.primaryButton(
            'Forgot',
            action: BackendDomActions.passwordForgot,
            disabled: c.isDisabledFor(BackendDomActions.passwordForgot),
          ),
        ]),
        dom.spacer(),
        dom.row(children: [
          _inputText(
              id: BackendPlaygroundIds.passwordResetToken,
              placeholder: 'reset token'),
          _inputPassword(
            id: BackendPlaygroundIds.passwordResetNewPassword,
            placeholder: 'new password',
          ),
          dom.primaryButton(
            'Reset',
            action: BackendDomActions.passwordReset,
            disabled: c.isDisabledFor(BackendDomActions.passwordReset),
          ),
        ]),
      ],
    );
  }

  @override
  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      BackendDomActions.passwordForgot: (_) async {
        final token = await ctrl.passwordForgot(
            email: _value(BackendPlaygroundIds.passwordResetEmail));
        if (token == null) return;
        _setValue(BackendPlaygroundIds.passwordResetToken, token);
      },
      BackendDomActions.passwordReset: (_) {
        ctrl.passwordReset(
          token: _value(BackendPlaygroundIds.passwordResetToken),
          password: _value(BackendPlaygroundIds.passwordResetNewPassword),
        );
      },
    });
  }
}

final class BackendPlaygroundInvitesSection extends _BackendPlaygroundSection {
  @override
  BackendPlaygroundTopic get topic => BackendPlaygroundTopic.invites;

  @override
  web.Element render() {
    final c = ctrl;
    return dom.section(
      title: 'Invites',
      subtitle: 'Create invite (admin) and accept it (new or existing user).',
      children: [
        dom.spacer(),
        dom.row(children: [
          _inputText(
            id: BackendPlaygroundIds.inviteTenantSlug,
            placeholder: 'tenant slug (e.g. acme)',
          ),
          _inputText(
              id: BackendPlaygroundIds.inviteEmail,
              placeholder: 'invitee email'),
          _inputText(
              id: BackendPlaygroundIds.inviteRole,
              placeholder: 'role (member/admin/owner)'),
          dom.primaryButton(
            'Create invite',
            action: BackendDomActions.inviteCreate,
            disabled: c.isDisabledFor(BackendDomActions.inviteCreate),
          ),
        ]),
        dom.spacer(),
        dom.row(children: [
          _inputText(
            id: BackendPlaygroundIds.inviteAcceptTenantSlug,
            placeholder: 'tenant slug (e.g. acme)',
          ),
          _inputText(
              id: BackendPlaygroundIds.inviteToken,
              placeholder: 'invite token'),
          _inputPassword(
            id: BackendPlaygroundIds.invitePassword,
            placeholder: 'password (for new user)',
          ),
          dom.primaryButton(
            'Accept (new user)',
            action: BackendDomActions.inviteAccept,
            disabled: c.isDisabledFor(BackendDomActions.inviteAccept),
          ),
          dom.primaryButton(
            'Accept (existing)',
            action: BackendDomActions.inviteAcceptExisting,
            disabled: c.isDisabledFor(BackendDomActions.inviteAcceptExisting),
          ),
        ]),
      ],
    );
  }

  @override
  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      BackendDomActions.inviteCreate: (_) async {
        final tenantSlug = _value(BackendPlaygroundIds.inviteTenantSlug);
        final token = await ctrl.inviteCreate(
          tenantSlug: tenantSlug.isEmpty ? 'default' : tenantSlug,
          email: _value(BackendPlaygroundIds.inviteEmail),
          role: _value(BackendPlaygroundIds.inviteRole),
        );
        if (token == null) return;
        _setValue(BackendPlaygroundIds.inviteToken, token);
      },
      BackendDomActions.inviteAccept: (_) {
        final tenantSlug = _value(BackendPlaygroundIds.inviteAcceptTenantSlug);
        ctrl.inviteAccept(
          tenantSlug: tenantSlug.isEmpty ? 'default' : tenantSlug,
          token: _value(BackendPlaygroundIds.inviteToken),
          password: _value(BackendPlaygroundIds.invitePassword),
        );
      },
      BackendDomActions.inviteAcceptExisting: (_) {
        final tenantSlug = _value(BackendPlaygroundIds.inviteAcceptTenantSlug);
        ctrl.inviteAcceptExisting(
          tenantSlug: tenantSlug.isEmpty ? 'default' : tenantSlug,
          token: _value(BackendPlaygroundIds.inviteToken),
        );
      },
    });
  }
}

final class BackendPlaygroundOutputSection extends _BackendPlaygroundSection {
  @override
  BackendPlaygroundTopic get topic => BackendPlaygroundTopic.output;

  @override
  web.Element render() {
    final c = ctrl;
    return dom.section(
      title: 'Output',
      subtitle: 'Status and raw JSON from the last request.',
      children: [
        dom.spacer(),
        dom.statusText(
          text: c.status,
          isError: c.status.toLowerCase().contains('error'),
        ),
        dom.spacer(),
        _pre(c.lastJson),
      ],
    );
  }
}

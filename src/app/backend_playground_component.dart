import 'package:web/web.dart' as web;

import 'package:solidus/dom_ui/component.dart';
import 'package:solidus/dom_ui/dom.dart' as dom;

import './backend_playground_controller.dart';
import './backend_playground_sections.dart';

final class BackendPlaygroundComponent extends Component {
  static const _mountConnection = 'backend-mount-connection';
  static const _mountAuth = 'backend-mount-auth';
  static const _mountTenants = 'backend-mount-tenants';
  static const _mountSessions = 'backend-mount-sessions';
  static const _mountMfa = 'backend-mount-mfa';
  static const _mountEmail = 'backend-mount-email';
  static const _mountPassword = 'backend-mount-password';
  static const _mountInvites = 'backend-mount-invites';
  static const _mountOutput = 'backend-mount-output';

  BackendPlaygroundController get _ctrl {
    final ref = useRef<BackendPlaygroundController?>('backend.ctrl', null);
    ref.value ??= BackendPlaygroundController();
    return ref.value!;
  }

  @override
  void onMount() {
    final ctrl = _ctrl;
    provide<BackendPlaygroundController>(backendPlaygroundControllerKey, ctrl);
    addCleanup(ctrl.dispose);

    mountChild(
      BackendPlaygroundConnectionSection(),
      queryOrThrow<web.Element>('#$_mountConnection'),
    );
    mountChild(
      BackendPlaygroundAuthSection(),
      queryOrThrow<web.Element>('#$_mountAuth'),
    );
    mountChild(
      BackendPlaygroundTenantsSection(),
      queryOrThrow<web.Element>('#$_mountTenants'),
    );
    mountChild(
      BackendPlaygroundSessionsSection(),
      queryOrThrow<web.Element>('#$_mountSessions'),
    );
    mountChild(
      BackendPlaygroundMfaSection(),
      queryOrThrow<web.Element>('#$_mountMfa'),
    );
    mountChild(
      BackendPlaygroundEmailVerifySection(),
      queryOrThrow<web.Element>('#$_mountEmail'),
    );
    mountChild(
      BackendPlaygroundPasswordResetSection(),
      queryOrThrow<web.Element>('#$_mountPassword'),
    );
    mountChild(
      BackendPlaygroundInvitesSection(),
      queryOrThrow<web.Element>('#$_mountInvites'),
    );
    mountChild(
      BackendPlaygroundOutputSection(),
      queryOrThrow<web.Element>('#$_mountOutput'),
    );
  }

  @override
  web.Element render() {
    return dom.div(
      id: 'backend-root',
      className: 'container containerWide',
      children: [
        dom.header(
          title: 'Backend playground',
          subtitle:
              'Exercises `packages/solidus_backend` endpoints (cookies + CSRF + tenants + 2FA + email flows).',
          actions: [
            dom.linkButton('Home', href: './'),
            dom.linkButton('Demos', href: '?demos=1'),
            dom.linkButton('Docs', href: 'docs.html#/backend'),
          ],
        ),
        dom.spacer(),
        dom.mountPoint(_mountConnection),
        dom.spacer(),
        dom.mountPoint(_mountAuth),
        dom.spacer(),
        dom.mountPoint(_mountTenants),
        dom.spacer(),
        dom.mountPoint(_mountSessions),
        dom.spacer(),
        dom.mountPoint(_mountMfa),
        dom.spacer(),
        dom.mountPoint(_mountEmail),
        dom.spacer(),
        dom.mountPoint(_mountPassword),
        dom.spacer(),
        dom.mountPoint(_mountInvites),
        dom.spacer(),
        dom.mountPoint(_mountOutput),
      ],
    );
  }
}

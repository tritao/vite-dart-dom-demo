import 'dart:convert';

import 'package:web/web.dart' as web;

import 'package:solidus/dom_ui/action_dispatch.dart';
import 'package:solidus/dom_ui/component.dart';
import 'package:solidus/dom_ui/dom.dart' as dom;
import 'package:solidus/dom_ui/router.dart' as router;

import 'package:solidus/solidus_ui/table.dart' as sui;

import './admin_app_component.dart';
import './admin_controller.dart';

abstract final class _AdminIds {
  static const email = 'admin-email';
  static const password = 'admin-password';

  static const tenantSlug = 'admin-tenant-slug';
  static const tenantName = 'admin-tenant-name';
  static const tenantSignupMode = 'admin-tenant-signup-mode';

  static const inviteEmail = 'admin-invite-email';
  static const inviteRole = 'admin-invite-role';

  static const outboxStatus = 'admin-outbox-status';
}

String _value(Component c, String id) =>
    c.query<web.HTMLInputElement>('#$id')?.value.trim() ?? '';

web.Element _pre(String text) {
  final el = web.document.createElement('pre') as web.HTMLElement;
  el.className = 'codeBlock';
  el.textContent = text;
  return el;
}

final class AdminLoginPage extends Component {
  static const _demoEmail = 'demo@solidus.local';
  static const _demoPassword = 'demo-password-123456';
  static const _actionPrefillDemo = 'admin-prefill-demo';

  AdminController get _ctrl => useContext<AdminController>(adminControllerKey);
  AdminNavigator get _nav => useContext<AdminNavigator>(adminNavigatorKey);

  @override
  void onMount() {
    listen(_ctrl.events, (e) {
      if (e.topic == AdminTopic.session || e.topic == AdminTopic.output)
        invalidate();
    });
    listen(root.onClick, _onClick);
  }

  @override
  web.Element render() {
    final disabledLogin = _ctrl.isDisabledFor(AdminActions.login);
    final disabledBootstrap = _ctrl.isDisabledFor(AdminActions.bootstrap);
    final disabledDemo = _ctrl.isDisabledFor(AdminActions.demoBootstrapLogin);

    return dom.section(
      title: 'Login',
      subtitle: 'Global login (cookie session).',
      children: [
        dom.spacer(),
        dom.row(children: [
          dom.inputText(
              id: _AdminIds.email, className: 'input', placeholder: 'email'),
          _passwordInput(),
          dom.primaryButton(
            'Login',
            action: AdminActions.login,
            disabled: disabledLogin,
          ),
          dom.secondaryButton(
            'Prefill demo',
            action: _actionPrefillDemo,
            disabled: _ctrl.busy,
          ),
          dom.secondaryButton(
            'Demo bootstrap + login',
            action: AdminActions.demoBootstrapLogin,
            disabled: disabledDemo,
          ),
          dom.secondaryButton(
            'Bootstrap (first user)',
            action: AdminActions.bootstrap,
            disabled: disabledBootstrap,
          ),
        ]),
        dom.spacer(),
        dom.muted(
            'Tip: run `npm run dev:full` so `/api` proxy works with cookies.'),
        dom.spacer(),
        dom.section(
          title: 'Debug',
          subtitle: 'Last JSON response (useful when debugging auth/CSRF).',
          children: [
            dom.spacer(),
            _pre(_ctrl.lastJson),
          ],
        ),
      ],
    );
  }

  web.Element _passwordInput() {
    final el = web.HTMLInputElement()
      ..id = _AdminIds.password
      ..className = 'input'
      ..type = 'password'
      ..placeholder = 'password';
    return el;
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      AdminActions.login: (_) async {
        await _ctrl.login(
          email: _value(this, _AdminIds.email),
          password: _value(this, _AdminIds.password),
        );
        if (_ctrl.isAuthenticated) {
          await _ctrl.loadTenants();
          _nav.go('tenants');
        }
      },
      _actionPrefillDemo: (_) {
        final email = query<web.HTMLInputElement>('#${_AdminIds.email}');
        final password = query<web.HTMLInputElement>('#${_AdminIds.password}');
        if (email != null) email.value = _demoEmail;
        if (password != null) password.value = _demoPassword;
      },
      AdminActions.demoBootstrapLogin: (_) async {
        final email = query<web.HTMLInputElement>('#${_AdminIds.email}');
        final password = query<web.HTMLInputElement>('#${_AdminIds.password}');
        if (email != null) email.value = _demoEmail;
        if (password != null) password.value = _demoPassword;

        await _ctrl.demoBootstrapAndLogin(
          email: _demoEmail,
          password: _demoPassword,
        );
        if (_ctrl.isAuthenticated) {
          await _ctrl.loadTenants();
          _nav.go('tenants');
        }
      },
      AdminActions.bootstrap: (_) async {
        await _ctrl.bootstrap(
          email: _value(this, _AdminIds.email),
          password: _value(this, _AdminIds.password),
        );
      },
    });
  }
}

final class AdminTenantsPage extends Component {
  AdminController get _ctrl => useContext<AdminController>(adminControllerKey);

  @override
  void onMount() {
    listen(_ctrl.events, (e) {
      if (e.topic == AdminTopic.tenants || e.topic == AdminTopic.session)
        invalidate();
    });
    listen(root.onClick, _onClick);

    if (_ctrl.isAuthenticated && _ctrl.tenants.isEmpty) {
      _ctrl.loadTenants();
    }
  }

  @override
  web.Element render() {
    final tenants = _ctrl.tenants;

    return dom.section(
      title: 'Tenants',
      subtitle: 'Your tenants (membership-based).',
      children: [
        dom.spacer(),
        dom.row(children: [
          dom.secondaryButton(
            'Refresh',
            action: AdminActions.listTenants,
            disabled: _ctrl.isDisabledFor(AdminActions.listTenants),
          ),
        ]),
        dom.spacer(),
        sui.Table(
          head: () => [
            sui.TableRow(
                children: () => [
                      sui.TableHeadCell(text: 'Name'),
                      sui.TableHeadCell(text: 'Slug'),
                      sui.TableHeadCell(text: 'Role'),
                      sui.TableHeadCell(text: 'Actions'),
                    ]),
          ],
          body: () => tenants.map((t) {
            final isActive = t.slug == _ctrl.activeTenantSlug;
            return sui.TableRow(
                children: () => [
                      sui.TableCell(text: t.name),
                      sui.TableCell(text: t.slug),
                      sui.TableCell(
                          text: t.role + (isActive ? ' (active)' : '')),
                      _actionCell([
                        dom.secondaryButton(
                          isActive ? 'Selected' : 'Select',
                          action: AdminActions.selectTenant,
                          dataId: _hashId(t.slug),
                          disabled: isActive ||
                              _ctrl.isDisabledFor(AdminActions.selectTenant),
                        ),
                      ]),
                    ]);
          }),
        ),
        dom.spacer(),
        dom.section(
          title: 'Create tenant',
          subtitle: 'Creates a new tenant and makes you the owner.',
          children: [
            dom.spacer(),
            dom.row(children: [
              dom.inputText(
                id: _AdminIds.tenantSlug,
                className: 'input',
                placeholder: 'slug',
              ),
              dom.inputText(
                id: _AdminIds.tenantName,
                className: 'input',
                placeholder: 'name',
              ),
              dom.inputText(
                id: _AdminIds.tenantSignupMode,
                className: 'input',
                placeholder: 'signup mode (invite_only/public/disabled)',
              ),
              dom.primaryButton(
                'Create',
                action: AdminActions.createTenant,
                disabled: _ctrl.isDisabledFor(AdminActions.createTenant),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  web.Element _actionCell(List<web.Node> children) {
    final td = web.document.createElement('td') as web.HTMLTableCellElement
      ..className = 'td';
    td.append(dom.row(children: children));
    return td;
  }

  int _hashId(String slug) => slug.codeUnits.fold(0, (a, b) => a + b);

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      AdminActions.listTenants: (_) => _ctrl.loadTenants(),
      AdminActions.createTenant: (_) {
        final mode = _value(this, _AdminIds.tenantSignupMode);
        _ctrl.createTenant(
          slug: _value(this, _AdminIds.tenantSlug),
          name: _value(this, _AdminIds.tenantName),
          signupMode: mode.isEmpty ? 'invite_only' : mode,
        );
      },
      AdminActions.selectTenant: (el) {
        // Use the button's closest row to find the slug text cell.
        final row = el?.closest('tr');
        final slugCell =
            row?.querySelector('td:nth-child(2)') as web.HTMLElement?;
        final slug = slugCell?.textContent?.trim() ?? '';
        if (slug.isEmpty) return;
        router.setQueryParam('t', slug, replace: false);
        _ctrl.selectTenant(slug: slug);
      },
    });
  }
}

final class AdminMembersPage extends Component {
  AdminController get _ctrl => useContext<AdminController>(adminControllerKey);

  @override
  void onMount() {
    listen(_ctrl.events, (e) {
      if (e.topic == AdminTopic.members || e.topic == AdminTopic.session)
        invalidate();
    });
    listen(root.onClick, _onClick);
    listen(root.onChange, _onChange);

    if (_ctrl.isAuthenticated) {
      _ctrl.loadMembers();
    }
  }

  @override
  web.Element render() {
    final slug = _ctrl.activeTenantSlug;
    if (slug == null || slug.isEmpty) {
      return dom.section(
        title: 'Members',
        subtitle: 'Select a tenant first.',
        children: const [],
      );
    }

    final members = _ctrl.members;
    return dom.section(
      title: 'Members',
      subtitle: 'Tenant: $slug',
      children: [
        dom.spacer(),
        dom.row(children: [
          dom.secondaryButton(
            'Refresh',
            action: AdminActions.listMembers,
            disabled: _ctrl.isDisabledFor(AdminActions.listMembers),
          ),
        ]),
        dom.spacer(),
        sui.Table(
          head: () => [
            sui.TableRow(
                children: () => [
                      sui.TableHeadCell(text: 'Email'),
                      sui.TableHeadCell(text: 'Role'),
                      sui.TableHeadCell(text: 'Actions'),
                    ]),
          ],
          body: () => members.map((m) {
            return sui.TableRow(
                children: () => [
                      sui.TableCell(text: m.email),
                      _roleSelectCell(m.userId, m.role),
                      _actionCell([
                        dom.secondaryButton(
                          'Save role',
                          action: AdminActions.changeMemberRole,
                          dataId: _hashId(m.userId),
                          disabled: _ctrl
                              .isDisabledFor(AdminActions.changeMemberRole),
                        ),
                        dom.dangerButton(
                          'Remove',
                          action: AdminActions.removeMember,
                          dataId: _hashId(m.userId),
                          disabled:
                              _ctrl.isDisabledFor(AdminActions.removeMember),
                        ),
                      ]),
                    ]);
          }),
        ),
      ],
    );
  }

  int _hashId(String id) =>
      id.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff);

  web.Element _actionCell(List<web.Node> children) {
    final td = web.document.createElement('td') as web.HTMLTableCellElement
      ..className = 'td';
    td.append(dom.row(children: children));
    return td;
  }

  web.Element _roleSelectCell(String userId, String role) {
    final td = web.document.createElement('td') as web.HTMLTableCellElement
      ..className = 'td';
    final select = web.HTMLSelectElement()
      ..className = 'input'
      ..setAttribute('data-user-id', userId)
      ..setAttribute('data-kind', 'role');

    for (final r in const ['member', 'admin', 'owner']) {
      final opt = web.HTMLOptionElement()
        ..value = r
        ..textContent = r;
      if (r == role) opt.selected = true;
      select.appendChild(opt);
    }
    td.appendChild(select);
    return td;
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      AdminActions.listMembers: (_) => _ctrl.loadMembers(),
      AdminActions.changeMemberRole: (el) {
        final row = el?.closest('tr');
        final select = row?.querySelector('select[data-kind=\"role\"]')
            as web.HTMLSelectElement?;
        final userId = select?.getAttribute('data-user-id') ?? '';
        final role = select?.value.trim() ?? '';
        if (userId.isEmpty || role.isEmpty) return;
        _ctrl.changeMemberRole(userId: userId, role: role);
      },
      AdminActions.removeMember: (el) {
        final row = el?.closest('tr');
        final select = row?.querySelector('select[data-kind=\"role\"]')
            as web.HTMLSelectElement?;
        final userId = select?.getAttribute('data-user-id') ?? '';
        if (userId.isEmpty) return;
        final ok = web.window.confirm('Remove this member?');
        if (!ok) return;
        _ctrl.removeMember(userId: userId);
      },
    });
  }

  void _onChange(web.Event event) {
    // no-op for now (kept for future inline autosave)
  }
}

final class AdminInvitesPage extends Component {
  AdminController get _ctrl => useContext<AdminController>(adminControllerKey);

  @override
  void onMount() {
    listen(_ctrl.events, (e) {
      if (e.topic == AdminTopic.invites || e.topic == AdminTopic.session)
        invalidate();
    });
    listen(root.onClick, _onClick);

    if (_ctrl.isAuthenticated) {
      _ctrl.loadInvites();
    }
  }

  @override
  web.Element render() {
    final slug = _ctrl.activeTenantSlug;
    if (slug == null || slug.isEmpty) {
      return dom.section(
        title: 'Invites',
        subtitle: 'Select a tenant first.',
        children: const [],
      );
    }

    final invites = _ctrl.invites;
    return dom.section(
      title: 'Invites',
      subtitle: 'Tenant: $slug',
      children: [
        dom.spacer(),
        dom.row(children: [
          dom.secondaryButton(
            'Refresh',
            action: AdminActions.listInvites,
            disabled: _ctrl.isDisabledFor(AdminActions.listInvites),
          ),
        ]),
        dom.spacer(),
        dom.section(
          title: 'Create invite',
          subtitle: 'Sends an invite email (dev token is shown when enabled).',
          children: [
            dom.spacer(),
            dom.row(children: [
              dom.inputText(
                id: _AdminIds.inviteEmail,
                className: 'input',
                placeholder: 'email',
              ),
              dom.inputText(
                id: _AdminIds.inviteRole,
                className: 'input',
                placeholder: 'role (member/admin/owner)',
              ),
              dom.primaryButton(
                'Create',
                action: AdminActions.createInvite,
                disabled: _ctrl.isDisabledFor(AdminActions.createInvite),
              ),
            ]),
          ],
        ),
        dom.spacer(),
        sui.Table(
          head: () => [
            sui.TableRow(
                children: () => [
                      sui.TableHeadCell(text: 'Email'),
                      sui.TableHeadCell(text: 'Role'),
                      sui.TableHeadCell(text: 'Expires'),
                      sui.TableHeadCell(text: 'Status'),
                      sui.TableHeadCell(text: 'Actions'),
                    ]),
          ],
          body: () => invites.map((i) {
            final status = i.acceptedAt != null
                ? 'accepted'
                : (i.expiresAt != null &&
                        i.expiresAt!.isBefore(DateTime.now().toUtc()))
                    ? 'expired'
                    : 'pending';

            return sui.TableRow(
                children: () => [
                      sui.TableCell(text: i.email),
                      sui.TableCell(text: i.role),
                      sui.TableCell(text: i.expiresAt?.toIso8601String() ?? ''),
                      sui.TableCell(text: status),
                      _actionCell([
                        dom.dangerButton(
                          'Revoke',
                          action: AdminActions.revokeInvite,
                          dataId: _hashId(i.id),
                          disabled: status != 'pending' ||
                              _ctrl.isDisabledFor(AdminActions.revokeInvite),
                        ),
                      ], dataInviteId: i.id),
                    ]);
          }),
        ),
      ],
    );
  }

  int _hashId(String id) =>
      id.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff);

  web.Element _actionCell(List<web.Node> children,
      {required String dataInviteId}) {
    final td = web.document.createElement('td') as web.HTMLTableCellElement
      ..className = 'td';
    td.setAttribute('data-invite-id', dataInviteId);
    td.append(dom.row(children: children));
    return td;
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      AdminActions.listInvites: (_) => _ctrl.loadInvites(),
      AdminActions.createInvite: (_) {
        final role = _value(this, _AdminIds.inviteRole);
        _ctrl.createInvite(
          email: _value(this, _AdminIds.inviteEmail),
          role: role.isEmpty ? 'member' : role,
        );
      },
      AdminActions.revokeInvite: (el) {
        final td = el?.closest('td');
        final id = td?.getAttribute('data-invite-id') ?? '';
        if (id.isEmpty) return;
        final ok = web.window.confirm('Revoke this invite?');
        if (!ok) return;
        _ctrl.revokeInvite(inviteId: id);
      },
    });
  }
}

final class AdminOutboxPage extends Component {
  AdminController get _ctrl => useContext<AdminController>(adminControllerKey);

  @override
  void onMount() {
    listen(_ctrl.events, (e) {
      if (e.topic == AdminTopic.outbox || e.topic == AdminTopic.output)
        invalidate();
    });
    listen(root.onClick, _onClick);
    listen(root.onChange, _onChange);

    if (_ctrl.isAuthenticated) {
      _ctrl.loadOutbox();
    }
  }

  @override
  web.Element render() {
    final emails = _ctrl.outbox;

    return dom.section(
      title: 'Email outbox (dev)',
      subtitle:
          'Requires SOLIDUS_EXPOSE_DEV_TOKENS=1. Shows queued/sent/failed emails.',
      children: [
        dom.spacer(),
        dom.row(children: [
          _statusSelect(),
          dom.secondaryButton(
            'Refresh',
            action: AdminActions.listOutbox,
            disabled: _ctrl.isDisabledFor(AdminActions.listOutbox),
          ),
        ]),
        dom.spacer(),
        sui.Table(
          head: () => [
            sui.TableRow(
                children: () => [
                      sui.TableHeadCell(text: 'To'),
                      sui.TableHeadCell(text: 'Subject'),
                      sui.TableHeadCell(text: 'Status'),
                      sui.TableHeadCell(text: 'Attempts'),
                      sui.TableHeadCell(text: 'Actions'),
                    ]),
          ],
          body: () => emails.map((e) {
            return sui.TableRow(
                children: () => [
                      sui.TableCell(text: e.to),
                      sui.TableCell(text: e.subject),
                      sui.TableCell(text: e.status),
                      sui.TableCell(text: '${e.attempts}'),
                      _outboxActionsCell(e.id, e.status),
                    ]);
          }),
        ),
        dom.spacer(),
        dom.section(
          title: 'Debug',
          subtitle: 'Last JSON response.',
          children: [
            dom.spacer(),
            _pre(_ctrl.lastJson),
          ],
        ),
      ],
    );
  }

  web.Element _statusSelect() {
    final select = web.HTMLSelectElement()
      ..id = _AdminIds.outboxStatus
      ..className = 'input';

    for (final v in const ['', 'pending', 'failed', 'sent']) {
      final opt = web.HTMLOptionElement()
        ..value = v
        ..textContent = v.isEmpty ? 'All statuses' : v;
      select.appendChild(opt);
    }
    return select;
  }

  web.Element _outboxActionsCell(String emailId, String status) {
    final td = web.document.createElement('td') as web.HTMLTableCellElement
      ..className = 'td'
      ..setAttribute('data-email-id', emailId);

    td.append(dom.row(children: [
      dom.secondaryButton(
        'View',
        action: AdminActions.getOutboxEmail,
        disabled: _ctrl.isDisabledFor(AdminActions.getOutboxEmail),
      ),
      dom.secondaryButton(
        'Retry',
        action: AdminActions.retryOutboxEmail,
        disabled: status == 'sent' ||
            _ctrl.isDisabledFor(AdminActions.retryOutboxEmail),
      ),
    ]));
    return td;
  }

  void _onClick(web.MouseEvent event) {
    dispatchAction(event, {
      AdminActions.listOutbox: (_) {
        final status = _value(this, _AdminIds.outboxStatus);
        _ctrl.loadOutbox(status: status);
      },
      AdminActions.retryOutboxEmail: (el) {
        final td = el?.closest('td');
        final id = td?.getAttribute('data-email-id') ?? '';
        if (id.isEmpty) return;
        _ctrl.retryOutboxEmail(id);
      },
      AdminActions.getOutboxEmail: (el) async {
        final td = el?.closest('td');
        final id = td?.getAttribute('data-email-id') ?? '';
        if (id.isEmpty) return;
        final detail = await _ctrl.getOutboxEmail(id);
        if (detail == null) return;
        final json = jsonEncode({
          'to': detail.email.to,
          'from': detail.email.from,
          'subject': detail.email.subject,
          'status': detail.email.status,
          'attempts': detail.email.attempts,
          'lastError': detail.email.lastError,
          'textBody': detail.textBody,
          'htmlBody': detail.htmlBody,
        });
        web.window.alert(json);
      },
    });
  }

  void _onChange(web.Event event) {
    // no-op: user clicks Refresh.
  }
}

import 'dart:async';
import 'dart:convert';

import '../backend_api.dart';

const String adminControllerKey = 'admin.controller';

enum AdminTopic {
  session,
  tenants,
  members,
  invites,
  outbox,
  output,
}

final class AdminEvent {
  AdminEvent(this.topic);
  final AdminTopic topic;
}

final class AdminMe {
  AdminMe({
    required this.userId,
    required this.email,
    required this.emailVerifiedAt,
    required this.sessionId,
    required this.mfaVerified,
    required this.activeTenantId,
    required this.csrfToken,
  });

  final String userId;
  final String email;
  final DateTime? emailVerifiedAt;
  final String sessionId;
  final bool mfaVerified;
  final String? activeTenantId;
  final String csrfToken;

  static AdminMe fromMeResponse(Map<String, Object?> json) {
    final user = (json['user'] as Map?)?.cast<String, Object?>() ?? const {};
    final session =
        (json['session'] as Map?)?.cast<String, Object?>() ?? const {};
    final csrfToken = (json['csrfToken'] as String?) ?? '';
    return AdminMe(
      userId: (user['id'] as String?) ?? '',
      email: (user['email'] as String?) ?? '',
      emailVerifiedAt: _parseDate(user['emailVerifiedAt']),
      sessionId: (session['id'] as String?) ?? '',
      mfaVerified: (session['mfaVerified'] as bool?) ?? false,
      activeTenantId: session['activeTenantId'] as String?,
      csrfToken: csrfToken,
    );
  }
}

final class AdminTenant {
  AdminTenant({
    required this.id,
    required this.slug,
    required this.name,
    required this.role,
  });

  final String id;
  final String slug;
  final String name;
  final String role;

  static AdminTenant fromJson(Map<String, Object?> json) {
    return AdminTenant(
      id: (json['id'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
    );
  }
}

final class AdminMember {
  AdminMember({required this.userId, required this.email, required this.role});
  final String userId;
  final String email;
  final String role;

  static AdminMember fromJson(Map<String, Object?> json) {
    return AdminMember(
      userId: (json['userId'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
    );
  }
}

final class AdminInvite {
  AdminInvite({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
    required this.acceptedAt,
  });

  final String id;
  final String email;
  final String role;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;

  static AdminInvite fromJson(Map<String, Object?> json) {
    return AdminInvite(
      id: (json['id'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      createdAt: _parseDate(json['createdAt']),
      expiresAt: _parseDate(json['expiresAt']),
      acceptedAt: _parseDate(json['acceptedAt']),
    );
  }
}

final class AdminOutboxEmail {
  AdminOutboxEmail({
    required this.id,
    required this.to,
    required this.from,
    required this.subject,
    required this.status,
    required this.attempts,
    required this.nextAttemptAt,
    required this.sentAt,
    required this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String to;
  final String from;
  final String subject;
  final String status;
  final int attempts;
  final DateTime? nextAttemptAt;
  final DateTime? sentAt;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static AdminOutboxEmail fromJson(Map<String, Object?> json) {
    return AdminOutboxEmail(
      id: (json['id'] as String?) ?? '',
      to: (json['to'] as String?) ?? '',
      from: (json['from'] as String?) ?? '',
      subject: (json['subject'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      attempts: (json['attempts'] as int?) ?? 0,
      nextAttemptAt: _parseDate(json['nextAttemptAt']),
      sentAt: _parseDate(json['sentAt']),
      lastError: json['lastError'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

final class AdminOutboxEmailDetail {
  AdminOutboxEmailDetail({
    required this.email,
    required this.textBody,
    required this.htmlBody,
  });

  final AdminOutboxEmail email;
  final String textBody;
  final String? htmlBody;
}

final class AdminController {
  AdminController({String baseUrl = '/api'})
      : api = SolidusBackendApi(baseUrl: baseUrl);

  final SolidusBackendApi api;

  final StreamController<AdminEvent> _events =
      StreamController<AdminEvent>.broadcast(sync: true);

  Stream<AdminEvent> get events => _events.stream;

  bool get busy => _busy;
  String? get busyAction => _busyAction;

  AdminMe? get me => _me;
  bool get isAuthenticated => _me != null;
  String? get csrfToken => _csrfToken;
  String? get activeTenantSlug => _activeTenantSlug;

  List<AdminTenant> get tenants => List.unmodifiable(_tenants);
  List<AdminMember> get members => List.unmodifiable(_members);
  List<AdminInvite> get invites => List.unmodifiable(_invites);
  List<AdminOutboxEmail> get outbox => List.unmodifiable(_outbox);

  String get status => _status;
  String get lastJson => _lastJson;

  bool _busy = false;
  String? _busyAction;

  AdminMe? _me;
  String? _csrfToken;
  String? _activeTenantSlug;

  final List<AdminTenant> _tenants = <AdminTenant>[];
  final List<AdminMember> _members = <AdminMember>[];
  final List<AdminInvite> _invites = <AdminInvite>[];
  final List<AdminOutboxEmail> _outbox = <AdminOutboxEmail>[];

  String _status = 'Ready.';
  String _lastJson = 'No requests yet.';

  void dispose() {
    api.close();
    _events.close();
  }

  void _emit(AdminTopic topic) {
    if (_events.isClosed) return;
    _events.add(AdminEvent(topic));
  }

  void _setStatus(String value) {
    _status = value;
    _emit(AdminTopic.output);
  }

  void _setLastJson(Object? obj) {
    _lastJson = const JsonEncoder.withIndent('  ').convert(obj);
    _emit(AdminTopic.output);
  }

  bool isDisabledFor(String actionName) => _busy && _busyAction == actionName;

  Future<T?> _run<T>({
    required AdminTopic topic,
    required String actionName,
    required Future<T> Function() action,
  }) async {
    if (_busy) return null;
    _busy = true;
    _busyAction = actionName;
    _emit(topic);
    _setStatus('Working…');

    try {
      api.csrfToken = _csrfToken;
      return await action();
    } on BackendApiException catch (e) {
      final statusCode = e.statusCode;
      final body = e.body ?? '';

      var message = e.toString();
      if (statusCode == 404 &&
          (body.contains('Not Found') ||
              body.toLowerCase().contains('not found'))) {
        if (actionName.startsWith('admin-outbox')) {
          message =
              'HTTP 404: outbox endpoints disabled (run via `npm run dev:full` or set `SOLIDUS_EXPOSE_DEV_TOKENS=1`).';
        } else {
          message =
              'HTTP 404: endpoint not found (restart backend / ensure you pulled latest).';
        }
      }

      _setStatus('Error: $message');
      _setLastJson(
          {'error': e.toString(), 'statusCode': e.statusCode, 'body': e.body});
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

  Future<void> refreshSession() async {
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.session,
      actionName: AdminActions.refreshMe,
      action: () => api.getJson('/me'),
    );
    if (res == null) return;
    final me = AdminMe.fromMeResponse(res);
    _me = me;
    _csrfToken = me.csrfToken.isEmpty ? null : me.csrfToken;
    api.csrfToken = _csrfToken;
    _emit(AdminTopic.session);
    _emit(AdminTopic.output);
    _setLastJson(res);
    _setStatus('Fetched /me.');
  }

  Future<void> login({required String email, required String password}) async {
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.session,
      actionName: AdminActions.login,
      action: () =>
          api.postJson('/login', {'email': email, 'password': password}),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Logged in.');
    await refreshSession();
  }

  Future<void> bootstrap(
      {required String email, required String password}) async {
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.session,
      actionName: AdminActions.bootstrap,
      action: () =>
          api.postJson('/bootstrap', {'email': email, 'password': password}),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Bootstrapped.');
  }

  Future<void> logout() async {
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.session,
      actionName: AdminActions.logout,
      action: () => api.postJson('/logout', {}, csrf: false),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Logged out.');
    _me = null;
    _csrfToken = null;
    _activeTenantSlug = null;
    _tenants.clear();
    _members.clear();
    _invites.clear();
    _outbox.clear();
    _emit(AdminTopic.session);
    _emit(AdminTopic.tenants);
    _emit(AdminTopic.members);
    _emit(AdminTopic.invites);
    _emit(AdminTopic.outbox);
  }

  Future<void> loadTenants() async {
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.tenants,
      actionName: AdminActions.listTenants,
      action: () => api.getJson('/tenants'),
    );
    if (res == null) return;
    final list = (res['tenants'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, Object?>())
            .map(AdminTenant.fromJson)
            .toList(growable: false) ??
        const <AdminTenant>[];
    _tenants
      ..clear()
      ..addAll(list);
    _emit(AdminTopic.tenants);
    _setLastJson(res);
    _setStatus('Fetched /tenants.');

    final activeId = _me?.activeTenantId;
    if (_activeTenantSlug == null && activeId != null) {
      final match = _tenants.where((t) => t.id == activeId).toList();
      if (match.isNotEmpty) {
        _activeTenantSlug = match.first.slug;
        _emit(AdminTopic.session);
      }
    }
  }

  Future<void> createTenant({
    required String slug,
    required String name,
    required String signupMode,
  }) async {
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.tenants,
      actionName: AdminActions.createTenant,
      action: () => api.postJson(
        '/tenants',
        {'slug': slug, 'name': name, 'signupMode': signupMode},
        csrf: true,
      ),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Tenant created.');
    await loadTenants();
  }

  Future<void> selectTenant({required String slug}) async {
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.tenants,
      actionName: AdminActions.selectTenant,
      action: () => api.postJson('/tenants/select', {'slug': slug}, csrf: true),
    );
    if (res == null) return;
    _activeTenantSlug = slug;
    _emit(AdminTopic.session);
    _emit(AdminTopic.tenants);
    _setLastJson(res);
    _setStatus('Selected tenant.');
  }

  Future<void> loadMembers() async {
    final slug = _activeTenantSlug;
    if (slug == null || slug.isEmpty) {
      _members.clear();
      _emit(AdminTopic.members);
      _setStatus('Select a tenant first.');
      return;
    }
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.members,
      actionName: AdminActions.listMembers,
      action: () => api.getJson('/t/$slug/admin/members'),
    );
    if (res == null) return;
    final list = (res['members'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, Object?>())
            .map(AdminMember.fromJson)
            .toList(growable: false) ??
        const <AdminMember>[];
    _members
      ..clear()
      ..addAll(list);
    _emit(AdminTopic.members);
    _setLastJson(res);
    _setStatus('Fetched members.');
  }

  Future<void> changeMemberRole({
    required String userId,
    required String role,
  }) async {
    final slug = _activeTenantSlug;
    if (slug == null || slug.isEmpty) return;
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.members,
      actionName: AdminActions.changeMemberRole,
      action: () => api.postJson(
        '/t/$slug/admin/members/$userId/role',
        {'role': role},
        csrf: true,
      ),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Role updated.');
    await loadMembers();
  }

  Future<void> removeMember({required String userId}) async {
    final slug = _activeTenantSlug;
    if (slug == null || slug.isEmpty) return;
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.members,
      actionName: AdminActions.removeMember,
      action: () => api.postJson(
        '/t/$slug/admin/members/$userId/remove',
        const {},
        csrf: true,
      ),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Member removed.');
    await loadMembers();
    await loadTenants();
  }

  Future<void> loadInvites() async {
    final slug = _activeTenantSlug;
    if (slug == null || slug.isEmpty) {
      _invites.clear();
      _emit(AdminTopic.invites);
      _setStatus('Select a tenant first.');
      return;
    }
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.invites,
      actionName: AdminActions.listInvites,
      action: () => api.getJson('/t/$slug/admin/invites'),
    );
    if (res == null) return;
    final list = (res['invites'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, Object?>())
            .map(AdminInvite.fromJson)
            .toList(growable: false) ??
        const <AdminInvite>[];
    _invites
      ..clear()
      ..addAll(list);
    _emit(AdminTopic.invites);
    _setLastJson(res);
    _setStatus('Fetched invites.');
  }

  Future<void> createInvite({
    required String email,
    required String role,
  }) async {
    final slug = _activeTenantSlug;
    if (slug == null || slug.isEmpty) return;
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.invites,
      actionName: AdminActions.createInvite,
      action: () => api.postJson(
        '/t/$slug/admin/invites',
        {'email': email, 'role': role},
        csrf: true,
      ),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Invite created.');
    await loadInvites();
  }

  Future<void> revokeInvite({required String inviteId}) async {
    final slug = _activeTenantSlug;
    if (slug == null || slug.isEmpty) return;
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.invites,
      actionName: AdminActions.revokeInvite,
      action: () => api.postJson(
        '/t/$slug/admin/invites/$inviteId/revoke',
        const {},
        csrf: true,
      ),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Invite revoked.');
    await loadInvites();
  }

  Future<void> loadOutbox({String status = ''}) async {
    final qp = status.trim().isEmpty
        ? ''
        : '?status=${Uri.encodeQueryComponent(status.trim())}';
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.outbox,
      actionName: AdminActions.listOutbox,
      action: () => api.getJson('/admin/email/outbox$qp'),
    );
    if (res == null) return;
    final list = (res['emails'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, Object?>())
            .map(AdminOutboxEmail.fromJson)
            .toList(growable: false) ??
        const <AdminOutboxEmail>[];
    _outbox
      ..clear()
      ..addAll(list);
    _emit(AdminTopic.outbox);
    _setLastJson(res);
    _setStatus('Fetched outbox.');
  }

  Future<AdminOutboxEmailDetail?> getOutboxEmail(String id) async {
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.outbox,
      actionName: AdminActions.getOutboxEmail,
      action: () => api.getJson('/admin/email/outbox/$id'),
    );
    if (res == null) return null;
    final emailJson =
        (res['email'] as Map?)?.cast<String, Object?>() ?? const {};
    final email = AdminOutboxEmail.fromJson(emailJson);
    _setLastJson(res);
    _setStatus('Fetched email.');
    return AdminOutboxEmailDetail(
      email: email,
      textBody: (emailJson['textBody'] as String?) ?? '',
      htmlBody: emailJson['htmlBody'] as String?,
    );
  }

  Future<void> retryOutboxEmail(String id) async {
    final res = await _run<Map<String, Object?>>(
      topic: AdminTopic.outbox,
      actionName: AdminActions.retryOutboxEmail,
      action: () =>
          api.postJson('/admin/email/outbox/$id/retry', const {}, csrf: true),
    );
    if (res == null) return;
    _setLastJson(res);
    _setStatus('Queued retry.');
    await loadOutbox();
  }
}

abstract final class AdminActions {
  static const refreshMe = 'admin-refresh-me';
  static const login = 'admin-login';
  static const bootstrap = 'admin-bootstrap';
  static const logout = 'admin-logout';

  static const listTenants = 'admin-tenants';
  static const createTenant = 'admin-tenant-create';
  static const selectTenant = 'admin-tenant-select';

  static const listMembers = 'admin-members';
  static const changeMemberRole = 'admin-member-role';
  static const removeMember = 'admin-member-remove';

  static const listInvites = 'admin-invites';
  static const createInvite = 'admin-invite-create';
  static const revokeInvite = 'admin-invite-revoke';

  static const listOutbox = 'admin-outbox';
  static const getOutboxEmail = 'admin-outbox-get';
  static const retryOutboxEmail = 'admin-outbox-retry';
}

DateTime? _parseDate(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

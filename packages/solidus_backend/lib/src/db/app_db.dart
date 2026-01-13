import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables.dart';

part 'app_db.g.dart';

@DriftDatabase(
  tables: [
    Tenants,
    TenantSettings,
    Users,
    Memberships,
    Sessions,
    TotpCredentials,
    RecoveryCodes,
    Invites,
    AuditLogs,
    PasswordResetTokens,
    EmailVerificationTokens,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({
    required String sqliteFilePath,
    bool logStatements = false,
  }) : super(_openConnection(sqliteFilePath, logStatements: logStatements));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(tenantSettings, tenantSettings.requireMfaForAdmins);
            await migrator.createTable(auditLogs);
          }
          if (from < 3) {
            await migrator.createTable(passwordResetTokens);
            await migrator.createTable(emailVerificationTokens);
          }
        },
        beforeOpen: (details) async {
          if (details.wasCreated) {
            // nothing
          }
        },
      );

  Future<Tenant> getTenantBySlug(String slug) {
    return (select(tenants)..where((t) => t.slug.equals(slug))).getSingle();
  }

  Future<Tenant?> maybeGetTenantBySlug(String slug) {
    return (select(tenants)..where((t) => t.slug.equals(slug))).getSingleOrNull();
  }

  Future<TenantSetting?> getTenantSettings(String tenantId) {
    return (select(tenantSettings)..where((s) => s.tenantId.equals(tenantId)))
        .getSingleOrNull();
  }

  Future<User?> getUserByEmail(String emailLower) {
    return (select(users)..where((u) => u.email.equals(emailLower)))
        .getSingleOrNull();
  }

  Future<User> getUserById(String id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingle();
  }

  Future<Membership?> getMembership({
    required String tenantId,
    required String userId,
  }) {
    return (select(memberships)
          ..where((m) => m.tenantId.equals(tenantId) & m.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<Session?> getSessionById(String sessionId) {
    return (select(sessions)..where((s) => s.id.equals(sessionId)))
        .getSingleOrNull();
  }

  Future<void> deleteSession(String sessionId) async {
    await (delete(sessions)..where((s) => s.id.equals(sessionId))).go();
  }
}

LazyDatabase _openConnection(String sqliteFilePath, {required bool logStatements}) {
  return LazyDatabase(() async {
    final file = File(sqliteFilePath);
    await file.parent.create(recursive: true);
    return NativeDatabase.createInBackground(file, logStatements: logStatements);
  });
}

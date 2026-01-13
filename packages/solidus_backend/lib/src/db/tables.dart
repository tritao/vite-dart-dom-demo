import 'package:drift/drift.dart';

class Tenants extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {slug},
      ];
}

class TenantSettings extends Table {
  TextColumn get tenantId => text()();
  TextColumn get signupMode => text()(); // public|invite_only|disabled
  BoolColumn get requireMfaForAdmins =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId};
}

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()(); // lowercased
  TextColumn get passwordHash => text()();
  DateTimeColumn get emailVerifiedAt => dateTime().nullable()();
  DateTimeColumn get disabledAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {email},
      ];
}

class Memberships extends Table {
  TextColumn get tenantId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()(); // owner|admin|member
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, userId};
}

class Sessions extends Table {
  TextColumn get id => text()(); // base64url random
  TextColumn get userId => text()();
  TextColumn get activeTenantId => text().nullable()();
  BoolColumn get mfaVerified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get recentAuthAt => dateTime().nullable()();
  TextColumn get csrfSecret => text()(); // base64url random

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  TextColumn get ip => text().nullable()();
  TextColumn get userAgent => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TotpCredentials extends Table {
  TextColumn get userId => text()();
  IntColumn get keyVersion => integer().withDefault(const Constant(1))();
  BlobColumn get secretNonce => blob()();
  BlobColumn get secretCiphertext => blob()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get enabledAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class RecoveryCodes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get codeHash => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get usedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Invites extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get email => text()(); // lowercased
  TextColumn get role => text()(); // owner|admin|member
  TextColumn get tokenHash => text()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get acceptedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().nullable()();
  TextColumn get actorUserId => text().nullable()();
  TextColumn get action => text()();
  TextColumn get target => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  TextColumn get ip => text().nullable()();
  TextColumn get userAgent => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PasswordResetTokens extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get tokenHash => text()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get usedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class EmailVerificationTokens extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get tokenHash => text()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get usedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

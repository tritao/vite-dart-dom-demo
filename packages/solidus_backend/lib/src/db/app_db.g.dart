// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $TenantsTable extends Tenants with TableInfo<$TenantsTable, Tenant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TenantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
      'slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, slug, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tenants';
  @override
  VerificationContext validateIntegrity(Insertable<Tenant> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
          _slugMeta, slug.isAcceptableOrUnknown(data['slug']!, _slugMeta));
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {slug},
      ];
  @override
  Tenant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tenant(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      slug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slug'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TenantsTable createAlias(String alias) {
    return $TenantsTable(attachedDatabase, alias);
  }
}

class Tenant extends DataClass implements Insertable<Tenant> {
  final String id;
  final String slug;
  final String name;
  final DateTime createdAt;
  const Tenant(
      {required this.id,
      required this.slug,
      required this.name,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slug'] = Variable<String>(slug);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TenantsCompanion toCompanion(bool nullToAbsent) {
    return TenantsCompanion(
      id: Value(id),
      slug: Value(slug),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory Tenant.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tenant(
      id: serializer.fromJson<String>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slug': serializer.toJson<String>(slug),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tenant copyWith(
          {String? id, String? slug, String? name, DateTime? createdAt}) =>
      Tenant(
        id: id ?? this.id,
        slug: slug ?? this.slug,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  Tenant copyWithCompanion(TenantsCompanion data) {
    return Tenant(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tenant(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, slug, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tenant &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class TenantsCompanion extends UpdateCompanion<Tenant> {
  final Value<String> id;
  final Value<String> slug;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TenantsCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TenantsCompanion.insert({
    required String id,
    required String slug,
    required String name,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        slug = Value(slug),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Tenant> custom({
    Expression<String>? id,
    Expression<String>? slug,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TenantsCompanion copyWith(
      {Value<String>? id,
      Value<String>? slug,
      Value<String>? name,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TenantsCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TenantsCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TenantSettingsTable extends TenantSettings
    with TableInfo<$TenantSettingsTable, TenantSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TenantSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _signupModeMeta =
      const VerificationMeta('signupMode');
  @override
  late final GeneratedColumn<String> signupMode = GeneratedColumn<String>(
      'signup_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requireMfaForAdminsMeta =
      const VerificationMeta('requireMfaForAdmins');
  @override
  late final GeneratedColumn<bool> requireMfaForAdmins = GeneratedColumn<bool>(
      'require_mfa_for_admins', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("require_mfa_for_admins" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [tenantId, signupMode, requireMfaForAdmins, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tenant_settings';
  @override
  VerificationContext validateIntegrity(Insertable<TenantSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('signup_mode')) {
      context.handle(
          _signupModeMeta,
          signupMode.isAcceptableOrUnknown(
              data['signup_mode']!, _signupModeMeta));
    } else if (isInserting) {
      context.missing(_signupModeMeta);
    }
    if (data.containsKey('require_mfa_for_admins')) {
      context.handle(
          _requireMfaForAdminsMeta,
          requireMfaForAdmins.isAcceptableOrUnknown(
              data['require_mfa_for_admins']!, _requireMfaForAdminsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId};
  @override
  TenantSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TenantSetting(
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      signupMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}signup_mode'])!,
      requireMfaForAdmins: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}require_mfa_for_admins'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TenantSettingsTable createAlias(String alias) {
    return $TenantSettingsTable(attachedDatabase, alias);
  }
}

class TenantSetting extends DataClass implements Insertable<TenantSetting> {
  final String tenantId;
  final String signupMode;
  final bool requireMfaForAdmins;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TenantSetting(
      {required this.tenantId,
      required this.signupMode,
      required this.requireMfaForAdmins,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['signup_mode'] = Variable<String>(signupMode);
    map['require_mfa_for_admins'] = Variable<bool>(requireMfaForAdmins);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TenantSettingsCompanion toCompanion(bool nullToAbsent) {
    return TenantSettingsCompanion(
      tenantId: Value(tenantId),
      signupMode: Value(signupMode),
      requireMfaForAdmins: Value(requireMfaForAdmins),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TenantSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TenantSetting(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      signupMode: serializer.fromJson<String>(json['signupMode']),
      requireMfaForAdmins:
          serializer.fromJson<bool>(json['requireMfaForAdmins']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'signupMode': serializer.toJson<String>(signupMode),
      'requireMfaForAdmins': serializer.toJson<bool>(requireMfaForAdmins),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TenantSetting copyWith(
          {String? tenantId,
          String? signupMode,
          bool? requireMfaForAdmins,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      TenantSetting(
        tenantId: tenantId ?? this.tenantId,
        signupMode: signupMode ?? this.signupMode,
        requireMfaForAdmins: requireMfaForAdmins ?? this.requireMfaForAdmins,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TenantSetting copyWithCompanion(TenantSettingsCompanion data) {
    return TenantSetting(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      signupMode:
          data.signupMode.present ? data.signupMode.value : this.signupMode,
      requireMfaForAdmins: data.requireMfaForAdmins.present
          ? data.requireMfaForAdmins.value
          : this.requireMfaForAdmins,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TenantSetting(')
          ..write('tenantId: $tenantId, ')
          ..write('signupMode: $signupMode, ')
          ..write('requireMfaForAdmins: $requireMfaForAdmins, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      tenantId, signupMode, requireMfaForAdmins, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TenantSetting &&
          other.tenantId == this.tenantId &&
          other.signupMode == this.signupMode &&
          other.requireMfaForAdmins == this.requireMfaForAdmins &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TenantSettingsCompanion extends UpdateCompanion<TenantSetting> {
  final Value<String> tenantId;
  final Value<String> signupMode;
  final Value<bool> requireMfaForAdmins;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TenantSettingsCompanion({
    this.tenantId = const Value.absent(),
    this.signupMode = const Value.absent(),
    this.requireMfaForAdmins = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TenantSettingsCompanion.insert({
    required String tenantId,
    required String signupMode,
    this.requireMfaForAdmins = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : tenantId = Value(tenantId),
        signupMode = Value(signupMode),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<TenantSetting> custom({
    Expression<String>? tenantId,
    Expression<String>? signupMode,
    Expression<bool>? requireMfaForAdmins,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (signupMode != null) 'signup_mode': signupMode,
      if (requireMfaForAdmins != null)
        'require_mfa_for_admins': requireMfaForAdmins,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TenantSettingsCompanion copyWith(
      {Value<String>? tenantId,
      Value<String>? signupMode,
      Value<bool>? requireMfaForAdmins,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TenantSettingsCompanion(
      tenantId: tenantId ?? this.tenantId,
      signupMode: signupMode ?? this.signupMode,
      requireMfaForAdmins: requireMfaForAdmins ?? this.requireMfaForAdmins,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (signupMode.present) {
      map['signup_mode'] = Variable<String>(signupMode.value);
    }
    if (requireMfaForAdmins.present) {
      map['require_mfa_for_admins'] = Variable<bool>(requireMfaForAdmins.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TenantSettingsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('signupMode: $signupMode, ')
          ..write('requireMfaForAdmins: $requireMfaForAdmins, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passwordHashMeta =
      const VerificationMeta('passwordHash');
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
      'password_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailVerifiedAtMeta =
      const VerificationMeta('emailVerifiedAt');
  @override
  late final GeneratedColumn<DateTime> emailVerifiedAt =
      GeneratedColumn<DateTime>('email_verified_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _disabledAtMeta =
      const VerificationMeta('disabledAt');
  @override
  late final GeneratedColumn<DateTime> disabledAt = GeneratedColumn<DateTime>(
      'disabled_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, email, passwordHash, emailVerifiedAt, disabledAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
          _passwordHashMeta,
          passwordHash.isAcceptableOrUnknown(
              data['password_hash']!, _passwordHashMeta));
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('email_verified_at')) {
      context.handle(
          _emailVerifiedAtMeta,
          emailVerifiedAt.isAcceptableOrUnknown(
              data['email_verified_at']!, _emailVerifiedAtMeta));
    }
    if (data.containsKey('disabled_at')) {
      context.handle(
          _disabledAtMeta,
          disabledAt.isAcceptableOrUnknown(
              data['disabled_at']!, _disabledAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {email},
      ];
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      passwordHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_hash'])!,
      emailVerifiedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}email_verified_at']),
      disabledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}disabled_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String email;
  final String passwordHash;
  final DateTime? emailVerifiedAt;
  final DateTime? disabledAt;
  final DateTime createdAt;
  const User(
      {required this.id,
      required this.email,
      required this.passwordHash,
      this.emailVerifiedAt,
      this.disabledAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    if (!nullToAbsent || emailVerifiedAt != null) {
      map['email_verified_at'] = Variable<DateTime>(emailVerifiedAt);
    }
    if (!nullToAbsent || disabledAt != null) {
      map['disabled_at'] = Variable<DateTime>(disabledAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      email: Value(email),
      passwordHash: Value(passwordHash),
      emailVerifiedAt: emailVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(emailVerifiedAt),
      disabledAt: disabledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(disabledAt),
      createdAt: Value(createdAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      emailVerifiedAt: serializer.fromJson<DateTime?>(json['emailVerifiedAt']),
      disabledAt: serializer.fromJson<DateTime?>(json['disabledAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'emailVerifiedAt': serializer.toJson<DateTime?>(emailVerifiedAt),
      'disabledAt': serializer.toJson<DateTime?>(disabledAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  User copyWith(
          {String? id,
          String? email,
          String? passwordHash,
          Value<DateTime?> emailVerifiedAt = const Value.absent(),
          Value<DateTime?> disabledAt = const Value.absent(),
          DateTime? createdAt}) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        emailVerifiedAt: emailVerifiedAt.present
            ? emailVerifiedAt.value
            : this.emailVerifiedAt,
        disabledAt: disabledAt.present ? disabledAt.value : this.disabledAt,
        createdAt: createdAt ?? this.createdAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      emailVerifiedAt: data.emailVerifiedAt.present
          ? data.emailVerifiedAt.value
          : this.emailVerifiedAt,
      disabledAt:
          data.disabledAt.present ? data.disabledAt.value : this.disabledAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('emailVerifiedAt: $emailVerifiedAt, ')
          ..write('disabledAt: $disabledAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, email, passwordHash, emailVerifiedAt, disabledAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.emailVerifiedAt == this.emailVerifiedAt &&
          other.disabledAt == this.disabledAt &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<DateTime?> emailVerifiedAt;
  final Value<DateTime?> disabledAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.emailVerifiedAt = const Value.absent(),
    this.disabledAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String email,
    required String passwordHash,
    this.emailVerifiedAt = const Value.absent(),
    this.disabledAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        email = Value(email),
        passwordHash = Value(passwordHash),
        createdAt = Value(createdAt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<DateTime>? emailVerifiedAt,
    Expression<DateTime>? disabledAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (emailVerifiedAt != null) 'email_verified_at': emailVerifiedAt,
      if (disabledAt != null) 'disabled_at': disabledAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? email,
      Value<String>? passwordHash,
      Value<DateTime?>? emailVerifiedAt,
      Value<DateTime?>? disabledAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      disabledAt: disabledAt ?? this.disabledAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (emailVerifiedAt.present) {
      map['email_verified_at'] = Variable<DateTime>(emailVerifiedAt.value);
    }
    if (disabledAt.present) {
      map['disabled_at'] = Variable<DateTime>(disabledAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('emailVerifiedAt: $emailVerifiedAt, ')
          ..write('disabledAt: $disabledAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembershipsTable extends Memberships
    with TableInfo<$MembershipsTable, Membership> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembershipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [tenantId, userId, role, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memberships';
  @override
  VerificationContext validateIntegrity(Insertable<Membership> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, userId};
  @override
  Membership map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Membership(
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MembershipsTable createAlias(String alias) {
    return $MembershipsTable(attachedDatabase, alias);
  }
}

class Membership extends DataClass implements Insertable<Membership> {
  final String tenantId;
  final String userId;
  final String role;
  final DateTime createdAt;
  const Membership(
      {required this.tenantId,
      required this.userId,
      required this.role,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MembershipsCompanion toCompanion(bool nullToAbsent) {
    return MembershipsCompanion(
      tenantId: Value(tenantId),
      userId: Value(userId),
      role: Value(role),
      createdAt: Value(createdAt),
    );
  }

  factory Membership.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Membership(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Membership copyWith(
          {String? tenantId,
          String? userId,
          String? role,
          DateTime? createdAt}) =>
      Membership(
        tenantId: tenantId ?? this.tenantId,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
      );
  Membership copyWithCompanion(MembershipsCompanion data) {
    return Membership(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Membership(')
          ..write('tenantId: $tenantId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tenantId, userId, role, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Membership &&
          other.tenantId == this.tenantId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.createdAt == this.createdAt);
}

class MembershipsCompanion extends UpdateCompanion<Membership> {
  final Value<String> tenantId;
  final Value<String> userId;
  final Value<String> role;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MembershipsCompanion({
    this.tenantId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembershipsCompanion.insert({
    required String tenantId,
    required String userId,
    required String role,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : tenantId = Value(tenantId),
        userId = Value(userId),
        role = Value(role),
        createdAt = Value(createdAt);
  static Insertable<Membership> custom({
    Expression<String>? tenantId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembershipsCompanion copyWith(
      {Value<String>? tenantId,
      Value<String>? userId,
      Value<String>? role,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return MembershipsCompanion(
      tenantId: tenantId ?? this.tenantId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembershipsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activeTenantIdMeta =
      const VerificationMeta('activeTenantId');
  @override
  late final GeneratedColumn<String> activeTenantId = GeneratedColumn<String>(
      'active_tenant_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mfaVerifiedMeta =
      const VerificationMeta('mfaVerified');
  @override
  late final GeneratedColumn<bool> mfaVerified = GeneratedColumn<bool>(
      'mfa_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("mfa_verified" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _recentAuthAtMeta =
      const VerificationMeta('recentAuthAt');
  @override
  late final GeneratedColumn<DateTime> recentAuthAt = GeneratedColumn<DateTime>(
      'recent_auth_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _csrfSecretMeta =
      const VerificationMeta('csrfSecret');
  @override
  late final GeneratedColumn<String> csrfSecret = GeneratedColumn<String>(
      'csrf_secret', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastSeenAtMeta =
      const VerificationMeta('lastSeenAt');
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
      'last_seen_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _ipMeta = const VerificationMeta('ip');
  @override
  late final GeneratedColumn<String> ip = GeneratedColumn<String>(
      'ip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userAgentMeta =
      const VerificationMeta('userAgent');
  @override
  late final GeneratedColumn<String> userAgent = GeneratedColumn<String>(
      'user_agent', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        activeTenantId,
        mfaVerified,
        recentAuthAt,
        csrfSecret,
        createdAt,
        lastSeenAt,
        expiresAt,
        ip,
        userAgent
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('active_tenant_id')) {
      context.handle(
          _activeTenantIdMeta,
          activeTenantId.isAcceptableOrUnknown(
              data['active_tenant_id']!, _activeTenantIdMeta));
    }
    if (data.containsKey('mfa_verified')) {
      context.handle(
          _mfaVerifiedMeta,
          mfaVerified.isAcceptableOrUnknown(
              data['mfa_verified']!, _mfaVerifiedMeta));
    }
    if (data.containsKey('recent_auth_at')) {
      context.handle(
          _recentAuthAtMeta,
          recentAuthAt.isAcceptableOrUnknown(
              data['recent_auth_at']!, _recentAuthAtMeta));
    }
    if (data.containsKey('csrf_secret')) {
      context.handle(
          _csrfSecretMeta,
          csrfSecret.isAcceptableOrUnknown(
              data['csrf_secret']!, _csrfSecretMeta));
    } else if (isInserting) {
      context.missing(_csrfSecretMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
          _lastSeenAtMeta,
          lastSeenAt.isAcceptableOrUnknown(
              data['last_seen_at']!, _lastSeenAtMeta));
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('ip')) {
      context.handle(_ipMeta, ip.isAcceptableOrUnknown(data['ip']!, _ipMeta));
    }
    if (data.containsKey('user_agent')) {
      context.handle(_userAgentMeta,
          userAgent.isAcceptableOrUnknown(data['user_agent']!, _userAgentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      activeTenantId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_tenant_id']),
      mfaVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}mfa_verified'])!,
      recentAuthAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}recent_auth_at']),
      csrfSecret: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}csrf_secret'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastSeenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at'])!,
      ip: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ip']),
      userAgent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_agent']),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String userId;
  final String? activeTenantId;
  final bool mfaVerified;
  final DateTime? recentAuthAt;
  final String csrfSecret;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final DateTime expiresAt;
  final String? ip;
  final String? userAgent;
  const Session(
      {required this.id,
      required this.userId,
      this.activeTenantId,
      required this.mfaVerified,
      this.recentAuthAt,
      required this.csrfSecret,
      required this.createdAt,
      required this.lastSeenAt,
      required this.expiresAt,
      this.ip,
      this.userAgent});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || activeTenantId != null) {
      map['active_tenant_id'] = Variable<String>(activeTenantId);
    }
    map['mfa_verified'] = Variable<bool>(mfaVerified);
    if (!nullToAbsent || recentAuthAt != null) {
      map['recent_auth_at'] = Variable<DateTime>(recentAuthAt);
    }
    map['csrf_secret'] = Variable<String>(csrfSecret);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || ip != null) {
      map['ip'] = Variable<String>(ip);
    }
    if (!nullToAbsent || userAgent != null) {
      map['user_agent'] = Variable<String>(userAgent);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      activeTenantId: activeTenantId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeTenantId),
      mfaVerified: Value(mfaVerified),
      recentAuthAt: recentAuthAt == null && nullToAbsent
          ? const Value.absent()
          : Value(recentAuthAt),
      csrfSecret: Value(csrfSecret),
      createdAt: Value(createdAt),
      lastSeenAt: Value(lastSeenAt),
      expiresAt: Value(expiresAt),
      ip: ip == null && nullToAbsent ? const Value.absent() : Value(ip),
      userAgent: userAgent == null && nullToAbsent
          ? const Value.absent()
          : Value(userAgent),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      activeTenantId: serializer.fromJson<String?>(json['activeTenantId']),
      mfaVerified: serializer.fromJson<bool>(json['mfaVerified']),
      recentAuthAt: serializer.fromJson<DateTime?>(json['recentAuthAt']),
      csrfSecret: serializer.fromJson<String>(json['csrfSecret']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      ip: serializer.fromJson<String?>(json['ip']),
      userAgent: serializer.fromJson<String?>(json['userAgent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'activeTenantId': serializer.toJson<String?>(activeTenantId),
      'mfaVerified': serializer.toJson<bool>(mfaVerified),
      'recentAuthAt': serializer.toJson<DateTime?>(recentAuthAt),
      'csrfSecret': serializer.toJson<String>(csrfSecret),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'ip': serializer.toJson<String?>(ip),
      'userAgent': serializer.toJson<String?>(userAgent),
    };
  }

  Session copyWith(
          {String? id,
          String? userId,
          Value<String?> activeTenantId = const Value.absent(),
          bool? mfaVerified,
          Value<DateTime?> recentAuthAt = const Value.absent(),
          String? csrfSecret,
          DateTime? createdAt,
          DateTime? lastSeenAt,
          DateTime? expiresAt,
          Value<String?> ip = const Value.absent(),
          Value<String?> userAgent = const Value.absent()}) =>
      Session(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        activeTenantId:
            activeTenantId.present ? activeTenantId.value : this.activeTenantId,
        mfaVerified: mfaVerified ?? this.mfaVerified,
        recentAuthAt:
            recentAuthAt.present ? recentAuthAt.value : this.recentAuthAt,
        csrfSecret: csrfSecret ?? this.csrfSecret,
        createdAt: createdAt ?? this.createdAt,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        expiresAt: expiresAt ?? this.expiresAt,
        ip: ip.present ? ip.value : this.ip,
        userAgent: userAgent.present ? userAgent.value : this.userAgent,
      );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      activeTenantId: data.activeTenantId.present
          ? data.activeTenantId.value
          : this.activeTenantId,
      mfaVerified:
          data.mfaVerified.present ? data.mfaVerified.value : this.mfaVerified,
      recentAuthAt: data.recentAuthAt.present
          ? data.recentAuthAt.value
          : this.recentAuthAt,
      csrfSecret:
          data.csrfSecret.present ? data.csrfSecret.value : this.csrfSecret,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSeenAt:
          data.lastSeenAt.present ? data.lastSeenAt.value : this.lastSeenAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      ip: data.ip.present ? data.ip.value : this.ip,
      userAgent: data.userAgent.present ? data.userAgent.value : this.userAgent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('activeTenantId: $activeTenantId, ')
          ..write('mfaVerified: $mfaVerified, ')
          ..write('recentAuthAt: $recentAuthAt, ')
          ..write('csrfSecret: $csrfSecret, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('ip: $ip, ')
          ..write('userAgent: $userAgent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      activeTenantId,
      mfaVerified,
      recentAuthAt,
      csrfSecret,
      createdAt,
      lastSeenAt,
      expiresAt,
      ip,
      userAgent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.activeTenantId == this.activeTenantId &&
          other.mfaVerified == this.mfaVerified &&
          other.recentAuthAt == this.recentAuthAt &&
          other.csrfSecret == this.csrfSecret &&
          other.createdAt == this.createdAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.expiresAt == this.expiresAt &&
          other.ip == this.ip &&
          other.userAgent == this.userAgent);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> activeTenantId;
  final Value<bool> mfaVerified;
  final Value<DateTime?> recentAuthAt;
  final Value<String> csrfSecret;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastSeenAt;
  final Value<DateTime> expiresAt;
  final Value<String?> ip;
  final Value<String?> userAgent;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.activeTenantId = const Value.absent(),
    this.mfaVerified = const Value.absent(),
    this.recentAuthAt = const Value.absent(),
    this.csrfSecret = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.ip = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String userId,
    this.activeTenantId = const Value.absent(),
    this.mfaVerified = const Value.absent(),
    this.recentAuthAt = const Value.absent(),
    required String csrfSecret,
    required DateTime createdAt,
    required DateTime lastSeenAt,
    required DateTime expiresAt,
    this.ip = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        csrfSecret = Value(csrfSecret),
        createdAt = Value(createdAt),
        lastSeenAt = Value(lastSeenAt),
        expiresAt = Value(expiresAt);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? activeTenantId,
    Expression<bool>? mfaVerified,
    Expression<DateTime>? recentAuthAt,
    Expression<String>? csrfSecret,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? expiresAt,
    Expression<String>? ip,
    Expression<String>? userAgent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (activeTenantId != null) 'active_tenant_id': activeTenantId,
      if (mfaVerified != null) 'mfa_verified': mfaVerified,
      if (recentAuthAt != null) 'recent_auth_at': recentAuthAt,
      if (csrfSecret != null) 'csrf_secret': csrfSecret,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (ip != null) 'ip': ip,
      if (userAgent != null) 'user_agent': userAgent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? activeTenantId,
      Value<bool>? mfaVerified,
      Value<DateTime?>? recentAuthAt,
      Value<String>? csrfSecret,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastSeenAt,
      Value<DateTime>? expiresAt,
      Value<String?>? ip,
      Value<String?>? userAgent,
      Value<int>? rowid}) {
    return SessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activeTenantId: activeTenantId ?? this.activeTenantId,
      mfaVerified: mfaVerified ?? this.mfaVerified,
      recentAuthAt: recentAuthAt ?? this.recentAuthAt,
      csrfSecret: csrfSecret ?? this.csrfSecret,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      expiresAt: expiresAt ?? this.expiresAt,
      ip: ip ?? this.ip,
      userAgent: userAgent ?? this.userAgent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (activeTenantId.present) {
      map['active_tenant_id'] = Variable<String>(activeTenantId.value);
    }
    if (mfaVerified.present) {
      map['mfa_verified'] = Variable<bool>(mfaVerified.value);
    }
    if (recentAuthAt.present) {
      map['recent_auth_at'] = Variable<DateTime>(recentAuthAt.value);
    }
    if (csrfSecret.present) {
      map['csrf_secret'] = Variable<String>(csrfSecret.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (ip.present) {
      map['ip'] = Variable<String>(ip.value);
    }
    if (userAgent.present) {
      map['user_agent'] = Variable<String>(userAgent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('activeTenantId: $activeTenantId, ')
          ..write('mfaVerified: $mfaVerified, ')
          ..write('recentAuthAt: $recentAuthAt, ')
          ..write('csrfSecret: $csrfSecret, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('ip: $ip, ')
          ..write('userAgent: $userAgent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TotpCredentialsTable extends TotpCredentials
    with TableInfo<$TotpCredentialsTable, TotpCredential> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TotpCredentialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyVersionMeta =
      const VerificationMeta('keyVersion');
  @override
  late final GeneratedColumn<int> keyVersion = GeneratedColumn<int>(
      'key_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _secretNonceMeta =
      const VerificationMeta('secretNonce');
  @override
  late final GeneratedColumn<Uint8List> secretNonce =
      GeneratedColumn<Uint8List>('secret_nonce', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _secretCiphertextMeta =
      const VerificationMeta('secretCiphertext');
  @override
  late final GeneratedColumn<Uint8List> secretCiphertext =
      GeneratedColumn<Uint8List>('secret_ciphertext', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _enabledAtMeta =
      const VerificationMeta('enabledAt');
  @override
  late final GeneratedColumn<DateTime> enabledAt = GeneratedColumn<DateTime>(
      'enabled_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        keyVersion,
        secretNonce,
        secretCiphertext,
        createdAt,
        updatedAt,
        enabledAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'totp_credentials';
  @override
  VerificationContext validateIntegrity(Insertable<TotpCredential> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('key_version')) {
      context.handle(
          _keyVersionMeta,
          keyVersion.isAcceptableOrUnknown(
              data['key_version']!, _keyVersionMeta));
    }
    if (data.containsKey('secret_nonce')) {
      context.handle(
          _secretNonceMeta,
          secretNonce.isAcceptableOrUnknown(
              data['secret_nonce']!, _secretNonceMeta));
    } else if (isInserting) {
      context.missing(_secretNonceMeta);
    }
    if (data.containsKey('secret_ciphertext')) {
      context.handle(
          _secretCiphertextMeta,
          secretCiphertext.isAcceptableOrUnknown(
              data['secret_ciphertext']!, _secretCiphertextMeta));
    } else if (isInserting) {
      context.missing(_secretCiphertextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('enabled_at')) {
      context.handle(_enabledAtMeta,
          enabledAt.isAcceptableOrUnknown(data['enabled_at']!, _enabledAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  TotpCredential map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TotpCredential(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      keyVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key_version'])!,
      secretNonce: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}secret_nonce'])!,
      secretCiphertext: attachedDatabase.typeMapping.read(
          DriftSqlType.blob, data['${effectivePrefix}secret_ciphertext'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      enabledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}enabled_at']),
    );
  }

  @override
  $TotpCredentialsTable createAlias(String alias) {
    return $TotpCredentialsTable(attachedDatabase, alias);
  }
}

class TotpCredential extends DataClass implements Insertable<TotpCredential> {
  final String userId;
  final int keyVersion;
  final Uint8List secretNonce;
  final Uint8List secretCiphertext;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? enabledAt;
  const TotpCredential(
      {required this.userId,
      required this.keyVersion,
      required this.secretNonce,
      required this.secretCiphertext,
      required this.createdAt,
      required this.updatedAt,
      this.enabledAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['key_version'] = Variable<int>(keyVersion);
    map['secret_nonce'] = Variable<Uint8List>(secretNonce);
    map['secret_ciphertext'] = Variable<Uint8List>(secretCiphertext);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || enabledAt != null) {
      map['enabled_at'] = Variable<DateTime>(enabledAt);
    }
    return map;
  }

  TotpCredentialsCompanion toCompanion(bool nullToAbsent) {
    return TotpCredentialsCompanion(
      userId: Value(userId),
      keyVersion: Value(keyVersion),
      secretNonce: Value(secretNonce),
      secretCiphertext: Value(secretCiphertext),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      enabledAt: enabledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(enabledAt),
    );
  }

  factory TotpCredential.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TotpCredential(
      userId: serializer.fromJson<String>(json['userId']),
      keyVersion: serializer.fromJson<int>(json['keyVersion']),
      secretNonce: serializer.fromJson<Uint8List>(json['secretNonce']),
      secretCiphertext:
          serializer.fromJson<Uint8List>(json['secretCiphertext']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      enabledAt: serializer.fromJson<DateTime?>(json['enabledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'keyVersion': serializer.toJson<int>(keyVersion),
      'secretNonce': serializer.toJson<Uint8List>(secretNonce),
      'secretCiphertext': serializer.toJson<Uint8List>(secretCiphertext),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'enabledAt': serializer.toJson<DateTime?>(enabledAt),
    };
  }

  TotpCredential copyWith(
          {String? userId,
          int? keyVersion,
          Uint8List? secretNonce,
          Uint8List? secretCiphertext,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> enabledAt = const Value.absent()}) =>
      TotpCredential(
        userId: userId ?? this.userId,
        keyVersion: keyVersion ?? this.keyVersion,
        secretNonce: secretNonce ?? this.secretNonce,
        secretCiphertext: secretCiphertext ?? this.secretCiphertext,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        enabledAt: enabledAt.present ? enabledAt.value : this.enabledAt,
      );
  TotpCredential copyWithCompanion(TotpCredentialsCompanion data) {
    return TotpCredential(
      userId: data.userId.present ? data.userId.value : this.userId,
      keyVersion:
          data.keyVersion.present ? data.keyVersion.value : this.keyVersion,
      secretNonce:
          data.secretNonce.present ? data.secretNonce.value : this.secretNonce,
      secretCiphertext: data.secretCiphertext.present
          ? data.secretCiphertext.value
          : this.secretCiphertext,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      enabledAt: data.enabledAt.present ? data.enabledAt.value : this.enabledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TotpCredential(')
          ..write('userId: $userId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('secretNonce: $secretNonce, ')
          ..write('secretCiphertext: $secretCiphertext, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('enabledAt: $enabledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      userId,
      keyVersion,
      $driftBlobEquality.hash(secretNonce),
      $driftBlobEquality.hash(secretCiphertext),
      createdAt,
      updatedAt,
      enabledAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TotpCredential &&
          other.userId == this.userId &&
          other.keyVersion == this.keyVersion &&
          $driftBlobEquality.equals(other.secretNonce, this.secretNonce) &&
          $driftBlobEquality.equals(
              other.secretCiphertext, this.secretCiphertext) &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.enabledAt == this.enabledAt);
}

class TotpCredentialsCompanion extends UpdateCompanion<TotpCredential> {
  final Value<String> userId;
  final Value<int> keyVersion;
  final Value<Uint8List> secretNonce;
  final Value<Uint8List> secretCiphertext;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> enabledAt;
  final Value<int> rowid;
  const TotpCredentialsCompanion({
    this.userId = const Value.absent(),
    this.keyVersion = const Value.absent(),
    this.secretNonce = const Value.absent(),
    this.secretCiphertext = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.enabledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TotpCredentialsCompanion.insert({
    required String userId,
    this.keyVersion = const Value.absent(),
    required Uint8List secretNonce,
    required Uint8List secretCiphertext,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.enabledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        secretNonce = Value(secretNonce),
        secretCiphertext = Value(secretCiphertext),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<TotpCredential> custom({
    Expression<String>? userId,
    Expression<int>? keyVersion,
    Expression<Uint8List>? secretNonce,
    Expression<Uint8List>? secretCiphertext,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? enabledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (keyVersion != null) 'key_version': keyVersion,
      if (secretNonce != null) 'secret_nonce': secretNonce,
      if (secretCiphertext != null) 'secret_ciphertext': secretCiphertext,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (enabledAt != null) 'enabled_at': enabledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TotpCredentialsCompanion copyWith(
      {Value<String>? userId,
      Value<int>? keyVersion,
      Value<Uint8List>? secretNonce,
      Value<Uint8List>? secretCiphertext,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? enabledAt,
      Value<int>? rowid}) {
    return TotpCredentialsCompanion(
      userId: userId ?? this.userId,
      keyVersion: keyVersion ?? this.keyVersion,
      secretNonce: secretNonce ?? this.secretNonce,
      secretCiphertext: secretCiphertext ?? this.secretCiphertext,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enabledAt: enabledAt ?? this.enabledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (keyVersion.present) {
      map['key_version'] = Variable<int>(keyVersion.value);
    }
    if (secretNonce.present) {
      map['secret_nonce'] = Variable<Uint8List>(secretNonce.value);
    }
    if (secretCiphertext.present) {
      map['secret_ciphertext'] = Variable<Uint8List>(secretCiphertext.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (enabledAt.present) {
      map['enabled_at'] = Variable<DateTime>(enabledAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TotpCredentialsCompanion(')
          ..write('userId: $userId, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('secretNonce: $secretNonce, ')
          ..write('secretCiphertext: $secretCiphertext, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('enabledAt: $enabledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecoveryCodesTable extends RecoveryCodes
    with TableInfo<$RecoveryCodesTable, RecoveryCode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecoveryCodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeHashMeta =
      const VerificationMeta('codeHash');
  @override
  late final GeneratedColumn<String> codeHash = GeneratedColumn<String>(
      'code_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<DateTime> usedAt = GeneratedColumn<DateTime>(
      'used_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, codeHash, createdAt, usedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recovery_codes';
  @override
  VerificationContext validateIntegrity(Insertable<RecoveryCode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('code_hash')) {
      context.handle(_codeHashMeta,
          codeHash.isAcceptableOrUnknown(data['code_hash']!, _codeHashMeta));
    } else if (isInserting) {
      context.missing(_codeHashMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('used_at')) {
      context.handle(_usedAtMeta,
          usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecoveryCode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecoveryCode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      codeHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code_hash'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      usedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}used_at']),
    );
  }

  @override
  $RecoveryCodesTable createAlias(String alias) {
    return $RecoveryCodesTable(attachedDatabase, alias);
  }
}

class RecoveryCode extends DataClass implements Insertable<RecoveryCode> {
  final String id;
  final String userId;
  final String codeHash;
  final DateTime createdAt;
  final DateTime? usedAt;
  const RecoveryCode(
      {required this.id,
      required this.userId,
      required this.codeHash,
      required this.createdAt,
      this.usedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['code_hash'] = Variable<String>(codeHash);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || usedAt != null) {
      map['used_at'] = Variable<DateTime>(usedAt);
    }
    return map;
  }

  RecoveryCodesCompanion toCompanion(bool nullToAbsent) {
    return RecoveryCodesCompanion(
      id: Value(id),
      userId: Value(userId),
      codeHash: Value(codeHash),
      createdAt: Value(createdAt),
      usedAt:
          usedAt == null && nullToAbsent ? const Value.absent() : Value(usedAt),
    );
  }

  factory RecoveryCode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecoveryCode(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      codeHash: serializer.fromJson<String>(json['codeHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      usedAt: serializer.fromJson<DateTime?>(json['usedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'codeHash': serializer.toJson<String>(codeHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'usedAt': serializer.toJson<DateTime?>(usedAt),
    };
  }

  RecoveryCode copyWith(
          {String? id,
          String? userId,
          String? codeHash,
          DateTime? createdAt,
          Value<DateTime?> usedAt = const Value.absent()}) =>
      RecoveryCode(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        codeHash: codeHash ?? this.codeHash,
        createdAt: createdAt ?? this.createdAt,
        usedAt: usedAt.present ? usedAt.value : this.usedAt,
      );
  RecoveryCode copyWithCompanion(RecoveryCodesCompanion data) {
    return RecoveryCode(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      codeHash: data.codeHash.present ? data.codeHash.value : this.codeHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryCode(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('codeHash: $codeHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('usedAt: $usedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, codeHash, createdAt, usedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecoveryCode &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.codeHash == this.codeHash &&
          other.createdAt == this.createdAt &&
          other.usedAt == this.usedAt);
}

class RecoveryCodesCompanion extends UpdateCompanion<RecoveryCode> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> codeHash;
  final Value<DateTime> createdAt;
  final Value<DateTime?> usedAt;
  final Value<int> rowid;
  const RecoveryCodesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.codeHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecoveryCodesCompanion.insert({
    required String id,
    required String userId,
    required String codeHash,
    required DateTime createdAt,
    this.usedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        codeHash = Value(codeHash),
        createdAt = Value(createdAt);
  static Insertable<RecoveryCode> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? codeHash,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? usedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (codeHash != null) 'code_hash': codeHash,
      if (createdAt != null) 'created_at': createdAt,
      if (usedAt != null) 'used_at': usedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecoveryCodesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? codeHash,
      Value<DateTime>? createdAt,
      Value<DateTime?>? usedAt,
      Value<int>? rowid}) {
    return RecoveryCodesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      codeHash: codeHash ?? this.codeHash,
      createdAt: createdAt ?? this.createdAt,
      usedAt: usedAt ?? this.usedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (codeHash.present) {
      map['code_hash'] = Variable<String>(codeHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<DateTime>(usedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryCodesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('codeHash: $codeHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('usedAt: $usedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvitesTable extends Invites with TableInfo<$InvitesTable, Invite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvitesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tokenHashMeta =
      const VerificationMeta('tokenHash');
  @override
  late final GeneratedColumn<String> tokenHash = GeneratedColumn<String>(
      'token_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _acceptedAtMeta =
      const VerificationMeta('acceptedAt');
  @override
  late final GeneratedColumn<DateTime> acceptedAt = GeneratedColumn<DateTime>(
      'accepted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, tenantId, email, role, tokenHash, expiresAt, acceptedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invites';
  @override
  VerificationContext validateIntegrity(Insertable<Invite> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('token_hash')) {
      context.handle(_tokenHashMeta,
          tokenHash.isAcceptableOrUnknown(data['token_hash']!, _tokenHashMeta));
    } else if (isInserting) {
      context.missing(_tokenHashMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
          _acceptedAtMeta,
          acceptedAt.isAcceptableOrUnknown(
              data['accepted_at']!, _acceptedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Invite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Invite(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      tokenHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}token_hash'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at'])!,
      acceptedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}accepted_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InvitesTable createAlias(String alias) {
    return $InvitesTable(attachedDatabase, alias);
  }
}

class Invite extends DataClass implements Insertable<Invite> {
  final String id;
  final String tenantId;
  final String email;
  final String role;
  final String tokenHash;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  const Invite(
      {required this.id,
      required this.tenantId,
      required this.email,
      required this.role,
      required this.tokenHash,
      required this.expiresAt,
      this.acceptedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['email'] = Variable<String>(email);
    map['role'] = Variable<String>(role);
    map['token_hash'] = Variable<String>(tokenHash);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || acceptedAt != null) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InvitesCompanion toCompanion(bool nullToAbsent) {
    return InvitesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      email: Value(email),
      role: Value(role),
      tokenHash: Value(tokenHash),
      expiresAt: Value(expiresAt),
      acceptedAt: acceptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Invite.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Invite(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      email: serializer.fromJson<String>(json['email']),
      role: serializer.fromJson<String>(json['role']),
      tokenHash: serializer.fromJson<String>(json['tokenHash']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      acceptedAt: serializer.fromJson<DateTime?>(json['acceptedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'email': serializer.toJson<String>(email),
      'role': serializer.toJson<String>(role),
      'tokenHash': serializer.toJson<String>(tokenHash),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'acceptedAt': serializer.toJson<DateTime?>(acceptedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Invite copyWith(
          {String? id,
          String? tenantId,
          String? email,
          String? role,
          String? tokenHash,
          DateTime? expiresAt,
          Value<DateTime?> acceptedAt = const Value.absent(),
          DateTime? createdAt}) =>
      Invite(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        email: email ?? this.email,
        role: role ?? this.role,
        tokenHash: tokenHash ?? this.tokenHash,
        expiresAt: expiresAt ?? this.expiresAt,
        acceptedAt: acceptedAt.present ? acceptedAt.value : this.acceptedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  Invite copyWithCompanion(InvitesCompanion data) {
    return Invite(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      email: data.email.present ? data.email.value : this.email,
      role: data.role.present ? data.role.value : this.role,
      tokenHash: data.tokenHash.present ? data.tokenHash.value : this.tokenHash,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      acceptedAt:
          data.acceptedAt.present ? data.acceptedAt.value : this.acceptedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Invite(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('email: $email, ')
          ..write('role: $role, ')
          ..write('tokenHash: $tokenHash, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, tenantId, email, role, tokenHash, expiresAt, acceptedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Invite &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.email == this.email &&
          other.role == this.role &&
          other.tokenHash == this.tokenHash &&
          other.expiresAt == this.expiresAt &&
          other.acceptedAt == this.acceptedAt &&
          other.createdAt == this.createdAt);
}

class InvitesCompanion extends UpdateCompanion<Invite> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> email;
  final Value<String> role;
  final Value<String> tokenHash;
  final Value<DateTime> expiresAt;
  final Value<DateTime?> acceptedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const InvitesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.email = const Value.absent(),
    this.role = const Value.absent(),
    this.tokenHash = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvitesCompanion.insert({
    required String id,
    required String tenantId,
    required String email,
    required String role,
    required String tokenHash,
    required DateTime expiresAt,
    this.acceptedAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        email = Value(email),
        role = Value(role),
        tokenHash = Value(tokenHash),
        expiresAt = Value(expiresAt),
        createdAt = Value(createdAt);
  static Insertable<Invite> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? email,
    Expression<String>? role,
    Expression<String>? tokenHash,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? acceptedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (tokenHash != null) 'token_hash': tokenHash,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvitesCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? email,
      Value<String>? role,
      Value<String>? tokenHash,
      Value<DateTime>? expiresAt,
      Value<DateTime?>? acceptedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return InvitesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      email: email ?? this.email,
      role: role ?? this.role,
      tokenHash: tokenHash ?? this.tokenHash,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (tokenHash.present) {
      map['token_hash'] = Variable<String>(tokenHash.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvitesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('email: $email, ')
          ..write('role: $role, ')
          ..write('tokenHash: $tokenHash, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogsTable extends AuditLogs
    with TableInfo<$AuditLogsTable, AuditLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actorUserIdMeta =
      const VerificationMeta('actorUserId');
  @override
  late final GeneratedColumn<String> actorUserId = GeneratedColumn<String>(
      'actor_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
      'target', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataJsonMeta =
      const VerificationMeta('metadataJson');
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
      'metadata_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ipMeta = const VerificationMeta('ip');
  @override
  late final GeneratedColumn<String> ip = GeneratedColumn<String>(
      'ip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userAgentMeta =
      const VerificationMeta('userAgent');
  @override
  late final GeneratedColumn<String> userAgent = GeneratedColumn<String>(
      'user_agent', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        actorUserId,
        action,
        target,
        metadataJson,
        ip,
        userAgent,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AuditLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    }
    if (data.containsKey('actor_user_id')) {
      context.handle(
          _actorUserIdMeta,
          actorUserId.isAcceptableOrUnknown(
              data['actor_user_id']!, _actorUserIdMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('target')) {
      context.handle(_targetMeta,
          target.isAcceptableOrUnknown(data['target']!, _targetMeta));
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
          _metadataJsonMeta,
          metadataJson.isAcceptableOrUnknown(
              data['metadata_json']!, _metadataJsonMeta));
    }
    if (data.containsKey('ip')) {
      context.handle(_ipMeta, ip.isAcceptableOrUnknown(data['ip']!, _ipMeta));
    }
    if (data.containsKey('user_agent')) {
      context.handle(_userAgentMeta,
          userAgent.isAcceptableOrUnknown(data['user_agent']!, _userAgentMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id']),
      actorUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}actor_user_id']),
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      target: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target']),
      metadataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata_json']),
      ip: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ip']),
      userAgent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_agent']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AuditLogsTable createAlias(String alias) {
    return $AuditLogsTable(attachedDatabase, alias);
  }
}

class AuditLog extends DataClass implements Insertable<AuditLog> {
  final String id;
  final String? tenantId;
  final String? actorUserId;
  final String action;
  final String? target;
  final String? metadataJson;
  final String? ip;
  final String? userAgent;
  final DateTime createdAt;
  const AuditLog(
      {required this.id,
      this.tenantId,
      this.actorUserId,
      required this.action,
      this.target,
      this.metadataJson,
      this.ip,
      this.userAgent,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || tenantId != null) {
      map['tenant_id'] = Variable<String>(tenantId);
    }
    if (!nullToAbsent || actorUserId != null) {
      map['actor_user_id'] = Variable<String>(actorUserId);
    }
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<String>(target);
    }
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    if (!nullToAbsent || ip != null) {
      map['ip'] = Variable<String>(ip);
    }
    if (!nullToAbsent || userAgent != null) {
      map['user_agent'] = Variable<String>(userAgent);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuditLogsCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsCompanion(
      id: Value(id),
      tenantId: tenantId == null && nullToAbsent
          ? const Value.absent()
          : Value(tenantId),
      actorUserId: actorUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorUserId),
      action: Value(action),
      target:
          target == null && nullToAbsent ? const Value.absent() : Value(target),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      ip: ip == null && nullToAbsent ? const Value.absent() : Value(ip),
      userAgent: userAgent == null && nullToAbsent
          ? const Value.absent()
          : Value(userAgent),
      createdAt: Value(createdAt),
    );
  }

  factory AuditLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLog(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String?>(json['tenantId']),
      actorUserId: serializer.fromJson<String?>(json['actorUserId']),
      action: serializer.fromJson<String>(json['action']),
      target: serializer.fromJson<String?>(json['target']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      ip: serializer.fromJson<String?>(json['ip']),
      userAgent: serializer.fromJson<String?>(json['userAgent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String?>(tenantId),
      'actorUserId': serializer.toJson<String?>(actorUserId),
      'action': serializer.toJson<String>(action),
      'target': serializer.toJson<String?>(target),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'ip': serializer.toJson<String?>(ip),
      'userAgent': serializer.toJson<String?>(userAgent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuditLog copyWith(
          {String? id,
          Value<String?> tenantId = const Value.absent(),
          Value<String?> actorUserId = const Value.absent(),
          String? action,
          Value<String?> target = const Value.absent(),
          Value<String?> metadataJson = const Value.absent(),
          Value<String?> ip = const Value.absent(),
          Value<String?> userAgent = const Value.absent(),
          DateTime? createdAt}) =>
      AuditLog(
        id: id ?? this.id,
        tenantId: tenantId.present ? tenantId.value : this.tenantId,
        actorUserId: actorUserId.present ? actorUserId.value : this.actorUserId,
        action: action ?? this.action,
        target: target.present ? target.value : this.target,
        metadataJson:
            metadataJson.present ? metadataJson.value : this.metadataJson,
        ip: ip.present ? ip.value : this.ip,
        userAgent: userAgent.present ? userAgent.value : this.userAgent,
        createdAt: createdAt ?? this.createdAt,
      );
  AuditLog copyWithCompanion(AuditLogsCompanion data) {
    return AuditLog(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      actorUserId:
          data.actorUserId.present ? data.actorUserId.value : this.actorUserId,
      action: data.action.present ? data.action.value : this.action,
      target: data.target.present ? data.target.value : this.target,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      ip: data.ip.present ? data.ip.value : this.ip,
      userAgent: data.userAgent.present ? data.userAgent.value : this.userAgent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLog(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('action: $action, ')
          ..write('target: $target, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('ip: $ip, ')
          ..write('userAgent: $userAgent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tenantId, actorUserId, action, target,
      metadataJson, ip, userAgent, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLog &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.actorUserId == this.actorUserId &&
          other.action == this.action &&
          other.target == this.target &&
          other.metadataJson == this.metadataJson &&
          other.ip == this.ip &&
          other.userAgent == this.userAgent &&
          other.createdAt == this.createdAt);
}

class AuditLogsCompanion extends UpdateCompanion<AuditLog> {
  final Value<String> id;
  final Value<String?> tenantId;
  final Value<String?> actorUserId;
  final Value<String> action;
  final Value<String?> target;
  final Value<String?> metadataJson;
  final Value<String?> ip;
  final Value<String?> userAgent;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AuditLogsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.action = const Value.absent(),
    this.target = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.ip = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogsCompanion.insert({
    required String id,
    this.tenantId = const Value.absent(),
    this.actorUserId = const Value.absent(),
    required String action,
    this.target = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.ip = const Value.absent(),
    this.userAgent = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        action = Value(action),
        createdAt = Value(createdAt);
  static Insertable<AuditLog> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? actorUserId,
    Expression<String>? action,
    Expression<String>? target,
    Expression<String>? metadataJson,
    Expression<String>? ip,
    Expression<String>? userAgent,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (action != null) 'action': action,
      if (target != null) 'target': target,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (ip != null) 'ip': ip,
      if (userAgent != null) 'user_agent': userAgent,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? tenantId,
      Value<String?>? actorUserId,
      Value<String>? action,
      Value<String?>? target,
      Value<String?>? metadataJson,
      Value<String?>? ip,
      Value<String?>? userAgent,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AuditLogsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      actorUserId: actorUserId ?? this.actorUserId,
      action: action ?? this.action,
      target: target ?? this.target,
      metadataJson: metadataJson ?? this.metadataJson,
      ip: ip ?? this.ip,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (actorUserId.present) {
      map['actor_user_id'] = Variable<String>(actorUserId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (ip.present) {
      map['ip'] = Variable<String>(ip.value);
    }
    if (userAgent.present) {
      map['user_agent'] = Variable<String>(userAgent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('action: $action, ')
          ..write('target: $target, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('ip: $ip, ')
          ..write('userAgent: $userAgent, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PasswordResetTokensTable extends PasswordResetTokens
    with TableInfo<$PasswordResetTokensTable, PasswordResetToken> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PasswordResetTokensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tokenHashMeta =
      const VerificationMeta('tokenHash');
  @override
  late final GeneratedColumn<String> tokenHash = GeneratedColumn<String>(
      'token_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<DateTime> usedAt = GeneratedColumn<DateTime>(
      'used_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, tokenHash, expiresAt, usedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'password_reset_tokens';
  @override
  VerificationContext validateIntegrity(Insertable<PasswordResetToken> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('token_hash')) {
      context.handle(_tokenHashMeta,
          tokenHash.isAcceptableOrUnknown(data['token_hash']!, _tokenHashMeta));
    } else if (isInserting) {
      context.missing(_tokenHashMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('used_at')) {
      context.handle(_usedAtMeta,
          usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PasswordResetToken map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PasswordResetToken(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      tokenHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}token_hash'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at'])!,
      usedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}used_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PasswordResetTokensTable createAlias(String alias) {
    return $PasswordResetTokensTable(attachedDatabase, alias);
  }
}

class PasswordResetToken extends DataClass
    implements Insertable<PasswordResetToken> {
  final String id;
  final String userId;
  final String tokenHash;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final DateTime createdAt;
  const PasswordResetToken(
      {required this.id,
      required this.userId,
      required this.tokenHash,
      required this.expiresAt,
      this.usedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['token_hash'] = Variable<String>(tokenHash);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || usedAt != null) {
      map['used_at'] = Variable<DateTime>(usedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PasswordResetTokensCompanion toCompanion(bool nullToAbsent) {
    return PasswordResetTokensCompanion(
      id: Value(id),
      userId: Value(userId),
      tokenHash: Value(tokenHash),
      expiresAt: Value(expiresAt),
      usedAt:
          usedAt == null && nullToAbsent ? const Value.absent() : Value(usedAt),
      createdAt: Value(createdAt),
    );
  }

  factory PasswordResetToken.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PasswordResetToken(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      tokenHash: serializer.fromJson<String>(json['tokenHash']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      usedAt: serializer.fromJson<DateTime?>(json['usedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'tokenHash': serializer.toJson<String>(tokenHash),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'usedAt': serializer.toJson<DateTime?>(usedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PasswordResetToken copyWith(
          {String? id,
          String? userId,
          String? tokenHash,
          DateTime? expiresAt,
          Value<DateTime?> usedAt = const Value.absent(),
          DateTime? createdAt}) =>
      PasswordResetToken(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        tokenHash: tokenHash ?? this.tokenHash,
        expiresAt: expiresAt ?? this.expiresAt,
        usedAt: usedAt.present ? usedAt.value : this.usedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  PasswordResetToken copyWithCompanion(PasswordResetTokensCompanion data) {
    return PasswordResetToken(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      tokenHash: data.tokenHash.present ? data.tokenHash.value : this.tokenHash,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PasswordResetToken(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tokenHash: $tokenHash, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('usedAt: $usedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, tokenHash, expiresAt, usedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PasswordResetToken &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.tokenHash == this.tokenHash &&
          other.expiresAt == this.expiresAt &&
          other.usedAt == this.usedAt &&
          other.createdAt == this.createdAt);
}

class PasswordResetTokensCompanion extends UpdateCompanion<PasswordResetToken> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> tokenHash;
  final Value<DateTime> expiresAt;
  final Value<DateTime?> usedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PasswordResetTokensCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.tokenHash = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PasswordResetTokensCompanion.insert({
    required String id,
    required String userId,
    required String tokenHash,
    required DateTime expiresAt,
    this.usedAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        tokenHash = Value(tokenHash),
        expiresAt = Value(expiresAt),
        createdAt = Value(createdAt);
  static Insertable<PasswordResetToken> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? tokenHash,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? usedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (tokenHash != null) 'token_hash': tokenHash,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (usedAt != null) 'used_at': usedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PasswordResetTokensCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? tokenHash,
      Value<DateTime>? expiresAt,
      Value<DateTime?>? usedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PasswordResetTokensCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tokenHash: tokenHash ?? this.tokenHash,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (tokenHash.present) {
      map['token_hash'] = Variable<String>(tokenHash.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<DateTime>(usedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PasswordResetTokensCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tokenHash: $tokenHash, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('usedAt: $usedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmailVerificationTokensTable extends EmailVerificationTokens
    with TableInfo<$EmailVerificationTokensTable, EmailVerificationToken> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmailVerificationTokensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tokenHashMeta =
      const VerificationMeta('tokenHash');
  @override
  late final GeneratedColumn<String> tokenHash = GeneratedColumn<String>(
      'token_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<DateTime> usedAt = GeneratedColumn<DateTime>(
      'used_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, tokenHash, expiresAt, usedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'email_verification_tokens';
  @override
  VerificationContext validateIntegrity(
      Insertable<EmailVerificationToken> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('token_hash')) {
      context.handle(_tokenHashMeta,
          tokenHash.isAcceptableOrUnknown(data['token_hash']!, _tokenHashMeta));
    } else if (isInserting) {
      context.missing(_tokenHashMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('used_at')) {
      context.handle(_usedAtMeta,
          usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmailVerificationToken map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmailVerificationToken(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      tokenHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}token_hash'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at'])!,
      usedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}used_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EmailVerificationTokensTable createAlias(String alias) {
    return $EmailVerificationTokensTable(attachedDatabase, alias);
  }
}

class EmailVerificationToken extends DataClass
    implements Insertable<EmailVerificationToken> {
  final String id;
  final String userId;
  final String tokenHash;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final DateTime createdAt;
  const EmailVerificationToken(
      {required this.id,
      required this.userId,
      required this.tokenHash,
      required this.expiresAt,
      this.usedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['token_hash'] = Variable<String>(tokenHash);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || usedAt != null) {
      map['used_at'] = Variable<DateTime>(usedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EmailVerificationTokensCompanion toCompanion(bool nullToAbsent) {
    return EmailVerificationTokensCompanion(
      id: Value(id),
      userId: Value(userId),
      tokenHash: Value(tokenHash),
      expiresAt: Value(expiresAt),
      usedAt:
          usedAt == null && nullToAbsent ? const Value.absent() : Value(usedAt),
      createdAt: Value(createdAt),
    );
  }

  factory EmailVerificationToken.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmailVerificationToken(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      tokenHash: serializer.fromJson<String>(json['tokenHash']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      usedAt: serializer.fromJson<DateTime?>(json['usedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'tokenHash': serializer.toJson<String>(tokenHash),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'usedAt': serializer.toJson<DateTime?>(usedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EmailVerificationToken copyWith(
          {String? id,
          String? userId,
          String? tokenHash,
          DateTime? expiresAt,
          Value<DateTime?> usedAt = const Value.absent(),
          DateTime? createdAt}) =>
      EmailVerificationToken(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        tokenHash: tokenHash ?? this.tokenHash,
        expiresAt: expiresAt ?? this.expiresAt,
        usedAt: usedAt.present ? usedAt.value : this.usedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  EmailVerificationToken copyWithCompanion(
      EmailVerificationTokensCompanion data) {
    return EmailVerificationToken(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      tokenHash: data.tokenHash.present ? data.tokenHash.value : this.tokenHash,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmailVerificationToken(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tokenHash: $tokenHash, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('usedAt: $usedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, tokenHash, expiresAt, usedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmailVerificationToken &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.tokenHash == this.tokenHash &&
          other.expiresAt == this.expiresAt &&
          other.usedAt == this.usedAt &&
          other.createdAt == this.createdAt);
}

class EmailVerificationTokensCompanion
    extends UpdateCompanion<EmailVerificationToken> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> tokenHash;
  final Value<DateTime> expiresAt;
  final Value<DateTime?> usedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EmailVerificationTokensCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.tokenHash = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmailVerificationTokensCompanion.insert({
    required String id,
    required String userId,
    required String tokenHash,
    required DateTime expiresAt,
    this.usedAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        tokenHash = Value(tokenHash),
        expiresAt = Value(expiresAt),
        createdAt = Value(createdAt);
  static Insertable<EmailVerificationToken> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? tokenHash,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? usedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (tokenHash != null) 'token_hash': tokenHash,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (usedAt != null) 'used_at': usedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmailVerificationTokensCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? tokenHash,
      Value<DateTime>? expiresAt,
      Value<DateTime?>? usedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return EmailVerificationTokensCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tokenHash: tokenHash ?? this.tokenHash,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (tokenHash.present) {
      map['token_hash'] = Variable<String>(tokenHash.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<DateTime>(usedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmailVerificationTokensCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tokenHash: $tokenHash, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('usedAt: $usedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TenantsTable tenants = $TenantsTable(this);
  late final $TenantSettingsTable tenantSettings = $TenantSettingsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $MembershipsTable memberships = $MembershipsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $TotpCredentialsTable totpCredentials =
      $TotpCredentialsTable(this);
  late final $RecoveryCodesTable recoveryCodes = $RecoveryCodesTable(this);
  late final $InvitesTable invites = $InvitesTable(this);
  late final $AuditLogsTable auditLogs = $AuditLogsTable(this);
  late final $PasswordResetTokensTable passwordResetTokens =
      $PasswordResetTokensTable(this);
  late final $EmailVerificationTokensTable emailVerificationTokens =
      $EmailVerificationTokensTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        tenants,
        tenantSettings,
        users,
        memberships,
        sessions,
        totpCredentials,
        recoveryCodes,
        invites,
        auditLogs,
        passwordResetTokens,
        emailVerificationTokens
      ];
}

typedef $$TenantsTableCreateCompanionBuilder = TenantsCompanion Function({
  required String id,
  required String slug,
  required String name,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TenantsTableUpdateCompanionBuilder = TenantsCompanion Function({
  Value<String> id,
  Value<String> slug,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$TenantsTableFilterComposer
    extends Composer<_$AppDatabase, $TenantsTable> {
  $$TenantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TenantsTableOrderingComposer
    extends Composer<_$AppDatabase, $TenantsTable> {
  $$TenantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TenantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TenantsTable> {
  $$TenantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TenantsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TenantsTable,
    Tenant,
    $$TenantsTableFilterComposer,
    $$TenantsTableOrderingComposer,
    $$TenantsTableAnnotationComposer,
    $$TenantsTableCreateCompanionBuilder,
    $$TenantsTableUpdateCompanionBuilder,
    (Tenant, BaseReferences<_$AppDatabase, $TenantsTable, Tenant>),
    Tenant,
    PrefetchHooks Function()> {
  $$TenantsTableTableManager(_$AppDatabase db, $TenantsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TenantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TenantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TenantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> slug = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TenantsCompanion(
            id: id,
            slug: slug,
            name: name,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String slug,
            required String name,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TenantsCompanion.insert(
            id: id,
            slug: slug,
            name: name,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TenantsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TenantsTable,
    Tenant,
    $$TenantsTableFilterComposer,
    $$TenantsTableOrderingComposer,
    $$TenantsTableAnnotationComposer,
    $$TenantsTableCreateCompanionBuilder,
    $$TenantsTableUpdateCompanionBuilder,
    (Tenant, BaseReferences<_$AppDatabase, $TenantsTable, Tenant>),
    Tenant,
    PrefetchHooks Function()>;
typedef $$TenantSettingsTableCreateCompanionBuilder = TenantSettingsCompanion
    Function({
  required String tenantId,
  required String signupMode,
  Value<bool> requireMfaForAdmins,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TenantSettingsTableUpdateCompanionBuilder = TenantSettingsCompanion
    Function({
  Value<String> tenantId,
  Value<String> signupMode,
  Value<bool> requireMfaForAdmins,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TenantSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $TenantSettingsTable> {
  $$TenantSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get signupMode => $composableBuilder(
      column: $table.signupMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requireMfaForAdmins => $composableBuilder(
      column: $table.requireMfaForAdmins,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TenantSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $TenantSettingsTable> {
  $$TenantSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get signupMode => $composableBuilder(
      column: $table.signupMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requireMfaForAdmins => $composableBuilder(
      column: $table.requireMfaForAdmins,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TenantSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TenantSettingsTable> {
  $$TenantSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get signupMode => $composableBuilder(
      column: $table.signupMode, builder: (column) => column);

  GeneratedColumn<bool> get requireMfaForAdmins => $composableBuilder(
      column: $table.requireMfaForAdmins, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TenantSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TenantSettingsTable,
    TenantSetting,
    $$TenantSettingsTableFilterComposer,
    $$TenantSettingsTableOrderingComposer,
    $$TenantSettingsTableAnnotationComposer,
    $$TenantSettingsTableCreateCompanionBuilder,
    $$TenantSettingsTableUpdateCompanionBuilder,
    (
      TenantSetting,
      BaseReferences<_$AppDatabase, $TenantSettingsTable, TenantSetting>
    ),
    TenantSetting,
    PrefetchHooks Function()> {
  $$TenantSettingsTableTableManager(
      _$AppDatabase db, $TenantSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TenantSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TenantSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TenantSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> tenantId = const Value.absent(),
            Value<String> signupMode = const Value.absent(),
            Value<bool> requireMfaForAdmins = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TenantSettingsCompanion(
            tenantId: tenantId,
            signupMode: signupMode,
            requireMfaForAdmins: requireMfaForAdmins,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String tenantId,
            required String signupMode,
            Value<bool> requireMfaForAdmins = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TenantSettingsCompanion.insert(
            tenantId: tenantId,
            signupMode: signupMode,
            requireMfaForAdmins: requireMfaForAdmins,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TenantSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TenantSettingsTable,
    TenantSetting,
    $$TenantSettingsTableFilterComposer,
    $$TenantSettingsTableOrderingComposer,
    $$TenantSettingsTableAnnotationComposer,
    $$TenantSettingsTableCreateCompanionBuilder,
    $$TenantSettingsTableUpdateCompanionBuilder,
    (
      TenantSetting,
      BaseReferences<_$AppDatabase, $TenantSettingsTable, TenantSetting>
    ),
    TenantSetting,
    PrefetchHooks Function()>;
typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String email,
  required String passwordHash,
  Value<DateTime?> emailVerifiedAt,
  Value<DateTime?> disabledAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> email,
  Value<String> passwordHash,
  Value<DateTime?> emailVerifiedAt,
  Value<DateTime?> disabledAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get emailVerifiedAt => $composableBuilder(
      column: $table.emailVerifiedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get disabledAt => $composableBuilder(
      column: $table.disabledAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get emailVerifiedAt => $composableBuilder(
      column: $table.emailVerifiedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get disabledAt => $composableBuilder(
      column: $table.disabledAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => column);

  GeneratedColumn<DateTime> get emailVerifiedAt => $composableBuilder(
      column: $table.emailVerifiedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get disabledAt => $composableBuilder(
      column: $table.disabledAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<DateTime?> emailVerifiedAt = const Value.absent(),
            Value<DateTime?> disabledAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            email: email,
            passwordHash: passwordHash,
            emailVerifiedAt: emailVerifiedAt,
            disabledAt: disabledAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String email,
            required String passwordHash,
            Value<DateTime?> emailVerifiedAt = const Value.absent(),
            Value<DateTime?> disabledAt = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            email: email,
            passwordHash: passwordHash,
            emailVerifiedAt: emailVerifiedAt,
            disabledAt: disabledAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;
typedef $$MembershipsTableCreateCompanionBuilder = MembershipsCompanion
    Function({
  required String tenantId,
  required String userId,
  required String role,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$MembershipsTableUpdateCompanionBuilder = MembershipsCompanion
    Function({
  Value<String> tenantId,
  Value<String> userId,
  Value<String> role,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$MembershipsTableFilterComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$MembershipsTableOrderingComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MembershipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MembershipsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MembershipsTable,
    Membership,
    $$MembershipsTableFilterComposer,
    $$MembershipsTableOrderingComposer,
    $$MembershipsTableAnnotationComposer,
    $$MembershipsTableCreateCompanionBuilder,
    $$MembershipsTableUpdateCompanionBuilder,
    (Membership, BaseReferences<_$AppDatabase, $MembershipsTable, Membership>),
    Membership,
    PrefetchHooks Function()> {
  $$MembershipsTableTableManager(_$AppDatabase db, $MembershipsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembershipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembershipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembershipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> tenantId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MembershipsCompanion(
            tenantId: tenantId,
            userId: userId,
            role: role,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String tenantId,
            required String userId,
            required String role,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              MembershipsCompanion.insert(
            tenantId: tenantId,
            userId: userId,
            role: role,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MembershipsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MembershipsTable,
    Membership,
    $$MembershipsTableFilterComposer,
    $$MembershipsTableOrderingComposer,
    $$MembershipsTableAnnotationComposer,
    $$MembershipsTableCreateCompanionBuilder,
    $$MembershipsTableUpdateCompanionBuilder,
    (Membership, BaseReferences<_$AppDatabase, $MembershipsTable, Membership>),
    Membership,
    PrefetchHooks Function()>;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required String userId,
  Value<String?> activeTenantId,
  Value<bool> mfaVerified,
  Value<DateTime?> recentAuthAt,
  required String csrfSecret,
  required DateTime createdAt,
  required DateTime lastSeenAt,
  required DateTime expiresAt,
  Value<String?> ip,
  Value<String?> userAgent,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> activeTenantId,
  Value<bool> mfaVerified,
  Value<DateTime?> recentAuthAt,
  Value<String> csrfSecret,
  Value<DateTime> createdAt,
  Value<DateTime> lastSeenAt,
  Value<DateTime> expiresAt,
  Value<String?> ip,
  Value<String?> userAgent,
  Value<int> rowid,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activeTenantId => $composableBuilder(
      column: $table.activeTenantId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get mfaVerified => $composableBuilder(
      column: $table.mfaVerified, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recentAuthAt => $composableBuilder(
      column: $table.recentAuthAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get csrfSecret => $composableBuilder(
      column: $table.csrfSecret, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ip => $composableBuilder(
      column: $table.ip, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userAgent => $composableBuilder(
      column: $table.userAgent, builder: (column) => ColumnFilters(column));
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeTenantId => $composableBuilder(
      column: $table.activeTenantId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get mfaVerified => $composableBuilder(
      column: $table.mfaVerified, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recentAuthAt => $composableBuilder(
      column: $table.recentAuthAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get csrfSecret => $composableBuilder(
      column: $table.csrfSecret, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ip => $composableBuilder(
      column: $table.ip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userAgent => $composableBuilder(
      column: $table.userAgent, builder: (column) => ColumnOrderings(column));
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get activeTenantId => $composableBuilder(
      column: $table.activeTenantId, builder: (column) => column);

  GeneratedColumn<bool> get mfaVerified => $composableBuilder(
      column: $table.mfaVerified, builder: (column) => column);

  GeneratedColumn<DateTime> get recentAuthAt => $composableBuilder(
      column: $table.recentAuthAt, builder: (column) => column);

  GeneratedColumn<String> get csrfSecret => $composableBuilder(
      column: $table.csrfSecret, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
      column: $table.lastSeenAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get ip =>
      $composableBuilder(column: $table.ip, builder: (column) => column);

  GeneratedColumn<String> get userAgent =>
      $composableBuilder(column: $table.userAgent, builder: (column) => column);
}

class $$SessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
    Session,
    PrefetchHooks Function()> {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> activeTenantId = const Value.absent(),
            Value<bool> mfaVerified = const Value.absent(),
            Value<DateTime?> recentAuthAt = const Value.absent(),
            Value<String> csrfSecret = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastSeenAt = const Value.absent(),
            Value<DateTime> expiresAt = const Value.absent(),
            Value<String?> ip = const Value.absent(),
            Value<String?> userAgent = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            userId: userId,
            activeTenantId: activeTenantId,
            mfaVerified: mfaVerified,
            recentAuthAt: recentAuthAt,
            csrfSecret: csrfSecret,
            createdAt: createdAt,
            lastSeenAt: lastSeenAt,
            expiresAt: expiresAt,
            ip: ip,
            userAgent: userAgent,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> activeTenantId = const Value.absent(),
            Value<bool> mfaVerified = const Value.absent(),
            Value<DateTime?> recentAuthAt = const Value.absent(),
            required String csrfSecret,
            required DateTime createdAt,
            required DateTime lastSeenAt,
            required DateTime expiresAt,
            Value<String?> ip = const Value.absent(),
            Value<String?> userAgent = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            id: id,
            userId: userId,
            activeTenantId: activeTenantId,
            mfaVerified: mfaVerified,
            recentAuthAt: recentAuthAt,
            csrfSecret: csrfSecret,
            createdAt: createdAt,
            lastSeenAt: lastSeenAt,
            expiresAt: expiresAt,
            ip: ip,
            userAgent: userAgent,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
    Session,
    PrefetchHooks Function()>;
typedef $$TotpCredentialsTableCreateCompanionBuilder = TotpCredentialsCompanion
    Function({
  required String userId,
  Value<int> keyVersion,
  required Uint8List secretNonce,
  required Uint8List secretCiphertext,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> enabledAt,
  Value<int> rowid,
});
typedef $$TotpCredentialsTableUpdateCompanionBuilder = TotpCredentialsCompanion
    Function({
  Value<String> userId,
  Value<int> keyVersion,
  Value<Uint8List> secretNonce,
  Value<Uint8List> secretCiphertext,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> enabledAt,
  Value<int> rowid,
});

class $$TotpCredentialsTableFilterComposer
    extends Composer<_$AppDatabase, $TotpCredentialsTable> {
  $$TotpCredentialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get keyVersion => $composableBuilder(
      column: $table.keyVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get secretNonce => $composableBuilder(
      column: $table.secretNonce, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get secretCiphertext => $composableBuilder(
      column: $table.secretCiphertext,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get enabledAt => $composableBuilder(
      column: $table.enabledAt, builder: (column) => ColumnFilters(column));
}

class $$TotpCredentialsTableOrderingComposer
    extends Composer<_$AppDatabase, $TotpCredentialsTable> {
  $$TotpCredentialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get keyVersion => $composableBuilder(
      column: $table.keyVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get secretNonce => $composableBuilder(
      column: $table.secretNonce, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get secretCiphertext => $composableBuilder(
      column: $table.secretCiphertext,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get enabledAt => $composableBuilder(
      column: $table.enabledAt, builder: (column) => ColumnOrderings(column));
}

class $$TotpCredentialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TotpCredentialsTable> {
  $$TotpCredentialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get keyVersion => $composableBuilder(
      column: $table.keyVersion, builder: (column) => column);

  GeneratedColumn<Uint8List> get secretNonce => $composableBuilder(
      column: $table.secretNonce, builder: (column) => column);

  GeneratedColumn<Uint8List> get secretCiphertext => $composableBuilder(
      column: $table.secretCiphertext, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get enabledAt =>
      $composableBuilder(column: $table.enabledAt, builder: (column) => column);
}

class $$TotpCredentialsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TotpCredentialsTable,
    TotpCredential,
    $$TotpCredentialsTableFilterComposer,
    $$TotpCredentialsTableOrderingComposer,
    $$TotpCredentialsTableAnnotationComposer,
    $$TotpCredentialsTableCreateCompanionBuilder,
    $$TotpCredentialsTableUpdateCompanionBuilder,
    (
      TotpCredential,
      BaseReferences<_$AppDatabase, $TotpCredentialsTable, TotpCredential>
    ),
    TotpCredential,
    PrefetchHooks Function()> {
  $$TotpCredentialsTableTableManager(
      _$AppDatabase db, $TotpCredentialsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TotpCredentialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TotpCredentialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TotpCredentialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<int> keyVersion = const Value.absent(),
            Value<Uint8List> secretNonce = const Value.absent(),
            Value<Uint8List> secretCiphertext = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> enabledAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TotpCredentialsCompanion(
            userId: userId,
            keyVersion: keyVersion,
            secretNonce: secretNonce,
            secretCiphertext: secretCiphertext,
            createdAt: createdAt,
            updatedAt: updatedAt,
            enabledAt: enabledAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            Value<int> keyVersion = const Value.absent(),
            required Uint8List secretNonce,
            required Uint8List secretCiphertext,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> enabledAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TotpCredentialsCompanion.insert(
            userId: userId,
            keyVersion: keyVersion,
            secretNonce: secretNonce,
            secretCiphertext: secretCiphertext,
            createdAt: createdAt,
            updatedAt: updatedAt,
            enabledAt: enabledAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TotpCredentialsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TotpCredentialsTable,
    TotpCredential,
    $$TotpCredentialsTableFilterComposer,
    $$TotpCredentialsTableOrderingComposer,
    $$TotpCredentialsTableAnnotationComposer,
    $$TotpCredentialsTableCreateCompanionBuilder,
    $$TotpCredentialsTableUpdateCompanionBuilder,
    (
      TotpCredential,
      BaseReferences<_$AppDatabase, $TotpCredentialsTable, TotpCredential>
    ),
    TotpCredential,
    PrefetchHooks Function()>;
typedef $$RecoveryCodesTableCreateCompanionBuilder = RecoveryCodesCompanion
    Function({
  required String id,
  required String userId,
  required String codeHash,
  required DateTime createdAt,
  Value<DateTime?> usedAt,
  Value<int> rowid,
});
typedef $$RecoveryCodesTableUpdateCompanionBuilder = RecoveryCodesCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> codeHash,
  Value<DateTime> createdAt,
  Value<DateTime?> usedAt,
  Value<int> rowid,
});

class $$RecoveryCodesTableFilterComposer
    extends Composer<_$AppDatabase, $RecoveryCodesTable> {
  $$RecoveryCodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codeHash => $composableBuilder(
      column: $table.codeHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get usedAt => $composableBuilder(
      column: $table.usedAt, builder: (column) => ColumnFilters(column));
}

class $$RecoveryCodesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecoveryCodesTable> {
  $$RecoveryCodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codeHash => $composableBuilder(
      column: $table.codeHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get usedAt => $composableBuilder(
      column: $table.usedAt, builder: (column) => ColumnOrderings(column));
}

class $$RecoveryCodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecoveryCodesTable> {
  $$RecoveryCodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get codeHash =>
      $composableBuilder(column: $table.codeHash, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);
}

class $$RecoveryCodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecoveryCodesTable,
    RecoveryCode,
    $$RecoveryCodesTableFilterComposer,
    $$RecoveryCodesTableOrderingComposer,
    $$RecoveryCodesTableAnnotationComposer,
    $$RecoveryCodesTableCreateCompanionBuilder,
    $$RecoveryCodesTableUpdateCompanionBuilder,
    (
      RecoveryCode,
      BaseReferences<_$AppDatabase, $RecoveryCodesTable, RecoveryCode>
    ),
    RecoveryCode,
    PrefetchHooks Function()> {
  $$RecoveryCodesTableTableManager(_$AppDatabase db, $RecoveryCodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecoveryCodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecoveryCodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecoveryCodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> codeHash = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> usedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecoveryCodesCompanion(
            id: id,
            userId: userId,
            codeHash: codeHash,
            createdAt: createdAt,
            usedAt: usedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String codeHash,
            required DateTime createdAt,
            Value<DateTime?> usedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecoveryCodesCompanion.insert(
            id: id,
            userId: userId,
            codeHash: codeHash,
            createdAt: createdAt,
            usedAt: usedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecoveryCodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecoveryCodesTable,
    RecoveryCode,
    $$RecoveryCodesTableFilterComposer,
    $$RecoveryCodesTableOrderingComposer,
    $$RecoveryCodesTableAnnotationComposer,
    $$RecoveryCodesTableCreateCompanionBuilder,
    $$RecoveryCodesTableUpdateCompanionBuilder,
    (
      RecoveryCode,
      BaseReferences<_$AppDatabase, $RecoveryCodesTable, RecoveryCode>
    ),
    RecoveryCode,
    PrefetchHooks Function()>;
typedef $$InvitesTableCreateCompanionBuilder = InvitesCompanion Function({
  required String id,
  required String tenantId,
  required String email,
  required String role,
  required String tokenHash,
  required DateTime expiresAt,
  Value<DateTime?> acceptedAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$InvitesTableUpdateCompanionBuilder = InvitesCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> email,
  Value<String> role,
  Value<String> tokenHash,
  Value<DateTime> expiresAt,
  Value<DateTime?> acceptedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$InvitesTableFilterComposer
    extends Composer<_$AppDatabase, $InvitesTable> {
  $$InvitesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tokenHash => $composableBuilder(
      column: $table.tokenHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get acceptedAt => $composableBuilder(
      column: $table.acceptedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$InvitesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvitesTable> {
  $$InvitesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tokenHash => $composableBuilder(
      column: $table.tokenHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get acceptedAt => $composableBuilder(
      column: $table.acceptedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$InvitesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvitesTable> {
  $$InvitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get tokenHash =>
      $composableBuilder(column: $table.tokenHash, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get acceptedAt => $composableBuilder(
      column: $table.acceptedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$InvitesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InvitesTable,
    Invite,
    $$InvitesTableFilterComposer,
    $$InvitesTableOrderingComposer,
    $$InvitesTableAnnotationComposer,
    $$InvitesTableCreateCompanionBuilder,
    $$InvitesTableUpdateCompanionBuilder,
    (Invite, BaseReferences<_$AppDatabase, $InvitesTable, Invite>),
    Invite,
    PrefetchHooks Function()> {
  $$InvitesTableTableManager(_$AppDatabase db, $InvitesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvitesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvitesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> tokenHash = const Value.absent(),
            Value<DateTime> expiresAt = const Value.absent(),
            Value<DateTime?> acceptedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvitesCompanion(
            id: id,
            tenantId: tenantId,
            email: email,
            role: role,
            tokenHash: tokenHash,
            expiresAt: expiresAt,
            acceptedAt: acceptedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            required String email,
            required String role,
            required String tokenHash,
            required DateTime expiresAt,
            Value<DateTime?> acceptedAt = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              InvitesCompanion.insert(
            id: id,
            tenantId: tenantId,
            email: email,
            role: role,
            tokenHash: tokenHash,
            expiresAt: expiresAt,
            acceptedAt: acceptedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InvitesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InvitesTable,
    Invite,
    $$InvitesTableFilterComposer,
    $$InvitesTableOrderingComposer,
    $$InvitesTableAnnotationComposer,
    $$InvitesTableCreateCompanionBuilder,
    $$InvitesTableUpdateCompanionBuilder,
    (Invite, BaseReferences<_$AppDatabase, $InvitesTable, Invite>),
    Invite,
    PrefetchHooks Function()>;
typedef $$AuditLogsTableCreateCompanionBuilder = AuditLogsCompanion Function({
  required String id,
  Value<String?> tenantId,
  Value<String?> actorUserId,
  required String action,
  Value<String?> target,
  Value<String?> metadataJson,
  Value<String?> ip,
  Value<String?> userAgent,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AuditLogsTableUpdateCompanionBuilder = AuditLogsCompanion Function({
  Value<String> id,
  Value<String?> tenantId,
  Value<String?> actorUserId,
  Value<String> action,
  Value<String?> target,
  Value<String?> metadataJson,
  Value<String?> ip,
  Value<String?> userAgent,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$AuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actorUserId => $composableBuilder(
      column: $table.actorUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get target => $composableBuilder(
      column: $table.target, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ip => $composableBuilder(
      column: $table.ip, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userAgent => $composableBuilder(
      column: $table.userAgent, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actorUserId => $composableBuilder(
      column: $table.actorUserId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get target => $composableBuilder(
      column: $table.target, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ip => $composableBuilder(
      column: $table.ip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userAgent => $composableBuilder(
      column: $table.userAgent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get actorUserId => $composableBuilder(
      column: $table.actorUserId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => column);

  GeneratedColumn<String> get ip =>
      $composableBuilder(column: $table.ip, builder: (column) => column);

  GeneratedColumn<String> get userAgent =>
      $composableBuilder(column: $table.userAgent, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AuditLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AuditLogsTable,
    AuditLog,
    $$AuditLogsTableFilterComposer,
    $$AuditLogsTableOrderingComposer,
    $$AuditLogsTableAnnotationComposer,
    $$AuditLogsTableCreateCompanionBuilder,
    $$AuditLogsTableUpdateCompanionBuilder,
    (AuditLog, BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog>),
    AuditLog,
    PrefetchHooks Function()> {
  $$AuditLogsTableTableManager(_$AppDatabase db, $AuditLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> tenantId = const Value.absent(),
            Value<String?> actorUserId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String?> target = const Value.absent(),
            Value<String?> metadataJson = const Value.absent(),
            Value<String?> ip = const Value.absent(),
            Value<String?> userAgent = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AuditLogsCompanion(
            id: id,
            tenantId: tenantId,
            actorUserId: actorUserId,
            action: action,
            target: target,
            metadataJson: metadataJson,
            ip: ip,
            userAgent: userAgent,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> tenantId = const Value.absent(),
            Value<String?> actorUserId = const Value.absent(),
            required String action,
            Value<String?> target = const Value.absent(),
            Value<String?> metadataJson = const Value.absent(),
            Value<String?> ip = const Value.absent(),
            Value<String?> userAgent = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AuditLogsCompanion.insert(
            id: id,
            tenantId: tenantId,
            actorUserId: actorUserId,
            action: action,
            target: target,
            metadataJson: metadataJson,
            ip: ip,
            userAgent: userAgent,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AuditLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AuditLogsTable,
    AuditLog,
    $$AuditLogsTableFilterComposer,
    $$AuditLogsTableOrderingComposer,
    $$AuditLogsTableAnnotationComposer,
    $$AuditLogsTableCreateCompanionBuilder,
    $$AuditLogsTableUpdateCompanionBuilder,
    (AuditLog, BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog>),
    AuditLog,
    PrefetchHooks Function()>;
typedef $$PasswordResetTokensTableCreateCompanionBuilder
    = PasswordResetTokensCompanion Function({
  required String id,
  required String userId,
  required String tokenHash,
  required DateTime expiresAt,
  Value<DateTime?> usedAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PasswordResetTokensTableUpdateCompanionBuilder
    = PasswordResetTokensCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> tokenHash,
  Value<DateTime> expiresAt,
  Value<DateTime?> usedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PasswordResetTokensTableFilterComposer
    extends Composer<_$AppDatabase, $PasswordResetTokensTable> {
  $$PasswordResetTokensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tokenHash => $composableBuilder(
      column: $table.tokenHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get usedAt => $composableBuilder(
      column: $table.usedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PasswordResetTokensTableOrderingComposer
    extends Composer<_$AppDatabase, $PasswordResetTokensTable> {
  $$PasswordResetTokensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tokenHash => $composableBuilder(
      column: $table.tokenHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get usedAt => $composableBuilder(
      column: $table.usedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PasswordResetTokensTableAnnotationComposer
    extends Composer<_$AppDatabase, $PasswordResetTokensTable> {
  $$PasswordResetTokensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get tokenHash =>
      $composableBuilder(column: $table.tokenHash, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PasswordResetTokensTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PasswordResetTokensTable,
    PasswordResetToken,
    $$PasswordResetTokensTableFilterComposer,
    $$PasswordResetTokensTableOrderingComposer,
    $$PasswordResetTokensTableAnnotationComposer,
    $$PasswordResetTokensTableCreateCompanionBuilder,
    $$PasswordResetTokensTableUpdateCompanionBuilder,
    (
      PasswordResetToken,
      BaseReferences<_$AppDatabase, $PasswordResetTokensTable,
          PasswordResetToken>
    ),
    PasswordResetToken,
    PrefetchHooks Function()> {
  $$PasswordResetTokensTableTableManager(
      _$AppDatabase db, $PasswordResetTokensTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PasswordResetTokensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PasswordResetTokensTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PasswordResetTokensTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> tokenHash = const Value.absent(),
            Value<DateTime> expiresAt = const Value.absent(),
            Value<DateTime?> usedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PasswordResetTokensCompanion(
            id: id,
            userId: userId,
            tokenHash: tokenHash,
            expiresAt: expiresAt,
            usedAt: usedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String tokenHash,
            required DateTime expiresAt,
            Value<DateTime?> usedAt = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PasswordResetTokensCompanion.insert(
            id: id,
            userId: userId,
            tokenHash: tokenHash,
            expiresAt: expiresAt,
            usedAt: usedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PasswordResetTokensTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PasswordResetTokensTable,
    PasswordResetToken,
    $$PasswordResetTokensTableFilterComposer,
    $$PasswordResetTokensTableOrderingComposer,
    $$PasswordResetTokensTableAnnotationComposer,
    $$PasswordResetTokensTableCreateCompanionBuilder,
    $$PasswordResetTokensTableUpdateCompanionBuilder,
    (
      PasswordResetToken,
      BaseReferences<_$AppDatabase, $PasswordResetTokensTable,
          PasswordResetToken>
    ),
    PasswordResetToken,
    PrefetchHooks Function()>;
typedef $$EmailVerificationTokensTableCreateCompanionBuilder
    = EmailVerificationTokensCompanion Function({
  required String id,
  required String userId,
  required String tokenHash,
  required DateTime expiresAt,
  Value<DateTime?> usedAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$EmailVerificationTokensTableUpdateCompanionBuilder
    = EmailVerificationTokensCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> tokenHash,
  Value<DateTime> expiresAt,
  Value<DateTime?> usedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$EmailVerificationTokensTableFilterComposer
    extends Composer<_$AppDatabase, $EmailVerificationTokensTable> {
  $$EmailVerificationTokensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tokenHash => $composableBuilder(
      column: $table.tokenHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get usedAt => $composableBuilder(
      column: $table.usedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$EmailVerificationTokensTableOrderingComposer
    extends Composer<_$AppDatabase, $EmailVerificationTokensTable> {
  $$EmailVerificationTokensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tokenHash => $composableBuilder(
      column: $table.tokenHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get usedAt => $composableBuilder(
      column: $table.usedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$EmailVerificationTokensTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmailVerificationTokensTable> {
  $$EmailVerificationTokensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get tokenHash =>
      $composableBuilder(column: $table.tokenHash, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EmailVerificationTokensTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmailVerificationTokensTable,
    EmailVerificationToken,
    $$EmailVerificationTokensTableFilterComposer,
    $$EmailVerificationTokensTableOrderingComposer,
    $$EmailVerificationTokensTableAnnotationComposer,
    $$EmailVerificationTokensTableCreateCompanionBuilder,
    $$EmailVerificationTokensTableUpdateCompanionBuilder,
    (
      EmailVerificationToken,
      BaseReferences<_$AppDatabase, $EmailVerificationTokensTable,
          EmailVerificationToken>
    ),
    EmailVerificationToken,
    PrefetchHooks Function()> {
  $$EmailVerificationTokensTableTableManager(
      _$AppDatabase db, $EmailVerificationTokensTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmailVerificationTokensTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$EmailVerificationTokensTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmailVerificationTokensTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> tokenHash = const Value.absent(),
            Value<DateTime> expiresAt = const Value.absent(),
            Value<DateTime?> usedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmailVerificationTokensCompanion(
            id: id,
            userId: userId,
            tokenHash: tokenHash,
            expiresAt: expiresAt,
            usedAt: usedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String tokenHash,
            required DateTime expiresAt,
            Value<DateTime?> usedAt = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              EmailVerificationTokensCompanion.insert(
            id: id,
            userId: userId,
            tokenHash: tokenHash,
            expiresAt: expiresAt,
            usedAt: usedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EmailVerificationTokensTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $EmailVerificationTokensTable,
        EmailVerificationToken,
        $$EmailVerificationTokensTableFilterComposer,
        $$EmailVerificationTokensTableOrderingComposer,
        $$EmailVerificationTokensTableAnnotationComposer,
        $$EmailVerificationTokensTableCreateCompanionBuilder,
        $$EmailVerificationTokensTableUpdateCompanionBuilder,
        (
          EmailVerificationToken,
          BaseReferences<_$AppDatabase, $EmailVerificationTokensTable,
              EmailVerificationToken>
        ),
        EmailVerificationToken,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TenantsTableTableManager get tenants =>
      $$TenantsTableTableManager(_db, _db.tenants);
  $$TenantSettingsTableTableManager get tenantSettings =>
      $$TenantSettingsTableTableManager(_db, _db.tenantSettings);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$MembershipsTableTableManager get memberships =>
      $$MembershipsTableTableManager(_db, _db.memberships);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$TotpCredentialsTableTableManager get totpCredentials =>
      $$TotpCredentialsTableTableManager(_db, _db.totpCredentials);
  $$RecoveryCodesTableTableManager get recoveryCodes =>
      $$RecoveryCodesTableTableManager(_db, _db.recoveryCodes);
  $$InvitesTableTableManager get invites =>
      $$InvitesTableTableManager(_db, _db.invites);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db, _db.auditLogs);
  $$PasswordResetTokensTableTableManager get passwordResetTokens =>
      $$PasswordResetTokensTableTableManager(_db, _db.passwordResetTokens);
  $$EmailVerificationTokensTableTableManager get emailVerificationTokens =>
      $$EmailVerificationTokensTableTableManager(
          _db, _db.emailVerificationTokens);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedRecordsTable extends CachedRecords
    with TableInfo<$CachedRecordsTable, CachedRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
      'module', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityVersionMeta =
      const VerificationMeta('entityVersion');
  @override
  late final GeneratedColumn<String> entityVersion = GeneratedColumn<String>(
      'entity_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deltaTokenMeta =
      const VerificationMeta('deltaToken');
  @override
  late final GeneratedColumn<String> deltaToken = GeneratedColumn<String>(
      'delta_token', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
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
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        module,
        cacheKey,
        payload,
        entityVersion,
        deltaToken,
        isDeleted,
        createdAt,
        updatedAt,
        lastSyncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_records';
  @override
  VerificationContext validateIntegrity(Insertable<CachedRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('module')) {
      context.handle(_moduleMeta,
          module.isAcceptableOrUnknown(data['module']!, _moduleMeta));
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('entity_version')) {
      context.handle(
          _entityVersionMeta,
          entityVersion.isAcceptableOrUnknown(
              data['entity_version']!, _entityVersionMeta));
    }
    if (data.containsKey('delta_token')) {
      context.handle(
          _deltaTokenMeta,
          deltaToken.isAcceptableOrUnknown(
              data['delta_token']!, _deltaTokenMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
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
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {module, cacheKey},
      ];
  @override
  CachedRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      module: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}module'])!,
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      entityVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_version']),
      deltaToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}delta_token']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
    );
  }

  @override
  $CachedRecordsTable createAlias(String alias) {
    return $CachedRecordsTable(attachedDatabase, alias);
  }
}

class CachedRecord extends DataClass implements Insertable<CachedRecord> {
  final int id;
  final String module;
  final String cacheKey;
  final String payload;
  final String? entityVersion;
  final String? deltaToken;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  const CachedRecord(
      {required this.id,
      required this.module,
      required this.cacheKey,
      required this.payload,
      this.entityVersion,
      this.deltaToken,
      required this.isDeleted,
      required this.createdAt,
      required this.updatedAt,
      this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['module'] = Variable<String>(module);
    map['cache_key'] = Variable<String>(cacheKey);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || entityVersion != null) {
      map['entity_version'] = Variable<String>(entityVersion);
    }
    if (!nullToAbsent || deltaToken != null) {
      map['delta_token'] = Variable<String>(deltaToken);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  CachedRecordsCompanion toCompanion(bool nullToAbsent) {
    return CachedRecordsCompanion(
      id: Value(id),
      module: Value(module),
      cacheKey: Value(cacheKey),
      payload: Value(payload),
      entityVersion: entityVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(entityVersion),
      deltaToken: deltaToken == null && nullToAbsent
          ? const Value.absent()
          : Value(deltaToken),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory CachedRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRecord(
      id: serializer.fromJson<int>(json['id']),
      module: serializer.fromJson<String>(json['module']),
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      payload: serializer.fromJson<String>(json['payload']),
      entityVersion: serializer.fromJson<String?>(json['entityVersion']),
      deltaToken: serializer.fromJson<String?>(json['deltaToken']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'module': serializer.toJson<String>(module),
      'cacheKey': serializer.toJson<String>(cacheKey),
      'payload': serializer.toJson<String>(payload),
      'entityVersion': serializer.toJson<String?>(entityVersion),
      'deltaToken': serializer.toJson<String?>(deltaToken),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  CachedRecord copyWith(
          {int? id,
          String? module,
          String? cacheKey,
          String? payload,
          Value<String?> entityVersion = const Value.absent(),
          Value<String?> deltaToken = const Value.absent(),
          bool? isDeleted,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> lastSyncedAt = const Value.absent()}) =>
      CachedRecord(
        id: id ?? this.id,
        module: module ?? this.module,
        cacheKey: cacheKey ?? this.cacheKey,
        payload: payload ?? this.payload,
        entityVersion:
            entityVersion.present ? entityVersion.value : this.entityVersion,
        deltaToken: deltaToken.present ? deltaToken.value : this.deltaToken,
        isDeleted: isDeleted ?? this.isDeleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
      );
  CachedRecord copyWithCompanion(CachedRecordsCompanion data) {
    return CachedRecord(
      id: data.id.present ? data.id.value : this.id,
      module: data.module.present ? data.module.value : this.module,
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      payload: data.payload.present ? data.payload.value : this.payload,
      entityVersion: data.entityVersion.present
          ? data.entityVersion.value
          : this.entityVersion,
      deltaToken:
          data.deltaToken.present ? data.deltaToken.value : this.deltaToken,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRecord(')
          ..write('id: $id, ')
          ..write('module: $module, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('payload: $payload, ')
          ..write('entityVersion: $entityVersion, ')
          ..write('deltaToken: $deltaToken, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, module, cacheKey, payload, entityVersion,
      deltaToken, isDeleted, createdAt, updatedAt, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRecord &&
          other.id == this.id &&
          other.module == this.module &&
          other.cacheKey == this.cacheKey &&
          other.payload == this.payload &&
          other.entityVersion == this.entityVersion &&
          other.deltaToken == this.deltaToken &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CachedRecordsCompanion extends UpdateCompanion<CachedRecord> {
  final Value<int> id;
  final Value<String> module;
  final Value<String> cacheKey;
  final Value<String> payload;
  final Value<String?> entityVersion;
  final Value<String?> deltaToken;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  const CachedRecordsCompanion({
    this.id = const Value.absent(),
    this.module = const Value.absent(),
    this.cacheKey = const Value.absent(),
    this.payload = const Value.absent(),
    this.entityVersion = const Value.absent(),
    this.deltaToken = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
  });
  CachedRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String module,
    required String cacheKey,
    required String payload,
    this.entityVersion = const Value.absent(),
    this.deltaToken = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastSyncedAt = const Value.absent(),
  })  : module = Value(module),
        cacheKey = Value(cacheKey),
        payload = Value(payload),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CachedRecord> custom({
    Expression<int>? id,
    Expression<String>? module,
    Expression<String>? cacheKey,
    Expression<String>? payload,
    Expression<String>? entityVersion,
    Expression<String>? deltaToken,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (module != null) 'module': module,
      if (cacheKey != null) 'cache_key': cacheKey,
      if (payload != null) 'payload': payload,
      if (entityVersion != null) 'entity_version': entityVersion,
      if (deltaToken != null) 'delta_token': deltaToken,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
    });
  }

  CachedRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? module,
      Value<String>? cacheKey,
      Value<String>? payload,
      Value<String?>? entityVersion,
      Value<String?>? deltaToken,
      Value<bool>? isDeleted,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastSyncedAt}) {
    return CachedRecordsCompanion(
      id: id ?? this.id,
      module: module ?? this.module,
      cacheKey: cacheKey ?? this.cacheKey,
      payload: payload ?? this.payload,
      entityVersion: entityVersion ?? this.entityVersion,
      deltaToken: deltaToken ?? this.deltaToken,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (entityVersion.present) {
      map['entity_version'] = Variable<String>(entityVersion.value);
    }
    if (deltaToken.present) {
      map['delta_token'] = Variable<String>(deltaToken.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRecordsCompanion(')
          ..write('id: $id, ')
          ..write('module: $module, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('payload: $payload, ')
          ..write('entityVersion: $entityVersion, ')
          ..write('deltaToken: $deltaToken, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
      'module', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
      'scope', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deltaTokenMeta =
      const VerificationMeta('deltaToken');
  @override
  late final GeneratedColumn<String> deltaToken = GeneratedColumn<String>(
      'delta_token', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sinceMessageIdMeta =
      const VerificationMeta('sinceMessageId');
  @override
  late final GeneratedColumn<int> sinceMessageId = GeneratedColumn<int>(
      'since_message_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _entityVersionMeta =
      const VerificationMeta('entityVersion');
  @override
  late final GeneratedColumn<String> entityVersion = GeneratedColumn<String>(
      'entity_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        module,
        scope,
        deltaToken,
        sinceMessageId,
        entityVersion,
        lastSyncedAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_states';
  @override
  VerificationContext validateIntegrity(Insertable<SyncState> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('module')) {
      context.handle(_moduleMeta,
          module.isAcceptableOrUnknown(data['module']!, _moduleMeta));
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
          _scopeMeta, scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta));
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('delta_token')) {
      context.handle(
          _deltaTokenMeta,
          deltaToken.isAcceptableOrUnknown(
              data['delta_token']!, _deltaTokenMeta));
    }
    if (data.containsKey('since_message_id')) {
      context.handle(
          _sinceMessageIdMeta,
          sinceMessageId.isAcceptableOrUnknown(
              data['since_message_id']!, _sinceMessageIdMeta));
    }
    if (data.containsKey('entity_version')) {
      context.handle(
          _entityVersionMeta,
          entityVersion.isAcceptableOrUnknown(
              data['entity_version']!, _entityVersionMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {module, scope},
      ];
  @override
  SyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncState(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      module: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}module'])!,
      scope: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope'])!,
      deltaToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}delta_token']),
      sinceMessageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}since_message_id']),
      entityVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_version']),
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncState extends DataClass implements Insertable<SyncState> {
  final int id;
  final String module;
  final String scope;
  final String? deltaToken;
  final int? sinceMessageId;
  final String? entityVersion;
  final DateTime? lastSyncedAt;
  final DateTime updatedAt;
  const SyncState(
      {required this.id,
      required this.module,
      required this.scope,
      this.deltaToken,
      this.sinceMessageId,
      this.entityVersion,
      this.lastSyncedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['module'] = Variable<String>(module);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || deltaToken != null) {
      map['delta_token'] = Variable<String>(deltaToken);
    }
    if (!nullToAbsent || sinceMessageId != null) {
      map['since_message_id'] = Variable<int>(sinceMessageId);
    }
    if (!nullToAbsent || entityVersion != null) {
      map['entity_version'] = Variable<String>(entityVersion);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      id: Value(id),
      module: Value(module),
      scope: Value(scope),
      deltaToken: deltaToken == null && nullToAbsent
          ? const Value.absent()
          : Value(deltaToken),
      sinceMessageId: sinceMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(sinceMessageId),
      entityVersion: entityVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(entityVersion),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncState.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncState(
      id: serializer.fromJson<int>(json['id']),
      module: serializer.fromJson<String>(json['module']),
      scope: serializer.fromJson<String>(json['scope']),
      deltaToken: serializer.fromJson<String?>(json['deltaToken']),
      sinceMessageId: serializer.fromJson<int?>(json['sinceMessageId']),
      entityVersion: serializer.fromJson<String?>(json['entityVersion']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'module': serializer.toJson<String>(module),
      'scope': serializer.toJson<String>(scope),
      'deltaToken': serializer.toJson<String?>(deltaToken),
      'sinceMessageId': serializer.toJson<int?>(sinceMessageId),
      'entityVersion': serializer.toJson<String?>(entityVersion),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncState copyWith(
          {int? id,
          String? module,
          String? scope,
          Value<String?> deltaToken = const Value.absent(),
          Value<int?> sinceMessageId = const Value.absent(),
          Value<String?> entityVersion = const Value.absent(),
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          DateTime? updatedAt}) =>
      SyncState(
        id: id ?? this.id,
        module: module ?? this.module,
        scope: scope ?? this.scope,
        deltaToken: deltaToken.present ? deltaToken.value : this.deltaToken,
        sinceMessageId:
            sinceMessageId.present ? sinceMessageId.value : this.sinceMessageId,
        entityVersion:
            entityVersion.present ? entityVersion.value : this.entityVersion,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncState copyWithCompanion(SyncStatesCompanion data) {
    return SyncState(
      id: data.id.present ? data.id.value : this.id,
      module: data.module.present ? data.module.value : this.module,
      scope: data.scope.present ? data.scope.value : this.scope,
      deltaToken:
          data.deltaToken.present ? data.deltaToken.value : this.deltaToken,
      sinceMessageId: data.sinceMessageId.present
          ? data.sinceMessageId.value
          : this.sinceMessageId,
      entityVersion: data.entityVersion.present
          ? data.entityVersion.value
          : this.entityVersion,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncState(')
          ..write('id: $id, ')
          ..write('module: $module, ')
          ..write('scope: $scope, ')
          ..write('deltaToken: $deltaToken, ')
          ..write('sinceMessageId: $sinceMessageId, ')
          ..write('entityVersion: $entityVersion, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, module, scope, deltaToken, sinceMessageId,
      entityVersion, lastSyncedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncState &&
          other.id == this.id &&
          other.module == this.module &&
          other.scope == this.scope &&
          other.deltaToken == this.deltaToken &&
          other.sinceMessageId == this.sinceMessageId &&
          other.entityVersion == this.entityVersion &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.updatedAt == this.updatedAt);
}

class SyncStatesCompanion extends UpdateCompanion<SyncState> {
  final Value<int> id;
  final Value<String> module;
  final Value<String> scope;
  final Value<String?> deltaToken;
  final Value<int?> sinceMessageId;
  final Value<String?> entityVersion;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> updatedAt;
  const SyncStatesCompanion({
    this.id = const Value.absent(),
    this.module = const Value.absent(),
    this.scope = const Value.absent(),
    this.deltaToken = const Value.absent(),
    this.sinceMessageId = const Value.absent(),
    this.entityVersion = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    this.id = const Value.absent(),
    required String module,
    required String scope,
    this.deltaToken = const Value.absent(),
    this.sinceMessageId = const Value.absent(),
    this.entityVersion = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required DateTime updatedAt,
  })  : module = Value(module),
        scope = Value(scope),
        updatedAt = Value(updatedAt);
  static Insertable<SyncState> custom({
    Expression<int>? id,
    Expression<String>? module,
    Expression<String>? scope,
    Expression<String>? deltaToken,
    Expression<int>? sinceMessageId,
    Expression<String>? entityVersion,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (module != null) 'module': module,
      if (scope != null) 'scope': scope,
      if (deltaToken != null) 'delta_token': deltaToken,
      if (sinceMessageId != null) 'since_message_id': sinceMessageId,
      if (entityVersion != null) 'entity_version': entityVersion,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncStatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? module,
      Value<String>? scope,
      Value<String?>? deltaToken,
      Value<int?>? sinceMessageId,
      Value<String?>? entityVersion,
      Value<DateTime?>? lastSyncedAt,
      Value<DateTime>? updatedAt}) {
    return SyncStatesCompanion(
      id: id ?? this.id,
      module: module ?? this.module,
      scope: scope ?? this.scope,
      deltaToken: deltaToken ?? this.deltaToken,
      sinceMessageId: sinceMessageId ?? this.sinceMessageId,
      entityVersion: entityVersion ?? this.entityVersion,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (deltaToken.present) {
      map['delta_token'] = Variable<String>(deltaToken.value);
    }
    if (sinceMessageId.present) {
      map['since_message_id'] = Variable<int>(sinceMessageId.value);
    }
    if (entityVersion.present) {
      map['entity_version'] = Variable<String>(entityVersion.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('id: $id, ')
          ..write('module: $module, ')
          ..write('scope: $scope, ')
          ..write('deltaToken: $deltaToken, ')
          ..write('sinceMessageId: $sinceMessageId, ')
          ..write('entityVersion: $entityVersion, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $OutboxOperationsTable extends OutboxOperations
    with TableInfo<$OutboxOperationsTable, OutboxOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
      'module', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationTypeMeta =
      const VerificationMeta('operationType');
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
      'operation_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>('next_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _conflictPayloadMeta =
      const VerificationMeta('conflictPayload');
  @override
  late final GeneratedColumn<String> conflictPayload = GeneratedColumn<String>(
      'conflict_payload', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _requiresTextOnlyMeta =
      const VerificationMeta('requiresTextOnly');
  @override
  late final GeneratedColumn<bool> requiresTextOnly = GeneratedColumn<bool>(
      'requires_text_only', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("requires_text_only" IN (0, 1))'),
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
  List<GeneratedColumn> get $columns => [
        id,
        module,
        entityType,
        entityId,
        operationType,
        payload,
        idempotencyKey,
        status,
        priority,
        attemptCount,
        nextAttemptAt,
        lastError,
        conflictPayload,
        requiresTextOnly,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_operations';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxOperation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('module')) {
      context.handle(_moduleMeta,
          module.isAcceptableOrUnknown(data['module']!, _moduleMeta));
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
          _operationTypeMeta,
          operationType.isAcceptableOrUnknown(
              data['operation_type']!, _operationTypeMeta));
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('conflict_payload')) {
      context.handle(
          _conflictPayloadMeta,
          conflictPayload.isAcceptableOrUnknown(
              data['conflict_payload']!, _conflictPayloadMeta));
    }
    if (data.containsKey('requires_text_only')) {
      context.handle(
          _requiresTextOnlyMeta,
          requiresTextOnly.isAcceptableOrUnknown(
              data['requires_text_only']!, _requiresTextOnlyMeta));
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxOperation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      module: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}module'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation_type'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      idempotencyKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}idempotency_key'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_attempt_at']),
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      conflictPayload: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conflict_payload']),
      requiresTextOnly: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}requires_text_only'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OutboxOperationsTable createAlias(String alias) {
    return $OutboxOperationsTable(attachedDatabase, alias);
  }
}

class OutboxOperation extends DataClass implements Insertable<OutboxOperation> {
  final String id;
  final String module;
  final String entityType;
  final String entityId;
  final String operationType;
  final String payload;
  final String idempotencyKey;
  final String status;
  final int priority;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final String? conflictPayload;
  final bool requiresTextOnly;
  final DateTime createdAt;
  final DateTime updatedAt;
  const OutboxOperation(
      {required this.id,
      required this.module,
      required this.entityType,
      required this.entityId,
      required this.operationType,
      required this.payload,
      required this.idempotencyKey,
      required this.status,
      required this.priority,
      required this.attemptCount,
      this.nextAttemptAt,
      this.lastError,
      this.conflictPayload,
      required this.requiresTextOnly,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['module'] = Variable<String>(module);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation_type'] = Variable<String>(operationType);
    map['payload'] = Variable<String>(payload);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<int>(priority);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || conflictPayload != null) {
      map['conflict_payload'] = Variable<String>(conflictPayload);
    }
    map['requires_text_only'] = Variable<bool>(requiresTextOnly);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OutboxOperationsCompanion toCompanion(bool nullToAbsent) {
    return OutboxOperationsCompanion(
      id: Value(id),
      module: Value(module),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operationType: Value(operationType),
      payload: Value(payload),
      idempotencyKey: Value(idempotencyKey),
      status: Value(status),
      priority: Value(priority),
      attemptCount: Value(attemptCount),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      conflictPayload: conflictPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictPayload),
      requiresTextOnly: Value(requiresTextOnly),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboxOperation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxOperation(
      id: serializer.fromJson<String>(json['id']),
      module: serializer.fromJson<String>(json['module']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payload: serializer.fromJson<String>(json['payload']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<int>(json['priority']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      conflictPayload: serializer.fromJson<String?>(json['conflictPayload']),
      requiresTextOnly: serializer.fromJson<bool>(json['requiresTextOnly']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'module': serializer.toJson<String>(module),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operationType': serializer.toJson<String>(operationType),
      'payload': serializer.toJson<String>(payload),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<int>(priority),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'conflictPayload': serializer.toJson<String?>(conflictPayload),
      'requiresTextOnly': serializer.toJson<bool>(requiresTextOnly),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OutboxOperation copyWith(
          {String? id,
          String? module,
          String? entityType,
          String? entityId,
          String? operationType,
          String? payload,
          String? idempotencyKey,
          String? status,
          int? priority,
          int? attemptCount,
          Value<DateTime?> nextAttemptAt = const Value.absent(),
          Value<String?> lastError = const Value.absent(),
          Value<String?> conflictPayload = const Value.absent(),
          bool? requiresTextOnly,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      OutboxOperation(
        id: id ?? this.id,
        module: module ?? this.module,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operationType: operationType ?? this.operationType,
        payload: payload ?? this.payload,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        attemptCount: attemptCount ?? this.attemptCount,
        nextAttemptAt:
            nextAttemptAt.present ? nextAttemptAt.value : this.nextAttemptAt,
        lastError: lastError.present ? lastError.value : this.lastError,
        conflictPayload: conflictPayload.present
            ? conflictPayload.value
            : this.conflictPayload,
        requiresTextOnly: requiresTextOnly ?? this.requiresTextOnly,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OutboxOperation copyWithCompanion(OutboxOperationsCompanion data) {
    return OutboxOperation(
      id: data.id.present ? data.id.value : this.id,
      module: data.module.present ? data.module.value : this.module,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payload: data.payload.present ? data.payload.value : this.payload,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      conflictPayload: data.conflictPayload.present
          ? data.conflictPayload.value
          : this.conflictPayload,
      requiresTextOnly: data.requiresTextOnly.present
          ? data.requiresTextOnly.value
          : this.requiresTextOnly,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOperation(')
          ..write('id: $id, ')
          ..write('module: $module, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('conflictPayload: $conflictPayload, ')
          ..write('requiresTextOnly: $requiresTextOnly, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      module,
      entityType,
      entityId,
      operationType,
      payload,
      idempotencyKey,
      status,
      priority,
      attemptCount,
      nextAttemptAt,
      lastError,
      conflictPayload,
      requiresTextOnly,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxOperation &&
          other.id == this.id &&
          other.module == this.module &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operationType == this.operationType &&
          other.payload == this.payload &&
          other.idempotencyKey == this.idempotencyKey &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.conflictPayload == this.conflictPayload &&
          other.requiresTextOnly == this.requiresTextOnly &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OutboxOperationsCompanion extends UpdateCompanion<OutboxOperation> {
  final Value<String> id;
  final Value<String> module;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operationType;
  final Value<String> payload;
  final Value<String> idempotencyKey;
  final Value<String> status;
  final Value<int> priority;
  final Value<int> attemptCount;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<String?> conflictPayload;
  final Value<bool> requiresTextOnly;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OutboxOperationsCompanion({
    this.id = const Value.absent(),
    this.module = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payload = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.conflictPayload = const Value.absent(),
    this.requiresTextOnly = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxOperationsCompanion.insert({
    required String id,
    required String module,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payload,
    required String idempotencyKey,
    required String status,
    required int priority,
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.conflictPayload = const Value.absent(),
    this.requiresTextOnly = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        module = Value(module),
        entityType = Value(entityType),
        entityId = Value(entityId),
        operationType = Value(operationType),
        payload = Value(payload),
        idempotencyKey = Value(idempotencyKey),
        status = Value(status),
        priority = Value(priority),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<OutboxOperation> custom({
    Expression<String>? id,
    Expression<String>? module,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operationType,
    Expression<String>? payload,
    Expression<String>? idempotencyKey,
    Expression<String>? status,
    Expression<int>? priority,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<String>? conflictPayload,
    Expression<bool>? requiresTextOnly,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (module != null) 'module': module,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operationType != null) 'operation_type': operationType,
      if (payload != null) 'payload': payload,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (conflictPayload != null) 'conflict_payload': conflictPayload,
      if (requiresTextOnly != null) 'requires_text_only': requiresTextOnly,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxOperationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? module,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operationType,
      Value<String>? payload,
      Value<String>? idempotencyKey,
      Value<String>? status,
      Value<int>? priority,
      Value<int>? attemptCount,
      Value<DateTime?>? nextAttemptAt,
      Value<String?>? lastError,
      Value<String?>? conflictPayload,
      Value<bool>? requiresTextOnly,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return OutboxOperationsCompanion(
      id: id ?? this.id,
      module: module ?? this.module,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      conflictPayload: conflictPayload ?? this.conflictPayload,
      requiresTextOnly: requiresTextOnly ?? this.requiresTextOnly,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (conflictPayload.present) {
      map['conflict_payload'] = Variable<String>(conflictPayload.value);
    }
    if (requiresTextOnly.present) {
      map['requires_text_only'] = Variable<bool>(requiresTextOnly.value);
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
    return (StringBuffer('OutboxOperationsCompanion(')
          ..write('id: $id, ')
          ..write('module: $module, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('conflictPayload: $conflictPayload, ')
          ..write('requiresTextOnly: $requiresTextOnly, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<int> chatId = GeneratedColumn<int>(
      'chat_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _serverMessageIdMeta =
      const VerificationMeta('serverMessageId');
  @override
  late final GeneratedColumn<int> serverMessageId = GeneratedColumn<int>(
      'server_message_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isOutgoingMeta =
      const VerificationMeta('isOutgoing');
  @override
  late final GeneratedColumn<bool> isOutgoing = GeneratedColumn<bool>(
      'is_outgoing', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_outgoing" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
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
  List<GeneratedColumn> get $columns => [
        localId,
        chatId,
        serverMessageId,
        payload,
        syncStatus,
        isOutgoing,
        isDeleted,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(Insertable<ChatMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('server_message_id')) {
      context.handle(
          _serverMessageIdMeta,
          serverMessageId.isAcceptableOrUnknown(
              data['server_message_id']!, _serverMessageIdMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('is_outgoing')) {
      context.handle(
          _isOutgoingMeta,
          isOutgoing.isAcceptableOrUnknown(
              data['is_outgoing']!, _isOutgoingMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
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
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessage(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chat_id'])!,
      serverMessageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_message_id']),
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      isOutgoing: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_outgoing'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final String localId;
  final int chatId;
  final int? serverMessageId;
  final String payload;
  final String syncStatus;
  final bool isOutgoing;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChatMessage(
      {required this.localId,
      required this.chatId,
      this.serverMessageId,
      required this.payload,
      required this.syncStatus,
      required this.isOutgoing,
      required this.isDeleted,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['chat_id'] = Variable<int>(chatId);
    if (!nullToAbsent || serverMessageId != null) {
      map['server_message_id'] = Variable<int>(serverMessageId);
    }
    map['payload'] = Variable<String>(payload);
    map['sync_status'] = Variable<String>(syncStatus);
    map['is_outgoing'] = Variable<bool>(isOutgoing);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      localId: Value(localId),
      chatId: Value(chatId),
      serverMessageId: serverMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverMessageId),
      payload: Value(payload),
      syncStatus: Value(syncStatus),
      isOutgoing: Value(isOutgoing),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      localId: serializer.fromJson<String>(json['localId']),
      chatId: serializer.fromJson<int>(json['chatId']),
      serverMessageId: serializer.fromJson<int?>(json['serverMessageId']),
      payload: serializer.fromJson<String>(json['payload']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      isOutgoing: serializer.fromJson<bool>(json['isOutgoing']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'chatId': serializer.toJson<int>(chatId),
      'serverMessageId': serializer.toJson<int?>(serverMessageId),
      'payload': serializer.toJson<String>(payload),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'isOutgoing': serializer.toJson<bool>(isOutgoing),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChatMessage copyWith(
          {String? localId,
          int? chatId,
          Value<int?> serverMessageId = const Value.absent(),
          String? payload,
          String? syncStatus,
          bool? isOutgoing,
          bool? isDeleted,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ChatMessage(
        localId: localId ?? this.localId,
        chatId: chatId ?? this.chatId,
        serverMessageId: serverMessageId.present
            ? serverMessageId.value
            : this.serverMessageId,
        payload: payload ?? this.payload,
        syncStatus: syncStatus ?? this.syncStatus,
        isOutgoing: isOutgoing ?? this.isOutgoing,
        isDeleted: isDeleted ?? this.isDeleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ChatMessage copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessage(
      localId: data.localId.present ? data.localId.value : this.localId,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      serverMessageId: data.serverMessageId.present
          ? data.serverMessageId.value
          : this.serverMessageId,
      payload: data.payload.present ? data.payload.value : this.payload,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      isOutgoing:
          data.isOutgoing.present ? data.isOutgoing.value : this.isOutgoing,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('localId: $localId, ')
          ..write('chatId: $chatId, ')
          ..write('serverMessageId: $serverMessageId, ')
          ..write('payload: $payload, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, chatId, serverMessageId, payload,
      syncStatus, isOutgoing, isDeleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.localId == this.localId &&
          other.chatId == this.chatId &&
          other.serverMessageId == this.serverMessageId &&
          other.payload == this.payload &&
          other.syncStatus == this.syncStatus &&
          other.isOutgoing == this.isOutgoing &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<String> localId;
  final Value<int> chatId;
  final Value<int?> serverMessageId;
  final Value<String> payload;
  final Value<String> syncStatus;
  final Value<bool> isOutgoing;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.localId = const Value.absent(),
    this.chatId = const Value.absent(),
    this.serverMessageId = const Value.absent(),
    this.payload = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isOutgoing = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String localId,
    required int chatId,
    this.serverMessageId = const Value.absent(),
    required String payload,
    required String syncStatus,
    this.isOutgoing = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        chatId = Value(chatId),
        payload = Value(payload),
        syncStatus = Value(syncStatus),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ChatMessage> custom({
    Expression<String>? localId,
    Expression<int>? chatId,
    Expression<int>? serverMessageId,
    Expression<String>? payload,
    Expression<String>? syncStatus,
    Expression<bool>? isOutgoing,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (chatId != null) 'chat_id': chatId,
      if (serverMessageId != null) 'server_message_id': serverMessageId,
      if (payload != null) 'payload': payload,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isOutgoing != null) 'is_outgoing': isOutgoing,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith(
      {Value<String>? localId,
      Value<int>? chatId,
      Value<int?>? serverMessageId,
      Value<String>? payload,
      Value<String>? syncStatus,
      Value<bool>? isOutgoing,
      Value<bool>? isDeleted,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ChatMessagesCompanion(
      localId: localId ?? this.localId,
      chatId: chatId ?? this.chatId,
      serverMessageId: serverMessageId ?? this.serverMessageId,
      payload: payload ?? this.payload,
      syncStatus: syncStatus ?? this.syncStatus,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<int>(chatId.value);
    }
    if (serverMessageId.present) {
      map['server_message_id'] = Variable<int>(serverMessageId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (isOutgoing.present) {
      map['is_outgoing'] = Variable<bool>(isOutgoing.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
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
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('localId: $localId, ')
          ..write('chatId: $chatId, ')
          ..write('serverMessageId: $serverMessageId, ')
          ..write('payload: $payload, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RmkGoodsTable extends RmkGoods with TableInfo<$RmkGoodsTable, RmkGood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RmkGoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalizedNameMeta =
      const VerificationMeta('normalizedName');
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
      'normalized_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _categoryNameMeta =
      const VerificationMeta('categoryName');
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
      'category_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentCategoryIdMeta =
      const VerificationMeta('parentCategoryId');
  @override
  late final GeneratedColumn<int> parentCategoryId = GeneratedColumn<int>(
      'parent_category_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverCreatedAtMeta =
      const VerificationMeta('serverCreatedAt');
  @override
  late final GeneratedColumn<DateTime> serverCreatedAt =
      GeneratedColumn<DateTime>('server_created_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _serverUpdatedAtMeta =
      const VerificationMeta('serverUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>('server_updated_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _localUpdatedAtMeta =
      const VerificationMeta('localUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>('local_updated_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        normalizedName,
        categoryId,
        categoryName,
        parentCategoryId,
        price,
        quantity,
        imageUrl,
        payload,
        serverCreatedAt,
        serverUpdatedAt,
        localUpdatedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rmk_goods';
  @override
  VerificationContext validateIntegrity(Insertable<RmkGood> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
          _normalizedNameMeta,
          normalizedName.isAcceptableOrUnknown(
              data['normalized_name']!, _normalizedNameMeta));
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('category_name')) {
      context.handle(
          _categoryNameMeta,
          categoryName.isAcceptableOrUnknown(
              data['category_name']!, _categoryNameMeta));
    }
    if (data.containsKey('parent_category_id')) {
      context.handle(
          _parentCategoryIdMeta,
          parentCategoryId.isAcceptableOrUnknown(
              data['parent_category_id']!, _parentCategoryIdMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('server_created_at')) {
      context.handle(
          _serverCreatedAtMeta,
          serverCreatedAt.isAcceptableOrUnknown(
              data['server_created_at']!, _serverCreatedAtMeta));
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
          _serverUpdatedAtMeta,
          serverUpdatedAt.isAcceptableOrUnknown(
              data['server_updated_at']!, _serverUpdatedAtMeta));
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
          _localUpdatedAtMeta,
          localUpdatedAt.isAcceptableOrUnknown(
              data['local_updated_at']!, _localUpdatedAtMeta));
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RmkGood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RmkGood(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      normalizedName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}normalized_name'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      categoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_name']),
      parentCategoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_category_id']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      serverCreatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}server_created_at']),
      serverUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}server_updated_at']),
      localUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}local_updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $RmkGoodsTable createAlias(String alias) {
    return $RmkGoodsTable(attachedDatabase, alias);
  }
}

class RmkGood extends DataClass implements Insertable<RmkGood> {
  final int id;
  final String name;
  final String normalizedName;
  final int? categoryId;
  final String? categoryName;
  final int? parentCategoryId;
  final double price;
  final double quantity;
  final String? imageUrl;
  final String payload;
  final DateTime? serverCreatedAt;
  final DateTime? serverUpdatedAt;
  final DateTime localUpdatedAt;
  final bool isDeleted;
  const RmkGood(
      {required this.id,
      required this.name,
      required this.normalizedName,
      this.categoryId,
      this.categoryName,
      this.parentCategoryId,
      required this.price,
      required this.quantity,
      this.imageUrl,
      required this.payload,
      this.serverCreatedAt,
      this.serverUpdatedAt,
      required this.localUpdatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || parentCategoryId != null) {
      map['parent_category_id'] = Variable<int>(parentCategoryId);
    }
    map['price'] = Variable<double>(price);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || serverCreatedAt != null) {
      map['server_created_at'] = Variable<DateTime>(serverCreatedAt);
    }
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  RmkGoodsCompanion toCompanion(bool nullToAbsent) {
    return RmkGoodsCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      parentCategoryId: parentCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentCategoryId),
      price: Value(price),
      quantity: Value(quantity),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      payload: Value(payload),
      serverCreatedAt: serverCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverCreatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      localUpdatedAt: Value(localUpdatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory RmkGood.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RmkGood(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      parentCategoryId: serializer.fromJson<int?>(json['parentCategoryId']),
      price: serializer.fromJson<double>(json['price']),
      quantity: serializer.fromJson<double>(json['quantity']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      payload: serializer.fromJson<String>(json['payload']),
      serverCreatedAt: serializer.fromJson<DateTime?>(json['serverCreatedAt']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'categoryId': serializer.toJson<int?>(categoryId),
      'categoryName': serializer.toJson<String?>(categoryName),
      'parentCategoryId': serializer.toJson<int?>(parentCategoryId),
      'price': serializer.toJson<double>(price),
      'quantity': serializer.toJson<double>(quantity),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'payload': serializer.toJson<String>(payload),
      'serverCreatedAt': serializer.toJson<DateTime?>(serverCreatedAt),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  RmkGood copyWith(
          {int? id,
          String? name,
          String? normalizedName,
          Value<int?> categoryId = const Value.absent(),
          Value<String?> categoryName = const Value.absent(),
          Value<int?> parentCategoryId = const Value.absent(),
          double? price,
          double? quantity,
          Value<String?> imageUrl = const Value.absent(),
          String? payload,
          Value<DateTime?> serverCreatedAt = const Value.absent(),
          Value<DateTime?> serverUpdatedAt = const Value.absent(),
          DateTime? localUpdatedAt,
          bool? isDeleted}) =>
      RmkGood(
        id: id ?? this.id,
        name: name ?? this.name,
        normalizedName: normalizedName ?? this.normalizedName,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        categoryName:
            categoryName.present ? categoryName.value : this.categoryName,
        parentCategoryId: parentCategoryId.present
            ? parentCategoryId.value
            : this.parentCategoryId,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        payload: payload ?? this.payload,
        serverCreatedAt: serverCreatedAt.present
            ? serverCreatedAt.value
            : this.serverCreatedAt,
        serverUpdatedAt: serverUpdatedAt.present
            ? serverUpdatedAt.value
            : this.serverUpdatedAt,
        localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  RmkGood copyWithCompanion(RmkGoodsCompanion data) {
    return RmkGood(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      parentCategoryId: data.parentCategoryId.present
          ? data.parentCategoryId.value
          : this.parentCategoryId,
      price: data.price.present ? data.price.value : this.price,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      payload: data.payload.present ? data.payload.value : this.payload,
      serverCreatedAt: data.serverCreatedAt.present
          ? data.serverCreatedAt.value
          : this.serverCreatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RmkGood(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('parentCategoryId: $parentCategoryId, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('payload: $payload, ')
          ..write('serverCreatedAt: $serverCreatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      normalizedName,
      categoryId,
      categoryName,
      parentCategoryId,
      price,
      quantity,
      imageUrl,
      payload,
      serverCreatedAt,
      serverUpdatedAt,
      localUpdatedAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RmkGood &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.parentCategoryId == this.parentCategoryId &&
          other.price == this.price &&
          other.quantity == this.quantity &&
          other.imageUrl == this.imageUrl &&
          other.payload == this.payload &&
          other.serverCreatedAt == this.serverCreatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.isDeleted == this.isDeleted);
}

class RmkGoodsCompanion extends UpdateCompanion<RmkGood> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<int?> categoryId;
  final Value<String?> categoryName;
  final Value<int?> parentCategoryId;
  final Value<double> price;
  final Value<double> quantity;
  final Value<String?> imageUrl;
  final Value<String> payload;
  final Value<DateTime?> serverCreatedAt;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> localUpdatedAt;
  final Value<bool> isDeleted;
  const RmkGoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.parentCategoryId = const Value.absent(),
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.payload = const Value.absent(),
    this.serverCreatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  RmkGoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String normalizedName,
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.parentCategoryId = const Value.absent(),
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    this.imageUrl = const Value.absent(),
    required String payload,
    this.serverCreatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    required DateTime localUpdatedAt,
    this.isDeleted = const Value.absent(),
  })  : name = Value(name),
        normalizedName = Value(normalizedName),
        payload = Value(payload),
        localUpdatedAt = Value(localUpdatedAt);
  static Insertable<RmkGood> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<int>? categoryId,
    Expression<String>? categoryName,
    Expression<int>? parentCategoryId,
    Expression<double>? price,
    Expression<double>? quantity,
    Expression<String>? imageUrl,
    Expression<String>? payload,
    Expression<DateTime>? serverCreatedAt,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (parentCategoryId != null) 'parent_category_id': parentCategoryId,
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
      if (imageUrl != null) 'image_url': imageUrl,
      if (payload != null) 'payload': payload,
      if (serverCreatedAt != null) 'server_created_at': serverCreatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  RmkGoodsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? normalizedName,
      Value<int?>? categoryId,
      Value<String?>? categoryName,
      Value<int?>? parentCategoryId,
      Value<double>? price,
      Value<double>? quantity,
      Value<String?>? imageUrl,
      Value<String>? payload,
      Value<DateTime?>? serverCreatedAt,
      Value<DateTime?>? serverUpdatedAt,
      Value<DateTime>? localUpdatedAt,
      Value<bool>? isDeleted}) {
    return RmkGoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      payload: payload ?? this.payload,
      serverCreatedAt: serverCreatedAt ?? this.serverCreatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (parentCategoryId.present) {
      map['parent_category_id'] = Variable<int>(parentCategoryId.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (serverCreatedAt.present) {
      map['server_created_at'] = Variable<DateTime>(serverCreatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RmkGoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('parentCategoryId: $parentCategoryId, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('payload: $payload, ')
          ..write('serverCreatedAt: $serverCreatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $RmkCategoriesTable extends RmkCategories
    with TableInfo<$RmkCategoriesTable, RmkCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RmkCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalizedNameMeta =
      const VerificationMeta('normalizedName');
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
      'normalized_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _localUpdatedAtMeta =
      const VerificationMeta('localUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>('local_updated_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, parentId, name, normalizedName, level, localUpdatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rmk_categories';
  @override
  VerificationContext validateIntegrity(Insertable<RmkCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
          _normalizedNameMeta,
          normalizedName.isAcceptableOrUnknown(
              data['normalized_name']!, _normalizedNameMeta));
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
          _localUpdatedAtMeta,
          localUpdatedAt.isAcceptableOrUnknown(
              data['local_updated_at']!, _localUpdatedAtMeta));
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RmkCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RmkCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      normalizedName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}normalized_name'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}local_updated_at'])!,
    );
  }

  @override
  $RmkCategoriesTable createAlias(String alias) {
    return $RmkCategoriesTable(attachedDatabase, alias);
  }
}

class RmkCategory extends DataClass implements Insertable<RmkCategory> {
  final int id;
  final int? parentId;
  final String name;
  final String normalizedName;
  final int level;
  final DateTime localUpdatedAt;
  const RmkCategory(
      {required this.id,
      this.parentId,
      required this.name,
      required this.normalizedName,
      required this.level,
      required this.localUpdatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['level'] = Variable<int>(level);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  RmkCategoriesCompanion toCompanion(bool nullToAbsent) {
    return RmkCategoriesCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      normalizedName: Value(normalizedName),
      level: Value(level),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory RmkCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RmkCategory(
      id: serializer.fromJson<int>(json['id']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      level: serializer.fromJson<int>(json['level']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'parentId': serializer.toJson<int?>(parentId),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'level': serializer.toJson<int>(level),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  RmkCategory copyWith(
          {int? id,
          Value<int?> parentId = const Value.absent(),
          String? name,
          String? normalizedName,
          int? level,
          DateTime? localUpdatedAt}) =>
      RmkCategory(
        id: id ?? this.id,
        parentId: parentId.present ? parentId.value : this.parentId,
        name: name ?? this.name,
        normalizedName: normalizedName ?? this.normalizedName,
        level: level ?? this.level,
        localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      );
  RmkCategory copyWithCompanion(RmkCategoriesCompanion data) {
    return RmkCategory(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      level: data.level.present ? data.level.value : this.level,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RmkCategory(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('level: $level, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, parentId, name, normalizedName, level, localUpdatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RmkCategory &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.level == this.level &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class RmkCategoriesCompanion extends UpdateCompanion<RmkCategory> {
  final Value<int> id;
  final Value<int?> parentId;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<int> level;
  final Value<DateTime> localUpdatedAt;
  const RmkCategoriesCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.level = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
  });
  RmkCategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    required String name,
    required String normalizedName,
    this.level = const Value.absent(),
    required DateTime localUpdatedAt,
  })  : name = Value(name),
        normalizedName = Value(normalizedName),
        localUpdatedAt = Value(localUpdatedAt);
  static Insertable<RmkCategory> custom({
    Expression<int>? id,
    Expression<int>? parentId,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<int>? level,
    Expression<DateTime>? localUpdatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (level != null) 'level': level,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
    });
  }

  RmkCategoriesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? parentId,
      Value<String>? name,
      Value<String>? normalizedName,
      Value<int>? level,
      Value<DateTime>? localUpdatedAt}) {
    return RmkCategoriesCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      level: level ?? this.level,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RmkCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('level: $level, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }
}

class $RmkCartItemsTable extends RmkCartItems
    with TableInfo<$RmkCartItemsTable, RmkCartItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RmkCartItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _goodIdMeta = const VerificationMeta('goodId');
  @override
  late final GeneratedColumn<int> goodId = GeneratedColumn<int>(
      'good_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _customTotalMeta =
      const VerificationMeta('customTotal');
  @override
  late final GeneratedColumn<double> customTotal = GeneratedColumn<double>(
      'custom_total', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [goodId, name, quantity, price, customTotal, imageUrl, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rmk_cart_items';
  @override
  VerificationContext validateIntegrity(Insertable<RmkCartItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('good_id')) {
      context.handle(_goodIdMeta,
          goodId.isAcceptableOrUnknown(data['good_id']!, _goodIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    }
    if (data.containsKey('custom_total')) {
      context.handle(
          _customTotalMeta,
          customTotal.isAcceptableOrUnknown(
              data['custom_total']!, _customTotalMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
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
  Set<GeneratedColumn> get $primaryKey => {goodId};
  @override
  RmkCartItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RmkCartItem(
      goodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}good_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      customTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}custom_total']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RmkCartItemsTable createAlias(String alias) {
    return $RmkCartItemsTable(attachedDatabase, alias);
  }
}

class RmkCartItem extends DataClass implements Insertable<RmkCartItem> {
  final int goodId;
  final String name;
  final double quantity;
  final double price;
  final double? customTotal;
  final String? imageUrl;
  final DateTime updatedAt;
  const RmkCartItem(
      {required this.goodId,
      required this.name,
      required this.quantity,
      required this.price,
      this.customTotal,
      this.imageUrl,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['good_id'] = Variable<int>(goodId);
    map['name'] = Variable<String>(name);
    map['quantity'] = Variable<double>(quantity);
    map['price'] = Variable<double>(price);
    if (!nullToAbsent || customTotal != null) {
      map['custom_total'] = Variable<double>(customTotal);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RmkCartItemsCompanion toCompanion(bool nullToAbsent) {
    return RmkCartItemsCompanion(
      goodId: Value(goodId),
      name: Value(name),
      quantity: Value(quantity),
      price: Value(price),
      customTotal: customTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(customTotal),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      updatedAt: Value(updatedAt),
    );
  }

  factory RmkCartItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RmkCartItem(
      goodId: serializer.fromJson<int>(json['goodId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<double>(json['quantity']),
      price: serializer.fromJson<double>(json['price']),
      customTotal: serializer.fromJson<double?>(json['customTotal']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'goodId': serializer.toJson<int>(goodId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<double>(quantity),
      'price': serializer.toJson<double>(price),
      'customTotal': serializer.toJson<double?>(customTotal),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RmkCartItem copyWith(
          {int? goodId,
          String? name,
          double? quantity,
          double? price,
          Value<double?> customTotal = const Value.absent(),
          Value<String?> imageUrl = const Value.absent(),
          DateTime? updatedAt}) =>
      RmkCartItem(
        goodId: goodId ?? this.goodId,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        price: price ?? this.price,
        customTotal: customTotal.present ? customTotal.value : this.customTotal,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  RmkCartItem copyWithCompanion(RmkCartItemsCompanion data) {
    return RmkCartItem(
      goodId: data.goodId.present ? data.goodId.value : this.goodId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      price: data.price.present ? data.price.value : this.price,
      customTotal:
          data.customTotal.present ? data.customTotal.value : this.customTotal,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RmkCartItem(')
          ..write('goodId: $goodId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('customTotal: $customTotal, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      goodId, name, quantity, price, customTotal, imageUrl, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RmkCartItem &&
          other.goodId == this.goodId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.price == this.price &&
          other.customTotal == this.customTotal &&
          other.imageUrl == this.imageUrl &&
          other.updatedAt == this.updatedAt);
}

class RmkCartItemsCompanion extends UpdateCompanion<RmkCartItem> {
  final Value<int> goodId;
  final Value<String> name;
  final Value<double> quantity;
  final Value<double> price;
  final Value<double?> customTotal;
  final Value<String?> imageUrl;
  final Value<DateTime> updatedAt;
  const RmkCartItemsCompanion({
    this.goodId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.price = const Value.absent(),
    this.customTotal = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RmkCartItemsCompanion.insert({
    this.goodId = const Value.absent(),
    required String name,
    this.quantity = const Value.absent(),
    this.price = const Value.absent(),
    this.customTotal = const Value.absent(),
    this.imageUrl = const Value.absent(),
    required DateTime updatedAt,
  })  : name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<RmkCartItem> custom({
    Expression<int>? goodId,
    Expression<String>? name,
    Expression<double>? quantity,
    Expression<double>? price,
    Expression<double>? customTotal,
    Expression<String>? imageUrl,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (goodId != null) 'good_id': goodId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (price != null) 'price': price,
      if (customTotal != null) 'custom_total': customTotal,
      if (imageUrl != null) 'image_url': imageUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RmkCartItemsCompanion copyWith(
      {Value<int>? goodId,
      Value<String>? name,
      Value<double>? quantity,
      Value<double>? price,
      Value<double?>? customTotal,
      Value<String?>? imageUrl,
      Value<DateTime>? updatedAt}) {
    return RmkCartItemsCompanion(
      goodId: goodId ?? this.goodId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      customTotal: customTotal ?? this.customTotal,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (goodId.present) {
      map['good_id'] = Variable<int>(goodId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (customTotal.present) {
      map['custom_total'] = Variable<double>(customTotal.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RmkCartItemsCompanion(')
          ..write('goodId: $goodId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('customTotal: $customTotal, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RmkOutboxSalesTable extends RmkOutboxSales
    with TableInfo<$RmkOutboxSalesTable, RmkOutboxSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RmkOutboxSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  List<GeneratedColumn> get $columns => [
        id,
        payload,
        idempotencyKey,
        status,
        attemptCount,
        lastError,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rmk_outbox_sales';
  @override
  VerificationContext validateIntegrity(Insertable<RmkOutboxSale> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RmkOutboxSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RmkOutboxSale(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      idempotencyKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}idempotency_key'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RmkOutboxSalesTable createAlias(String alias) {
    return $RmkOutboxSalesTable(attachedDatabase, alias);
  }
}

class RmkOutboxSale extends DataClass implements Insertable<RmkOutboxSale> {
  final String id;
  final String payload;
  final String idempotencyKey;
  final String status;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RmkOutboxSale(
      {required this.id,
      required this.payload,
      required this.idempotencyKey,
      required this.status,
      required this.attemptCount,
      this.lastError,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RmkOutboxSalesCompanion toCompanion(bool nullToAbsent) {
    return RmkOutboxSalesCompanion(
      id: Value(id),
      payload: Value(payload),
      idempotencyKey: Value(idempotencyKey),
      status: Value(status),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RmkOutboxSale.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RmkOutboxSale(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RmkOutboxSale copyWith(
          {String? id,
          String? payload,
          String? idempotencyKey,
          String? status,
          int? attemptCount,
          Value<String?> lastError = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      RmkOutboxSale(
        id: id ?? this.id,
        payload: payload ?? this.payload,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        lastError: lastError.present ? lastError.value : this.lastError,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  RmkOutboxSale copyWithCompanion(RmkOutboxSalesCompanion data) {
    return RmkOutboxSale(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RmkOutboxSale(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, idempotencyKey, status,
      attemptCount, lastError, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RmkOutboxSale &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.idempotencyKey == this.idempotencyKey &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RmkOutboxSalesCompanion extends UpdateCompanion<RmkOutboxSale> {
  final Value<String> id;
  final Value<String> payload;
  final Value<String> idempotencyKey;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RmkOutboxSalesCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RmkOutboxSalesCompanion.insert({
    required String id,
    required String payload,
    required String idempotencyKey,
    required String status,
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        payload = Value(payload),
        idempotencyKey = Value(idempotencyKey),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<RmkOutboxSale> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<String>? idempotencyKey,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RmkOutboxSalesCompanion copyWith(
      {Value<String>? id,
      Value<String>? payload,
      Value<String>? idempotencyKey,
      Value<String>? status,
      Value<int>? attemptCount,
      Value<String?>? lastError,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return RmkOutboxSalesCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
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
    return (StringBuffer('RmkOutboxSalesCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedRecordsTable cachedRecords = $CachedRecordsTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  late final $OutboxOperationsTable outboxOperations =
      $OutboxOperationsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $RmkGoodsTable rmkGoods = $RmkGoodsTable(this);
  late final $RmkCategoriesTable rmkCategories = $RmkCategoriesTable(this);
  late final $RmkCartItemsTable rmkCartItems = $RmkCartItemsTable(this);
  late final $RmkOutboxSalesTable rmkOutboxSales = $RmkOutboxSalesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cachedRecords,
        syncStates,
        outboxOperations,
        chatMessages,
        rmkGoods,
        rmkCategories,
        rmkCartItems,
        rmkOutboxSales
      ];
}

typedef $$CachedRecordsTableCreateCompanionBuilder = CachedRecordsCompanion
    Function({
  Value<int> id,
  required String module,
  required String cacheKey,
  required String payload,
  Value<String?> entityVersion,
  Value<String?> deltaToken,
  Value<bool> isDeleted,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> lastSyncedAt,
});
typedef $$CachedRecordsTableUpdateCompanionBuilder = CachedRecordsCompanion
    Function({
  Value<int> id,
  Value<String> module,
  Value<String> cacheKey,
  Value<String> payload,
  Value<String?> entityVersion,
  Value<String?> deltaToken,
  Value<bool> isDeleted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncedAt,
});

class $$CachedRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRecordsTable> {
  $$CachedRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get module => $composableBuilder(
      column: $table.module, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityVersion => $composableBuilder(
      column: $table.entityVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deltaToken => $composableBuilder(
      column: $table.deltaToken, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRecordsTable> {
  $$CachedRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get module => $composableBuilder(
      column: $table.module, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityVersion => $composableBuilder(
      column: $table.entityVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deltaToken => $composableBuilder(
      column: $table.deltaToken, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$CachedRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRecordsTable> {
  $$CachedRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get entityVersion => $composableBuilder(
      column: $table.entityVersion, builder: (column) => column);

  GeneratedColumn<String> get deltaToken => $composableBuilder(
      column: $table.deltaToken, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);
}

class $$CachedRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedRecordsTable,
    CachedRecord,
    $$CachedRecordsTableFilterComposer,
    $$CachedRecordsTableOrderingComposer,
    $$CachedRecordsTableAnnotationComposer,
    $$CachedRecordsTableCreateCompanionBuilder,
    $$CachedRecordsTableUpdateCompanionBuilder,
    (
      CachedRecord,
      BaseReferences<_$AppDatabase, $CachedRecordsTable, CachedRecord>
    ),
    CachedRecord,
    PrefetchHooks Function()> {
  $$CachedRecordsTableTableManager(_$AppDatabase db, $CachedRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> module = const Value.absent(),
            Value<String> cacheKey = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String?> entityVersion = const Value.absent(),
            Value<String?> deltaToken = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
          }) =>
              CachedRecordsCompanion(
            id: id,
            module: module,
            cacheKey: cacheKey,
            payload: payload,
            entityVersion: entityVersion,
            deltaToken: deltaToken,
            isDeleted: isDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncedAt: lastSyncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String module,
            required String cacheKey,
            required String payload,
            Value<String?> entityVersion = const Value.absent(),
            Value<String?> deltaToken = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> lastSyncedAt = const Value.absent(),
          }) =>
              CachedRecordsCompanion.insert(
            id: id,
            module: module,
            cacheKey: cacheKey,
            payload: payload,
            entityVersion: entityVersion,
            deltaToken: deltaToken,
            isDeleted: isDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncedAt: lastSyncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedRecordsTable,
    CachedRecord,
    $$CachedRecordsTableFilterComposer,
    $$CachedRecordsTableOrderingComposer,
    $$CachedRecordsTableAnnotationComposer,
    $$CachedRecordsTableCreateCompanionBuilder,
    $$CachedRecordsTableUpdateCompanionBuilder,
    (
      CachedRecord,
      BaseReferences<_$AppDatabase, $CachedRecordsTable, CachedRecord>
    ),
    CachedRecord,
    PrefetchHooks Function()>;
typedef $$SyncStatesTableCreateCompanionBuilder = SyncStatesCompanion Function({
  Value<int> id,
  required String module,
  required String scope,
  Value<String?> deltaToken,
  Value<int?> sinceMessageId,
  Value<String?> entityVersion,
  Value<DateTime?> lastSyncedAt,
  required DateTime updatedAt,
});
typedef $$SyncStatesTableUpdateCompanionBuilder = SyncStatesCompanion Function({
  Value<int> id,
  Value<String> module,
  Value<String> scope,
  Value<String?> deltaToken,
  Value<int?> sinceMessageId,
  Value<String?> entityVersion,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> updatedAt,
});

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get module => $composableBuilder(
      column: $table.module, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deltaToken => $composableBuilder(
      column: $table.deltaToken, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sinceMessageId => $composableBuilder(
      column: $table.sinceMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityVersion => $composableBuilder(
      column: $table.entityVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get module => $composableBuilder(
      column: $table.module, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deltaToken => $composableBuilder(
      column: $table.deltaToken, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sinceMessageId => $composableBuilder(
      column: $table.sinceMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityVersion => $composableBuilder(
      column: $table.entityVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get deltaToken => $composableBuilder(
      column: $table.deltaToken, builder: (column) => column);

  GeneratedColumn<int> get sinceMessageId => $composableBuilder(
      column: $table.sinceMessageId, builder: (column) => column);

  GeneratedColumn<String> get entityVersion => $composableBuilder(
      column: $table.entityVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncStatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncStatesTable,
    SyncState,
    $$SyncStatesTableFilterComposer,
    $$SyncStatesTableOrderingComposer,
    $$SyncStatesTableAnnotationComposer,
    $$SyncStatesTableCreateCompanionBuilder,
    $$SyncStatesTableUpdateCompanionBuilder,
    (SyncState, BaseReferences<_$AppDatabase, $SyncStatesTable, SyncState>),
    SyncState,
    PrefetchHooks Function()> {
  $$SyncStatesTableTableManager(_$AppDatabase db, $SyncStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> module = const Value.absent(),
            Value<String> scope = const Value.absent(),
            Value<String?> deltaToken = const Value.absent(),
            Value<int?> sinceMessageId = const Value.absent(),
            Value<String?> entityVersion = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SyncStatesCompanion(
            id: id,
            module: module,
            scope: scope,
            deltaToken: deltaToken,
            sinceMessageId: sinceMessageId,
            entityVersion: entityVersion,
            lastSyncedAt: lastSyncedAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String module,
            required String scope,
            Value<String?> deltaToken = const Value.absent(),
            Value<int?> sinceMessageId = const Value.absent(),
            Value<String?> entityVersion = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            required DateTime updatedAt,
          }) =>
              SyncStatesCompanion.insert(
            id: id,
            module: module,
            scope: scope,
            deltaToken: deltaToken,
            sinceMessageId: sinceMessageId,
            entityVersion: entityVersion,
            lastSyncedAt: lastSyncedAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncStatesTable,
    SyncState,
    $$SyncStatesTableFilterComposer,
    $$SyncStatesTableOrderingComposer,
    $$SyncStatesTableAnnotationComposer,
    $$SyncStatesTableCreateCompanionBuilder,
    $$SyncStatesTableUpdateCompanionBuilder,
    (SyncState, BaseReferences<_$AppDatabase, $SyncStatesTable, SyncState>),
    SyncState,
    PrefetchHooks Function()>;
typedef $$OutboxOperationsTableCreateCompanionBuilder
    = OutboxOperationsCompanion Function({
  required String id,
  required String module,
  required String entityType,
  required String entityId,
  required String operationType,
  required String payload,
  required String idempotencyKey,
  required String status,
  required int priority,
  Value<int> attemptCount,
  Value<DateTime?> nextAttemptAt,
  Value<String?> lastError,
  Value<String?> conflictPayload,
  Value<bool> requiresTextOnly,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$OutboxOperationsTableUpdateCompanionBuilder
    = OutboxOperationsCompanion Function({
  Value<String> id,
  Value<String> module,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operationType,
  Value<String> payload,
  Value<String> idempotencyKey,
  Value<String> status,
  Value<int> priority,
  Value<int> attemptCount,
  Value<DateTime?> nextAttemptAt,
  Value<String?> lastError,
  Value<String?> conflictPayload,
  Value<bool> requiresTextOnly,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$OutboxOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get module => $composableBuilder(
      column: $table.module, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operationType => $composableBuilder(
      column: $table.operationType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conflictPayload => $composableBuilder(
      column: $table.conflictPayload,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requiresTextOnly => $composableBuilder(
      column: $table.requiresTextOnly,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OutboxOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get module => $composableBuilder(
      column: $table.module, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operationType => $composableBuilder(
      column: $table.operationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conflictPayload => $composableBuilder(
      column: $table.conflictPayload,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requiresTextOnly => $composableBuilder(
      column: $table.requiresTextOnly,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OutboxOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
      column: $table.operationType, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get conflictPayload => $composableBuilder(
      column: $table.conflictPayload, builder: (column) => column);

  GeneratedColumn<bool> get requiresTextOnly => $composableBuilder(
      column: $table.requiresTextOnly, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OutboxOperationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OutboxOperationsTable,
    OutboxOperation,
    $$OutboxOperationsTableFilterComposer,
    $$OutboxOperationsTableOrderingComposer,
    $$OutboxOperationsTableAnnotationComposer,
    $$OutboxOperationsTableCreateCompanionBuilder,
    $$OutboxOperationsTableUpdateCompanionBuilder,
    (
      OutboxOperation,
      BaseReferences<_$AppDatabase, $OutboxOperationsTable, OutboxOperation>
    ),
    OutboxOperation,
    PrefetchHooks Function()> {
  $$OutboxOperationsTableTableManager(
      _$AppDatabase db, $OutboxOperationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> module = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operationType = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> idempotencyKey = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<DateTime?> nextAttemptAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String?> conflictPayload = const Value.absent(),
            Value<bool> requiresTextOnly = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxOperationsCompanion(
            id: id,
            module: module,
            entityType: entityType,
            entityId: entityId,
            operationType: operationType,
            payload: payload,
            idempotencyKey: idempotencyKey,
            status: status,
            priority: priority,
            attemptCount: attemptCount,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            conflictPayload: conflictPayload,
            requiresTextOnly: requiresTextOnly,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String module,
            required String entityType,
            required String entityId,
            required String operationType,
            required String payload,
            required String idempotencyKey,
            required String status,
            required int priority,
            Value<int> attemptCount = const Value.absent(),
            Value<DateTime?> nextAttemptAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String?> conflictPayload = const Value.absent(),
            Value<bool> requiresTextOnly = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxOperationsCompanion.insert(
            id: id,
            module: module,
            entityType: entityType,
            entityId: entityId,
            operationType: operationType,
            payload: payload,
            idempotencyKey: idempotencyKey,
            status: status,
            priority: priority,
            attemptCount: attemptCount,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            conflictPayload: conflictPayload,
            requiresTextOnly: requiresTextOnly,
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

typedef $$OutboxOperationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OutboxOperationsTable,
    OutboxOperation,
    $$OutboxOperationsTableFilterComposer,
    $$OutboxOperationsTableOrderingComposer,
    $$OutboxOperationsTableAnnotationComposer,
    $$OutboxOperationsTableCreateCompanionBuilder,
    $$OutboxOperationsTableUpdateCompanionBuilder,
    (
      OutboxOperation,
      BaseReferences<_$AppDatabase, $OutboxOperationsTable, OutboxOperation>
    ),
    OutboxOperation,
    PrefetchHooks Function()>;
typedef $$ChatMessagesTableCreateCompanionBuilder = ChatMessagesCompanion
    Function({
  required String localId,
  required int chatId,
  Value<int?> serverMessageId,
  required String payload,
  required String syncStatus,
  Value<bool> isOutgoing,
  Value<bool> isDeleted,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ChatMessagesTableUpdateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<String> localId,
  Value<int> chatId,
  Value<int?> serverMessageId,
  Value<String> payload,
  Value<String> syncStatus,
  Value<bool> isOutgoing,
  Value<bool> isDeleted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverMessageId => $composableBuilder(
      column: $table.serverMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOutgoing => $composableBuilder(
      column: $table.isOutgoing, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverMessageId => $composableBuilder(
      column: $table.serverMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOutgoing => $composableBuilder(
      column: $table.isOutgoing, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<int> get serverMessageId => $composableBuilder(
      column: $table.serverMessageId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<bool> get isOutgoing => $composableBuilder(
      column: $table.isOutgoing, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChatMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (
      ChatMessage,
      BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>
    ),
    ChatMessage,
    PrefetchHooks Function()> {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<int> chatId = const Value.absent(),
            Value<int?> serverMessageId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<bool> isOutgoing = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion(
            localId: localId,
            chatId: chatId,
            serverMessageId: serverMessageId,
            payload: payload,
            syncStatus: syncStatus,
            isOutgoing: isOutgoing,
            isDeleted: isDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            required int chatId,
            Value<int?> serverMessageId = const Value.absent(),
            required String payload,
            required String syncStatus,
            Value<bool> isOutgoing = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion.insert(
            localId: localId,
            chatId: chatId,
            serverMessageId: serverMessageId,
            payload: payload,
            syncStatus: syncStatus,
            isOutgoing: isOutgoing,
            isDeleted: isDeleted,
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

typedef $$ChatMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (
      ChatMessage,
      BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>
    ),
    ChatMessage,
    PrefetchHooks Function()>;
typedef $$RmkGoodsTableCreateCompanionBuilder = RmkGoodsCompanion Function({
  Value<int> id,
  required String name,
  required String normalizedName,
  Value<int?> categoryId,
  Value<String?> categoryName,
  Value<int?> parentCategoryId,
  Value<double> price,
  Value<double> quantity,
  Value<String?> imageUrl,
  required String payload,
  Value<DateTime?> serverCreatedAt,
  Value<DateTime?> serverUpdatedAt,
  required DateTime localUpdatedAt,
  Value<bool> isDeleted,
});
typedef $$RmkGoodsTableUpdateCompanionBuilder = RmkGoodsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> normalizedName,
  Value<int?> categoryId,
  Value<String?> categoryName,
  Value<int?> parentCategoryId,
  Value<double> price,
  Value<double> quantity,
  Value<String?> imageUrl,
  Value<String> payload,
  Value<DateTime?> serverCreatedAt,
  Value<DateTime?> serverUpdatedAt,
  Value<DateTime> localUpdatedAt,
  Value<bool> isDeleted,
});

class $$RmkGoodsTableFilterComposer
    extends Composer<_$AppDatabase, $RmkGoodsTable> {
  $$RmkGoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parentCategoryId => $composableBuilder(
      column: $table.parentCategoryId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get serverCreatedAt => $composableBuilder(
      column: $table.serverCreatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
      column: $table.serverUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));
}

class $$RmkGoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $RmkGoodsTable> {
  $$RmkGoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryName => $composableBuilder(
      column: $table.categoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parentCategoryId => $composableBuilder(
      column: $table.parentCategoryId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get serverCreatedAt => $composableBuilder(
      column: $table.serverCreatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
      column: $table.serverUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$RmkGoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RmkGoodsTable> {
  $$RmkGoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => column);

  GeneratedColumn<int> get parentCategoryId => $composableBuilder(
      column: $table.parentCategoryId, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get serverCreatedAt => $composableBuilder(
      column: $table.serverCreatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
      column: $table.serverUpdatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$RmkGoodsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RmkGoodsTable,
    RmkGood,
    $$RmkGoodsTableFilterComposer,
    $$RmkGoodsTableOrderingComposer,
    $$RmkGoodsTableAnnotationComposer,
    $$RmkGoodsTableCreateCompanionBuilder,
    $$RmkGoodsTableUpdateCompanionBuilder,
    (RmkGood, BaseReferences<_$AppDatabase, $RmkGoodsTable, RmkGood>),
    RmkGood,
    PrefetchHooks Function()> {
  $$RmkGoodsTableTableManager(_$AppDatabase db, $RmkGoodsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RmkGoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RmkGoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RmkGoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> normalizedName = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<int?> parentCategoryId = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime?> serverCreatedAt = const Value.absent(),
            Value<DateTime?> serverUpdatedAt = const Value.absent(),
            Value<DateTime> localUpdatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              RmkGoodsCompanion(
            id: id,
            name: name,
            normalizedName: normalizedName,
            categoryId: categoryId,
            categoryName: categoryName,
            parentCategoryId: parentCategoryId,
            price: price,
            quantity: quantity,
            imageUrl: imageUrl,
            payload: payload,
            serverCreatedAt: serverCreatedAt,
            serverUpdatedAt: serverUpdatedAt,
            localUpdatedAt: localUpdatedAt,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String normalizedName,
            Value<int?> categoryId = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<int?> parentCategoryId = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            required String payload,
            Value<DateTime?> serverCreatedAt = const Value.absent(),
            Value<DateTime?> serverUpdatedAt = const Value.absent(),
            required DateTime localUpdatedAt,
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              RmkGoodsCompanion.insert(
            id: id,
            name: name,
            normalizedName: normalizedName,
            categoryId: categoryId,
            categoryName: categoryName,
            parentCategoryId: parentCategoryId,
            price: price,
            quantity: quantity,
            imageUrl: imageUrl,
            payload: payload,
            serverCreatedAt: serverCreatedAt,
            serverUpdatedAt: serverUpdatedAt,
            localUpdatedAt: localUpdatedAt,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RmkGoodsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RmkGoodsTable,
    RmkGood,
    $$RmkGoodsTableFilterComposer,
    $$RmkGoodsTableOrderingComposer,
    $$RmkGoodsTableAnnotationComposer,
    $$RmkGoodsTableCreateCompanionBuilder,
    $$RmkGoodsTableUpdateCompanionBuilder,
    (RmkGood, BaseReferences<_$AppDatabase, $RmkGoodsTable, RmkGood>),
    RmkGood,
    PrefetchHooks Function()>;
typedef $$RmkCategoriesTableCreateCompanionBuilder = RmkCategoriesCompanion
    Function({
  Value<int> id,
  Value<int?> parentId,
  required String name,
  required String normalizedName,
  Value<int> level,
  required DateTime localUpdatedAt,
});
typedef $$RmkCategoriesTableUpdateCompanionBuilder = RmkCategoriesCompanion
    Function({
  Value<int> id,
  Value<int?> parentId,
  Value<String> name,
  Value<String> normalizedName,
  Value<int> level,
  Value<DateTime> localUpdatedAt,
});

class $$RmkCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $RmkCategoriesTable> {
  $$RmkCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnFilters(column));
}

class $$RmkCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $RmkCategoriesTable> {
  $$RmkCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$RmkCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RmkCategoriesTable> {
  $$RmkCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
      column: $table.normalizedName, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt, builder: (column) => column);
}

class $$RmkCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RmkCategoriesTable,
    RmkCategory,
    $$RmkCategoriesTableFilterComposer,
    $$RmkCategoriesTableOrderingComposer,
    $$RmkCategoriesTableAnnotationComposer,
    $$RmkCategoriesTableCreateCompanionBuilder,
    $$RmkCategoriesTableUpdateCompanionBuilder,
    (
      RmkCategory,
      BaseReferences<_$AppDatabase, $RmkCategoriesTable, RmkCategory>
    ),
    RmkCategory,
    PrefetchHooks Function()> {
  $$RmkCategoriesTableTableManager(_$AppDatabase db, $RmkCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RmkCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RmkCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RmkCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> normalizedName = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<DateTime> localUpdatedAt = const Value.absent(),
          }) =>
              RmkCategoriesCompanion(
            id: id,
            parentId: parentId,
            name: name,
            normalizedName: normalizedName,
            level: level,
            localUpdatedAt: localUpdatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            required String name,
            required String normalizedName,
            Value<int> level = const Value.absent(),
            required DateTime localUpdatedAt,
          }) =>
              RmkCategoriesCompanion.insert(
            id: id,
            parentId: parentId,
            name: name,
            normalizedName: normalizedName,
            level: level,
            localUpdatedAt: localUpdatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RmkCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RmkCategoriesTable,
    RmkCategory,
    $$RmkCategoriesTableFilterComposer,
    $$RmkCategoriesTableOrderingComposer,
    $$RmkCategoriesTableAnnotationComposer,
    $$RmkCategoriesTableCreateCompanionBuilder,
    $$RmkCategoriesTableUpdateCompanionBuilder,
    (
      RmkCategory,
      BaseReferences<_$AppDatabase, $RmkCategoriesTable, RmkCategory>
    ),
    RmkCategory,
    PrefetchHooks Function()>;
typedef $$RmkCartItemsTableCreateCompanionBuilder = RmkCartItemsCompanion
    Function({
  Value<int> goodId,
  required String name,
  Value<double> quantity,
  Value<double> price,
  Value<double?> customTotal,
  Value<String?> imageUrl,
  required DateTime updatedAt,
});
typedef $$RmkCartItemsTableUpdateCompanionBuilder = RmkCartItemsCompanion
    Function({
  Value<int> goodId,
  Value<String> name,
  Value<double> quantity,
  Value<double> price,
  Value<double?> customTotal,
  Value<String?> imageUrl,
  Value<DateTime> updatedAt,
});

class $$RmkCartItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RmkCartItemsTable> {
  $$RmkCartItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get goodId => $composableBuilder(
      column: $table.goodId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get customTotal => $composableBuilder(
      column: $table.customTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$RmkCartItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RmkCartItemsTable> {
  $$RmkCartItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get goodId => $composableBuilder(
      column: $table.goodId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get customTotal => $composableBuilder(
      column: $table.customTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RmkCartItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RmkCartItemsTable> {
  $$RmkCartItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get goodId =>
      $composableBuilder(column: $table.goodId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get customTotal => $composableBuilder(
      column: $table.customTotal, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RmkCartItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RmkCartItemsTable,
    RmkCartItem,
    $$RmkCartItemsTableFilterComposer,
    $$RmkCartItemsTableOrderingComposer,
    $$RmkCartItemsTableAnnotationComposer,
    $$RmkCartItemsTableCreateCompanionBuilder,
    $$RmkCartItemsTableUpdateCompanionBuilder,
    (
      RmkCartItem,
      BaseReferences<_$AppDatabase, $RmkCartItemsTable, RmkCartItem>
    ),
    RmkCartItem,
    PrefetchHooks Function()> {
  $$RmkCartItemsTableTableManager(_$AppDatabase db, $RmkCartItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RmkCartItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RmkCartItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RmkCartItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> goodId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double?> customTotal = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              RmkCartItemsCompanion(
            goodId: goodId,
            name: name,
            quantity: quantity,
            price: price,
            customTotal: customTotal,
            imageUrl: imageUrl,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> goodId = const Value.absent(),
            required String name,
            Value<double> quantity = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double?> customTotal = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            required DateTime updatedAt,
          }) =>
              RmkCartItemsCompanion.insert(
            goodId: goodId,
            name: name,
            quantity: quantity,
            price: price,
            customTotal: customTotal,
            imageUrl: imageUrl,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RmkCartItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RmkCartItemsTable,
    RmkCartItem,
    $$RmkCartItemsTableFilterComposer,
    $$RmkCartItemsTableOrderingComposer,
    $$RmkCartItemsTableAnnotationComposer,
    $$RmkCartItemsTableCreateCompanionBuilder,
    $$RmkCartItemsTableUpdateCompanionBuilder,
    (
      RmkCartItem,
      BaseReferences<_$AppDatabase, $RmkCartItemsTable, RmkCartItem>
    ),
    RmkCartItem,
    PrefetchHooks Function()>;
typedef $$RmkOutboxSalesTableCreateCompanionBuilder = RmkOutboxSalesCompanion
    Function({
  required String id,
  required String payload,
  required String idempotencyKey,
  required String status,
  Value<int> attemptCount,
  Value<String?> lastError,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$RmkOutboxSalesTableUpdateCompanionBuilder = RmkOutboxSalesCompanion
    Function({
  Value<String> id,
  Value<String> payload,
  Value<String> idempotencyKey,
  Value<String> status,
  Value<int> attemptCount,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$RmkOutboxSalesTableFilterComposer
    extends Composer<_$AppDatabase, $RmkOutboxSalesTable> {
  $$RmkOutboxSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$RmkOutboxSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $RmkOutboxSalesTable> {
  $$RmkOutboxSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RmkOutboxSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RmkOutboxSalesTable> {
  $$RmkOutboxSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RmkOutboxSalesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RmkOutboxSalesTable,
    RmkOutboxSale,
    $$RmkOutboxSalesTableFilterComposer,
    $$RmkOutboxSalesTableOrderingComposer,
    $$RmkOutboxSalesTableAnnotationComposer,
    $$RmkOutboxSalesTableCreateCompanionBuilder,
    $$RmkOutboxSalesTableUpdateCompanionBuilder,
    (
      RmkOutboxSale,
      BaseReferences<_$AppDatabase, $RmkOutboxSalesTable, RmkOutboxSale>
    ),
    RmkOutboxSale,
    PrefetchHooks Function()> {
  $$RmkOutboxSalesTableTableManager(
      _$AppDatabase db, $RmkOutboxSalesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RmkOutboxSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RmkOutboxSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RmkOutboxSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> idempotencyKey = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RmkOutboxSalesCompanion(
            id: id,
            payload: payload,
            idempotencyKey: idempotencyKey,
            status: status,
            attemptCount: attemptCount,
            lastError: lastError,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String payload,
            required String idempotencyKey,
            required String status,
            Value<int> attemptCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RmkOutboxSalesCompanion.insert(
            id: id,
            payload: payload,
            idempotencyKey: idempotencyKey,
            status: status,
            attemptCount: attemptCount,
            lastError: lastError,
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

typedef $$RmkOutboxSalesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RmkOutboxSalesTable,
    RmkOutboxSale,
    $$RmkOutboxSalesTableFilterComposer,
    $$RmkOutboxSalesTableOrderingComposer,
    $$RmkOutboxSalesTableAnnotationComposer,
    $$RmkOutboxSalesTableCreateCompanionBuilder,
    $$RmkOutboxSalesTableUpdateCompanionBuilder,
    (
      RmkOutboxSale,
      BaseReferences<_$AppDatabase, $RmkOutboxSalesTable, RmkOutboxSale>
    ),
    RmkOutboxSale,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedRecordsTableTableManager get cachedRecords =>
      $$CachedRecordsTableTableManager(_db, _db.cachedRecords);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
  $$OutboxOperationsTableTableManager get outboxOperations =>
      $$OutboxOperationsTableTableManager(_db, _db.outboxOperations);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$RmkGoodsTableTableManager get rmkGoods =>
      $$RmkGoodsTableTableManager(_db, _db.rmkGoods);
  $$RmkCategoriesTableTableManager get rmkCategories =>
      $$RmkCategoriesTableTableManager(_db, _db.rmkCategories);
  $$RmkCartItemsTableTableManager get rmkCartItems =>
      $$RmkCartItemsTableTableManager(_db, _db.rmkCartItems);
  $$RmkOutboxSalesTableTableManager get rmkOutboxSales =>
      $$RmkOutboxSalesTableTableManager(_db, _db.rmkOutboxSales);
}

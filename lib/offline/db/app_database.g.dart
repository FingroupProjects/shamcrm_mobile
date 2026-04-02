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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedRecordsTable cachedRecords = $CachedRecordsTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  late final $OutboxOperationsTable outboxOperations =
      $OutboxOperationsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cachedRecords, syncStates, outboxOperations, chatMessages];
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
}

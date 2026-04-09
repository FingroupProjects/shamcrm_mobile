import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class CachedRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get module => text()();
  TextColumn get cacheKey => text()();
  TextColumn get payload => text()();
  TextColumn get entityVersion => text().nullable()();
  TextColumn get deltaToken => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {module, cacheKey},
      ];
}

class SyncStates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get module => text()();
  TextColumn get scope => text()();
  TextColumn get deltaToken => text().nullable()();
  IntColumn get sinceMessageId => integer().nullable()();
  TextColumn get entityVersion => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {module, scope},
      ];
}

class OutboxOperations extends Table {
  TextColumn get id => text()();
  TextColumn get module => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operationType => text()();
  TextColumn get payload => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get status => text()();
  IntColumn get priority => integer()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get conflictPayload => text().nullable()();
  BoolColumn get requiresTextOnly => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ChatMessages extends Table {
  TextColumn get localId => text()();
  IntColumn get chatId => integer()();
  IntColumn get serverMessageId => integer().nullable()();
  TextColumn get payload => text()();
  TextColumn get syncStatus => text()();
  BoolColumn get isOutgoing => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

@DriftDatabase(
  tables: [
    CachedRecords,
    SyncStates,
    OutboxOperations,
    ChatMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor);

  static AppDatabase? _instance;

  factory AppDatabase() {
    return _instance ??= AppDatabase._(_openConnection());
  }

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'shamcrm_offline.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

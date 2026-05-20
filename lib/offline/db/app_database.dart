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
  BoolColumn get requiresTextOnly =>
      boolean().withDefault(const Constant(false))();
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

class RmkGoods extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get categoryName => text().nullable()();
  IntColumn get parentCategoryId => integer().nullable()();
  RealColumn get price => real().withDefault(const Constant(0))();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get payload => text()();
  DateTimeColumn get serverCreatedAt => dateTime().nullable()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get localUpdatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RmkCategories extends Table {
  IntColumn get id => integer()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  IntColumn get level => integer().withDefault(const Constant(0))();
  DateTimeColumn get localUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RmkCartItems extends Table {
  IntColumn get goodId => integer()();
  TextColumn get name => text()();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  RealColumn get price => real().withDefault(const Constant(0))();
  RealColumn get customTotal => real().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {goodId};
}

class RmkOutboxSales extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get status => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    CachedRecords,
    SyncStates,
    OutboxOperations,
    ChatMessages,
    RmkGoods,
    RmkCategories,
    RmkCartItems,
    RmkOutboxSales,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor);

  static AppDatabase? _instance;

  factory AppDatabase() {
    return _instance ??= AppDatabase._(_openConnection());
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(rmkGoods);
            await m.createTable(rmkCategories);
            await m.createTable(rmkCartItems);
            await m.createTable(rmkOutboxSales);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'shamcrm_offline.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

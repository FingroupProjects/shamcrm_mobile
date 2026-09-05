import 'dart:convert';

import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:drift/drift.dart';

class LocalCacheEntry {
  const LocalCacheEntry({
    required this.payload,
    this.entityVersion,
    this.deltaToken,
    this.lastSyncedAt,
  });

  final String payload;
  final String? entityVersion;
  final String? deltaToken;
  final DateTime? lastSyncedAt;
}

class LocalCacheRepository {
  LocalCacheRepository(this._database);

  final AppDatabase _database;

  Future<LocalCacheEntry?> read({
    required String module,
    required String cacheKey,
  }) async {
    final row = await (_database.select(_database.cachedRecords)
          ..where((tbl) => tbl.module.equals(module) & tbl.cacheKey.equals(cacheKey)))
        .getSingleOrNull();

    if (row == null) {
      return null;
    }

    return LocalCacheEntry(
      payload: row.payload,
      entityVersion: row.entityVersion,
      deltaToken: row.deltaToken,
      lastSyncedAt: row.lastSyncedAt,
    );
  }

  Future<void> write({
    required String module,
    required String cacheKey,
    required Object payload,
    String? entityVersion,
    String? deltaToken,
    DateTime? lastSyncedAt,
  }) async {
    final now = DateTime.now();
    final encodedPayload = jsonEncode(payload);

    await _database.transaction(() async {
      final existing = await (_database.select(_database.cachedRecords)
            ..where(
              (tbl) => tbl.module.equals(module) & tbl.cacheKey.equals(cacheKey),
            ))
          .getSingleOrNull();

      if (existing == null) {
        await _database.into(_database.cachedRecords).insert(
              CachedRecordsCompanion.insert(
                module: module,
                cacheKey: cacheKey,
                payload: encodedPayload,
                entityVersion: Value(entityVersion),
                deltaToken: Value(deltaToken),
                createdAt: now,
                updatedAt: now,
                lastSyncedAt: Value(lastSyncedAt),
              ),
            );
        return;
      }

      await (_database.update(_database.cachedRecords)
            ..where((tbl) => tbl.id.equals(existing.id)))
          .write(
        CachedRecordsCompanion(
          payload: Value(encodedPayload),
          entityVersion: Value(entityVersion),
          deltaToken: Value(deltaToken),
          isDeleted: const Value(false),
          updatedAt: Value(now),
          lastSyncedAt: Value(lastSyncedAt),
        ),
      );
    });
  }

  Future<void> clearModule(String module) async {
    await (_database.delete(_database.cachedRecords)
          ..where((tbl) => tbl.module.equals(module)))
        .go();
  }

  Future<List<({String cacheKey, LocalCacheEntry entry})>> readAllByModule(
    String module,
  ) async {
    final rows = await (_database.select(_database.cachedRecords)
          ..where(
            (tbl) => tbl.module.equals(module) & tbl.isDeleted.equals(false),
          ))
        .get();

    return rows
        .map(
          (row) => (
            cacheKey: row.cacheKey,
            entry: LocalCacheEntry(
              payload: row.payload,
              entityVersion: row.entityVersion,
              deltaToken: row.deltaToken,
              lastSyncedAt: row.lastSyncedAt,
            ),
          ),
        )
        .toList(growable: false);
  }
}

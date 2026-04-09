import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/offline/core/local_operation_status.dart';
import 'package:crm_task_manager/offline/core/network_policy.dart';
import 'package:crm_task_manager/offline/core/network_profile_service.dart';
import 'package:crm_task_manager/offline/core/offline_module.dart';
import 'package:crm_task_manager/offline/core/offline_telemetry_service.dart';
import 'package:crm_task_manager/offline/core/request_priority.dart';
import 'package:crm_task_manager/offline/core/request_scheduler.dart';
import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:drift/drift.dart' hide Column;

typedef OutboxExecutor = Future<void> Function(OutboxOperationRecord operation);

class OutboxOperationRecord {
  const OutboxOperationRecord({
    required this.id,
    required this.module,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.idempotencyKey,
    required this.status,
    required this.priority,
    required this.attemptCount,
    required this.nextAttemptAt,
    required this.lastError,
    required this.conflictPayload,
    required this.requiresTextOnly,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final OfflineModule module;
  final String entityType;
  final String entityId;
  final String operationType;
  final Map<String, dynamic> payload;
  final String idempotencyKey;
  final LocalOperationStatus status;
  final RequestPriority priority;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final String? conflictPayload;
  final bool requiresTextOnly;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory OutboxOperationRecord.fromRow(OutboxOperation row) {
    return OutboxOperationRecord(
      id: row.id,
      module: OfflineModule.values.firstWhere(
        (item) => item.value == row.module,
        orElse: () => OfflineModule.referenceData,
      ),
      entityType: row.entityType,
      entityId: row.entityId,
      operationType: row.operationType,
      payload: jsonDecode(row.payload) as Map<String, dynamic>,
      idempotencyKey: row.idempotencyKey,
      status: LocalOperationStatusX.fromValue(row.status),
      priority: RequestPriority.values.firstWhere(
        (item) => item.weight == row.priority,
        orElse: () => RequestPriority.normal,
      ),
      attemptCount: row.attemptCount,
      nextAttemptAt: row.nextAttemptAt,
      lastError: row.lastError,
      conflictPayload: row.conflictPayload,
      requiresTextOnly: row.requiresTextOnly,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

class OutboxService {
  OutboxService({
    required AppDatabase database,
    required this.scheduler,
    required this.networkProfileService,
    required this.telemetryService,
  }) : _database = database;

  final AppDatabase _database;
  final RequestScheduler scheduler;
  final NetworkProfileService networkProfileService;
  final OfflineTelemetryService telemetryService;

  final Map<OfflineModule, OutboxExecutor> _executors = {};
  bool _isProcessing = false;

  Future<void> initialize() async {
    telemetryService.setOutboxDepth(await pendingCount());
    networkProfileService.profileStream.listen((profile) {
      if (profile.isOnline) {
        unawaited(processPending());
      }
    });
  }

  void registerExecutor(OfflineModule module, OutboxExecutor executor) {
    _executors[module] = executor;
  }

  Future<void> enqueue({
    required String id,
    required OfflineModule module,
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    RequestPriority priority = RequestPriority.high,
    bool requiresTextOnly = false,
  }) async {
    final now = DateTime.now();
    await _database.into(_database.outboxOperations).insertOnConflictUpdate(
          OutboxOperationsCompanion.insert(
            id: id,
            module: module.value,
            entityType: entityType,
            entityId: entityId,
            operationType: operationType,
            payload: jsonEncode(payload),
            idempotencyKey: idempotencyKey,
            status: LocalOperationStatus.pending.value,
            priority: priority.weight,
            requiresTextOnly: Value(requiresTextOnly),
            createdAt: now,
            updatedAt: now,
          ),
        );
    telemetryService.setOutboxDepth(await pendingCount());
    if (networkProfileService.currentProfile.isOnline) {
      unawaited(processPending());
    }
  }

  Future<int> pendingCount() async {
    final countExpression = _database.outboxOperations.id.count();
    final query = _database.selectOnly(_database.outboxOperations)
      ..addColumns([countExpression])
      ..where(
        _database.outboxOperations.status.equals(LocalOperationStatus.pending.value) |
            _database.outboxOperations.status.equals(LocalOperationStatus.failed.value),
      );
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<List<OutboxOperationRecord>> pendingOperations() async {
    final now = DateTime.now();
    final rows = await (_database.select(_database.outboxOperations)
          ..where(
            (tbl) =>
                (tbl.status.equals(LocalOperationStatus.pending.value) |
                    tbl.status.equals(LocalOperationStatus.failed.value)) &
                (tbl.nextAttemptAt.isNull() | tbl.nextAttemptAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.priority),
            (tbl) => OrderingTerm(expression: tbl.createdAt),
          ]))
        .get();
    return rows.map(OutboxOperationRecord.fromRow).toList(growable: false);
  }

  Future<void> processPending() async {
    if (_isProcessing || !networkProfileService.currentProfile.isOnline) {
      return;
    }
    _isProcessing = true;
    try {
      final operations = await pendingOperations();
      for (final operation in operations) {
        final executor = _executors[operation.module];
        if (executor == null) {
          continue;
        }
        await scheduler.schedule<void>(
          priority: operation.priority,
          task: () => _syncOperation(operation, executor),
        );
      }
    } finally {
      _isProcessing = false;
      telemetryService.setOutboxDepth(await pendingCount());
    }
  }

  Future<void> markConflict({
    required String operationId,
    required String conflictPayload,
  }) async {
    await (_database.update(_database.outboxOperations)
          ..where((tbl) => tbl.id.equals(operationId)))
        .write(
      OutboxOperationsCompanion(
        status: Value(LocalOperationStatus.conflict.value),
        conflictPayload: Value(conflictPayload),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _syncOperation(
    OutboxOperationRecord operation,
    OutboxExecutor executor,
  ) async {
    final now = DateTime.now();
    await (_database.update(_database.outboxOperations)
          ..where((tbl) => tbl.id.equals(operation.id)))
        .write(
      OutboxOperationsCompanion(
        status: Value(LocalOperationStatus.syncing.value),
        updatedAt: Value(now),
      ),
    );

    try {
      await executor(operation);
      telemetryService.recordSyncResult(true);
      await (_database.update(_database.outboxOperations)
            ..where((tbl) => tbl.id.equals(operation.id)))
          .write(
        OutboxOperationsCompanion(
          status: Value(LocalOperationStatus.synced.value),
          updatedAt: Value(DateTime.now()),
          lastError: const Value(null),
          nextAttemptAt: const Value(null),
        ),
      );
    } catch (error) {
      final policy = NetworkPolicy.forRequest(
        priority: operation.priority,
        profile: networkProfileService.currentProfile,
      );
      telemetryService.recordSyncResult(false);
      final nextAttemptAt =
          DateTime.now().add(policy.backoffForAttempt(operation.attemptCount));
      await (_database.update(_database.outboxOperations)
            ..where((tbl) => tbl.id.equals(operation.id)))
          .write(
        OutboxOperationsCompanion(
          status: Value(LocalOperationStatus.failed.value),
          attemptCount: Value(operation.attemptCount + 1),
          updatedAt: Value(DateTime.now()),
          lastError: Value(error.toString()),
          nextAttemptAt: Value(nextAttemptAt),
        ),
      );
    }
  }
}

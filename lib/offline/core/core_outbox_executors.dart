import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/offline/core/offline_module.dart';
import 'package:crm_task_manager/offline/core/offline_runtime.dart';

class CoreOutboxExecutors {
  CoreOutboxExecutors._();

  static void register(ApiService apiService) {
    final outbox = OfflineRuntime.instance.outboxService;

    outbox.registerExecutor(OfflineModule.lead, (operation) async {
      switch (operation.operationType) {
        case 'create':
          await apiService.createLeadWithData(operation.payload['data']);
          return;
        case 'update':
          await apiService.updateLeadWithData(
            leadId: operation.payload['leadId'] as int,
            data: Map<String, dynamic>.from(
              operation.payload['data'] as Map,
            ),
          );
          return;
      }
    });

    outbox.registerExecutor(OfflineModule.deal, (operation) async {
      final payload = operation.payload;
      switch (operation.operationType) {
        case 'create':
          await apiService.createDeal(
            name: payload['name']?.toString() ?? '',
            dealStatusId: payload['dealStatusId'] as int,
            managerId: payload['managerId'] as int?,
            startDate: _parseDate(payload['startDate']),
            endDate: _parseDate(payload['endDate']),
            sum: payload['sum']?.toString() ?? '0',
            description: payload['description']?.toString(),
            dealtypeId: payload['dealtypeId'] as int?,
            leadId: payload['leadId'] as int?,
            customFields: _mapList(payload['customFields']),
            directoryValues: _mapIntList(payload['directoryValues']),
            userIds: (payload['userIds'] as List?)?.cast<int>(),
          );
          return;
        case 'update':
          await apiService.updateDeal(
            dealId: payload['dealId'] as int,
            name: payload['name']?.toString() ?? '',
            dealStatusId: payload['dealStatusId'] as int,
            managerId: payload['managerId'] as int?,
            startDate: _parseDate(payload['startDate']),
            endDate: _parseDate(payload['endDate']),
            sum: payload['sum']?.toString() ?? '0',
            description: payload['description']?.toString(),
            dealtypeId: payload['dealtypeId'] as int?,
            leadId: payload['leadId'] as int?,
            customFields: _mapList(payload['customFields']),
            directoryValues: _mapIntList(payload['directoryValues']),
            dealStatusIds: (payload['dealStatusIds'] as List?)?.cast<int>(),
            existingFiles: (payload['existingFiles'] as List?)?.cast<int>(),
            userIds: (payload['userIds'] as List?)?.cast<int>(),
          );
          return;
      }
    });

    outbox.registerExecutor(OfflineModule.task, (operation) async {
      final payload = operation.payload;
      switch (operation.operationType) {
        case 'create':
          await apiService.createTask(
            name: payload['name']?.toString() ?? '',
            statusId: payload['statusId'] as int?,
            taskStatusId: payload['taskStatusId'] as int?,
            priority: payload['priority'] as int?,
            startDate: _parseDate(payload['startDate']),
            endDate: _parseDate(payload['endDate']),
            projectId: payload['projectId'] as int?,
            userId: (payload['userId'] as List?)?.cast<int>(),
            description: payload['description']?.toString(),
            customFields: _mapList(payload['customFields']),
            directoryValues: _mapIntList(payload['directoryValues']),
          );
          return;
        case 'update':
          await apiService.updateTask(
            taskId: payload['taskId'] as int,
            name: payload['name']?.toString() ?? '',
            taskStatusId: payload['taskStatusId'] as int,
            priority: payload['priority']?.toString(),
            startDate: _parseDate(payload['startDate']),
            endDate: _parseDate(payload['endDate']),
            projectId: payload['projectId'] as int?,
            userId: (payload['userId'] as List?)?.cast<int>(),
            description: payload['description']?.toString(),
            customFields: _mapList(payload['customFields']),
            filePaths: (payload['filePaths'] as List?)?.cast<String>(),
            directoryValues: _mapIntList(payload['directoryValues']),
          );
          return;
      }
    });

    outbox.registerExecutor(OfflineModule.chatList, (operation) async {
      if (operation.operationType == 'delete') {
        await apiService.deleteChat(operation.payload['chatId'] as int);
      }
    });
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw;
    }
    return DateTime.tryParse(raw.toString());
  }

  static List<Map<String, dynamic>>? _mapList(dynamic raw) {
    if (raw is! List) {
      return null;
    }
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static List<Map<String, int>>? _mapIntList(dynamic raw) {
    if (raw is! List) {
      return null;
    }
    return raw.whereType<Map>().map((item) {
      return item.map(
        (key, value) => MapEntry(
          key.toString(),
          value is int ? value : int.tryParse(value.toString()) ?? 0,
        ),
      );
    }).toList(growable: false);
  }
}

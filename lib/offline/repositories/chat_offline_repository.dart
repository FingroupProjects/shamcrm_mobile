import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/pagination_dto.dart';
import 'package:crm_task_manager/offline/core/local_cache_repository.dart';
import 'package:crm_task_manager/offline/core/offline_module.dart';
import 'package:crm_task_manager/offline/core/offline_runtime.dart';
import 'package:crm_task_manager/offline/core/request_priority.dart';
import 'package:flutter/foundation.dart';

class ChatOfflineRepository {
  ChatOfflineRepository({
    required ApiService apiService,
    required LocalCacheRepository? cacheRepository,
  })  : _apiService = apiService,
        _cacheRepository = cacheRepository;

  factory ChatOfflineRepository.fromRuntime(ApiService apiService) {
    final runtime = OfflineRuntime.maybeInstance;
    return ChatOfflineRepository(
      apiService: apiService,
      cacheRepository: runtime?.localCacheRepository,
    );
  }

  final ApiService _apiService;
  final LocalCacheRepository? _cacheRepository;

  String _cacheKey({
    required String endPoint,
    required int page,
    String? query,
    int? salesFunnelId,
    Map<String, dynamic>? filters,
  }) {
    return jsonEncode({
      'endpoint': endPoint,
      'page': page,
      'query': query,
      'salesFunnelId': salesFunnelId,
      'filters': filters,
    });
  }

  Future<PaginationDTO<Chats>?> readCachedChats({
    required String endPoint,
    required int page,
    String? query,
    int? salesFunnelId,
    Map<String, dynamic>? filters,
  }) async {
    final cacheRepository = _cacheRepository;
    if (cacheRepository == null) {
      return null;
    }

    final entry = await cacheRepository.read(
      module: OfflineModule.chatList.value,
      cacheKey: _cacheKey(
        endPoint: endPoint,
        page: page,
        query: query,
        salesFunnelId: salesFunnelId,
        filters: filters,
      ),
    );
    if (entry == null) {
      return null;
    }

    final decoded = jsonDecode(entry.payload) as Map<String, dynamic>;
    final data = (decoded['data'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_chatFromCacheJson)
        .toList(growable: false);
    final pagination =
        decoded['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return PaginationDTO<Chats>(
      data: data,
      count: pagination['count'] as int? ?? data.length,
      total: pagination['total'] as int? ?? data.length,
      perPage: pagination['per_page'] as int? ?? data.length,
      currentPage: pagination['current_page'] as int? ?? page,
      totalPage: pagination['total_pages'] as int? ?? 1,
    );
  }

  Future<PaginationDTO<Chats>> refreshChats({
    required String endPoint,
    required int page,
    String? query,
    int? salesFunnelId,
    Map<String, dynamic>? filters,
  }) async {
    final runtime = OfflineRuntime.maybeInstance;
    final scheduler = runtime?.requestScheduler;
    final result = scheduler != null
        ? await scheduler.schedule(
            priority: RequestPriority.high,
            task: () => _apiService.getAllChats(
              endPoint,
              page,
              query,
              salesFunnelId,
              filters,
            ),
          )
        : await _apiService.getAllChats(
            endPoint,
            page,
            query,
            salesFunnelId,
            filters,
          );

    final cacheRepository = _cacheRepository;
    if (cacheRepository != null) {
      await cacheRepository.write(
        module: OfflineModule.chatList.value,
        cacheKey: _cacheKey(
          endPoint: endPoint,
          page: page,
          query: query,
          salesFunnelId: salesFunnelId,
          filters: filters,
        ),
        payload: _serialize(result),
        lastSyncedAt: DateTime.now(),
      );
    } else {
      debugPrint(
          'ChatOfflineRepository: OfflineRuntime недоступен, пропускаем сохранение кэша');
    }

    return result;
  }

  Future<PaginationDTO<Chats>?> getStaleWhileRevalidate({
    required String endPoint,
    required int page,
    String? query,
    int? salesFunnelId,
    Map<String, dynamic>? filters,
    ValueChanged<PaginationDTO<Chats>>? onFreshData,
  }) async {
    final cached = await readCachedChats(
      endPoint: endPoint,
      page: page,
      query: query,
      salesFunnelId: salesFunnelId,
      filters: filters,
    );
    if (cached != null && onFreshData != null) {
      Future<void>(() async {
        try {
          final fresh = await refreshChats(
            endPoint: endPoint,
            page: page,
            query: query,
            salesFunnelId: salesFunnelId,
            filters: filters,
          );
          onFreshData(fresh);
        } catch (_) {}
      });
    }
    return cached;
  }

  Map<String, dynamic> _serialize(PaginationDTO<Chats> pagination) {
    return {
      'data': pagination.data.map(_chatToCacheJson).toList(),
      'pagination': {
        'count': pagination.count,
        'total': pagination.total,
        'per_page': pagination.perPage,
        'current_page': pagination.currentPage,
        'total_pages': pagination.totalPage,
      },
    };
  }

  Map<String, dynamic> _chatToCacheJson(Chats chat) {
    return {
      'id': chat.id,
      'uniqueId': chat.uniqueId,
      'name': chat.name,
      'image': chat.image,
      'taskFrom': chat.taskFrom,
      'taskTo': chat.taskTo,
      'description': chat.description,
      'channel': chat.channel,
      'lastMessage': chat.lastMessage,
      'messageType': chat.messageType,
      'createDate': chat.createDate,
      'unreadCount': chat.unreadCount,
      'canSendMessage': chat.canSendMessage,
      'type': chat.type,
      'customName': chat.customName,
      'customImage': chat.customImage,
    };
  }

  Chats _chatFromCacheJson(Map<String, dynamic> json) {
    return Chats(
      id: json['id'] as int? ?? 0,
      uniqueId: json['uniqueId'] as String?,
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      taskFrom: json['taskFrom']?.toString(),
      taskTo: json['taskTo']?.toString(),
      description: json['description']?.toString(),
      channel: json['channel']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      messageType: json['messageType']?.toString(),
      createDate: json['createDate']?.toString() ?? '',
      unreadCount: json['unreadCount'] as int? ?? 0,
      canSendMessage: json['canSendMessage'] == true,
      type: json['type']?.toString(),
      chatUsers: const [],
      customName: json['customName']?.toString(),
      customImage: json['customImage']?.toString(),
    );
  }
}

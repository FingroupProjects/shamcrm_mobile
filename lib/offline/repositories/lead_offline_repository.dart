import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/offline/core/local_cache_repository.dart';
import 'package:crm_task_manager/offline/core/offline_module.dart';
import 'package:crm_task_manager/offline/core/offline_runtime.dart';
import 'package:crm_task_manager/offline/core/request_priority.dart';
import 'package:flutter/foundation.dart';

class LeadOfflineRepository {
  LeadOfflineRepository({
    required ApiService apiService,
    required LocalCacheRepository cacheRepository,
  })  : _apiService = apiService,
        _cacheRepository = cacheRepository;

  factory LeadOfflineRepository.fromRuntime(ApiService apiService) {
    return LeadOfflineRepository(
      apiService: apiService,
      cacheRepository: OfflineRuntime.instance.localCacheRepository,
    );
  }

  final ApiService _apiService;
  final LocalCacheRepository _cacheRepository;

  String _cacheKey({
    required int page,
    required bool showDebt,
    String? search,
  }) {
    final safeSearch = (search ?? '').trim();
    return 'page=$page|showDebt=$showDebt|search=$safeSearch';
  }

  Future<LeadsDataResponse?> readCachedPage({
    required int page,
    required bool showDebt,
    String? search,
  }) async {
    final entry = await _cacheRepository.read(
      module: OfflineModule.lead.value,
      cacheKey: _cacheKey(page: page, showDebt: showDebt, search: search),
    );
    if (entry == null) {
      return null;
    }

    final decoded = jsonDecode(entry.payload) as Map<String, dynamic>;
    return LeadsDataResponse.fromJson(decoded);
  }

  Future<LeadsDataResponse> refreshPage({
    required int page,
    required bool showDebt,
    String? search,
  }) async {
    final result = await OfflineRuntime.instance.requestScheduler.schedule(
      priority: RequestPriority.high,
      task: () => _apiService.getLeadPage(
        page,
        showDebt: showDebt,
        search: search,
      ),
    );

    await _cacheRepository.write(
      module: OfflineModule.lead.value,
      cacheKey: _cacheKey(page: page, showDebt: showDebt, search: search),
      payload: _serialize(result),
      lastSyncedAt: DateTime.now(),
    );

    return result;
  }

  Future<LeadsDataResponse?> getStaleWhileRevalidate({
    required int page,
    required bool showDebt,
    String? search,
    ValueChanged<LeadsDataResponse>? onFreshData,
  }) async {
    final cached = await readCachedPage(
      page: page,
      showDebt: showDebt,
      search: search,
    );

    if (cached != null && onFreshData != null) {
      Future<void>(() async {
        try {
          final fresh = await refreshPage(
            page: page,
            showDebt: showDebt,
            search: search,
          );
          onFreshData(fresh);
        } catch (_) {}
      });
    }

    return cached;
  }

  Future<void> clearCache() {
    return _cacheRepository.clearModule(OfflineModule.lead.value);
  }

  Map<String, dynamic> _serialize(LeadsDataResponse response) {
    return {
      'result': {
        'data': response.result?.map((item) => item.toJson()).toList() ?? [],
        'pagination': response.pagination?.toJson(),
      },
      'errors': response.errors,
    };
  }
}

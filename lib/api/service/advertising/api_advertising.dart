part of '../api_service.dart';

extension ApiAdvertisingX on ApiService {
  /// Получение сводной статистики Meta Ads
  Future<MetaAdsSummary> getMetaAdsSummary({
    required String dateFrom,
    required String dateTo,
    int? salesFunnelId,
    int? organizationId,
  }) async {
    try {
      final params = <String, String>{
        'date_from': dateFrom,
        'date_to': dateTo,
      };
      if (salesFunnelId != null) {
        params['sales_funnel_id'] = '$salesFunnelId';
      }
      if (organizationId != null) {
        params['organization_id'] = '$organizationId';
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final path = await _appendQueryParams('/meta-ads/summary?$query');
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final result = decoded['result'] as Map<String, dynamic>? ?? {};
        return MetaAdsSummary.fromJson(result);
      }
      throw Exception('Ошибка загрузки сводки Meta Ads: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiAdvertisingX.getMetaAdsSummary error: $e');
      }
      rethrow;
    }
  }

  /// Получение списка кампаний Meta Ads
  Future<Map<String, dynamic>> getMetaAdsCampaigns({
    required String dateFrom,
    required String dateTo,
    int? salesFunnelId,
    int? organizationId,
    int page = 1,
    int perPage = 50,
    String sortBy = 'spend',
    String sortDir = 'desc',
  }) async {
    try {
      final params = <String, String>{
        'date_from': dateFrom,
        'date_to': dateTo,
        'page': '$page',
        'per_page': '$perPage',
        'sort_by': sortBy,
        'sort_dir': sortDir,
      };
      if (salesFunnelId != null) {
        params['sales_funnel_id'] = '$salesFunnelId';
      }
      if (organizationId != null) {
        params['organization_id'] = '$organizationId';
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final path = await _appendQueryParams('/meta-ads/campaigns?$query');
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final result = decoded['result'] as Map<String, dynamic>? ?? {};
        final list = (result['data'] as List<dynamic>? ?? [])
            .map((e) => MetaAdsCampaign.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = result['pagination'] != null
            ? AdvertisingPagination.fromJson(result['pagination'] as Map<String, dynamic>)
            : (result['current_page'] != null
                ? AdvertisingPagination.fromJson(result)
                : null);
        return {
          'data': list,
          'pagination': pagination,
          'totals': result['totals'],
        };
      }
      throw Exception('Ошибка загрузки кампаний Meta Ads: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiAdvertisingX.getMetaAdsCampaigns error: $e');
      }
      rethrow;
    }
  }

  /// Получение групп объявлений Meta Ads
  Future<Map<String, dynamic>> getMetaAdsAdsets({
    required String dateFrom,
    required String dateTo,
    int? campaignId,
    int? salesFunnelId,
    int? organizationId,
    int page = 1,
    int perPage = 50,
    String sortBy = 'spend',
    String sortDir = 'desc',
  }) async {
    try {
      final params = <String, String>{
        'date_from': dateFrom,
        'date_to': dateTo,
        'page': '$page',
        'per_page': '$perPage',
        'sort_by': sortBy,
        'sort_dir': sortDir,
      };
      if (campaignId != null) {
        params['campaign_id'] = '$campaignId';
      }
      if (salesFunnelId != null) {
        params['sales_funnel_id'] = '$salesFunnelId';
      }
      if (organizationId != null) {
        params['organization_id'] = '$organizationId';
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final path = await _appendQueryParams('/meta-ads/adsets?$query');
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final result = decoded['result'] as Map<String, dynamic>? ?? {};
        final list = (result['data'] as List<dynamic>? ?? [])
            .map((e) => MetaAdsAdSet.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = result['pagination'] != null
            ? AdvertisingPagination.fromJson(result['pagination'] as Map<String, dynamic>)
            : (result['current_page'] != null
                ? AdvertisingPagination.fromJson(result)
                : null);
        return {
          'data': list,
          'pagination': pagination,
          'totals': result['totals'],
        };
      }
      throw Exception('Ошибка загрузки групп объявлений: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiAdvertisingX.getMetaAdsAdsets error: $e');
      }
      rethrow;
    }
  }

  /// Получение объявлений Meta Ads
  Future<Map<String, dynamic>> getMetaAdsAds({
    required String dateFrom,
    required String dateTo,
    int? campaignId,
    int? adsetId,
    int? salesFunnelId,
    int? organizationId,
    int page = 1,
    int perPage = 50,
    String sortBy = 'spend',
    String sortDir = 'desc',
  }) async {
    try {
      final params = <String, String>{
        'date_from': dateFrom,
        'date_to': dateTo,
        'page': '$page',
        'per_page': '$perPage',
        'sort_by': sortBy,
        'sort_dir': sortDir,
      };
      if (campaignId != null) {
        params['campaign_id'] = '$campaignId';
      }
      if (adsetId != null) {
        params['adset_id'] = '$adsetId';
      }
      if (salesFunnelId != null) {
        params['sales_funnel_id'] = '$salesFunnelId';
      }
      if (organizationId != null) {
        params['organization_id'] = '$organizationId';
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final path = await _appendQueryParams('/meta-ads/ads?$query');
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final result = decoded['result'] as Map<String, dynamic>? ?? {};
        final list = (result['data'] as List<dynamic>? ?? [])
            .map((e) => MetaAdsAd.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = result['pagination'] != null
            ? AdvertisingPagination.fromJson(result['pagination'] as Map<String, dynamic>)
            : (result['current_page'] != null
                ? AdvertisingPagination.fromJson(result)
                : null);
        return {
          'data': list,
          'pagination': pagination,
          'totals': result['totals'],
        };
      }
      throw Exception('Ошибка загрузки объявлений: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiAdvertisingX.getMetaAdsAds error: $e');
      }
      rethrow;
    }
  }

  /// Получение прочих рекламных кампаний (without_meta=1)
  Future<Map<String, dynamic>> getOtherAdvertisingCampaigns({
    int page = 1,
    int perPage = 20,
    int? salesFunnelId,
    int? organizationId,
    bool withoutMeta = true,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (withoutMeta) {
        params['without_meta'] = '1';
      }
      if (salesFunnelId != null) {
        params['sales_funnel_id'] = '$salesFunnelId';
      }
      if (organizationId != null) {
        params['organization_id'] = '$organizationId';
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final path = await _appendQueryParams('/advertising-campaigns?$query');
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final result = decoded['result'] as Map<String, dynamic>? ?? {};
        final list = (result['data'] as List<dynamic>? ?? [])
            .map((e) => OtherAdvertisingCampaign.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = result['pagination'] != null
            ? AdvertisingPagination.fromJson(result['pagination'] as Map<String, dynamic>)
            : (result['current_page'] != null
                ? AdvertisingPagination.fromJson(result)
                : null);
        return {
          'data': list,
          'pagination': pagination,
        };
      }
      throw Exception('Ошибка загрузки прочих кампаний: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiAdvertisingX.getOtherAdvertisingCampaigns error: $e');
      }
      rethrow;
    }
  }

  /// Получение всех рекламных кампаний из CRM (для сопоставления с мета)
  Future<List<OtherAdvertisingCampaign>> getAllCrmAdvertisingCampaigns({
    int? salesFunnelId,
    int? organizationId,
  }) async {
    try {
      final params = <String, String>{
        'per_page': '500',
      };
      if (salesFunnelId != null) {
        params['sales_funnel_id'] = '$salesFunnelId';
      }
      if (organizationId != null) {
        params['organization_id'] = '$organizationId';
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final path = await _appendQueryParams('/advertising-campaigns?$query');
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final result = decoded['result'] as Map<String, dynamic>? ?? {};
        return (result['data'] as List<dynamic>? ?? [])
            .map((e) => OtherAdvertisingCampaign.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiAdvertisingX.getAllCrmAdvertisingCampaigns error: $e');
      }
      return [];
    }
  }

  /// Получение аккаунтов Meta Ads
  Future<List<MetaAdsAccount>> getMetaAdsAccounts({
    int? salesFunnelId,
    int? organizationId,
  }) async {
    try {
      final params = <String, String>{};
      if (salesFunnelId != null) {
        params['sales_funnel_id'] = '$salesFunnelId';
      }
      if (organizationId != null) {
        params['organization_id'] = '$organizationId';
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final path = await _appendQueryParams('/meta-ads/accounts?$query');
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final result = decoded['result'] as Map<String, dynamic>? ?? {};
        return (result['accounts'] as List<dynamic>? ?? [])
            .map((e) => MetaAdsAccount.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiAdvertisingX.getMetaAdsAccounts error: $e');
      }
      return [];
    }
  }

  /// Синхронизация Meta Ads
  Future<bool> syncMetaAds({
    int? salesFunnelId,
    int? organizationId,
  }) async {
    try {
      final path = await _appendQueryParams('/meta-ads/sync');
      final response = await _postRequest(path, {
        if (salesFunnelId != null) 'sales_funnel_id': salesFunnelId,
        if (organizationId != null) 'organization_id': organizationId,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiAdvertisingX.syncMetaAds error: $e');
      }
      return false;
    }
  }

  /// Сохранение настроек лид-формы
  Future<bool> saveLeadFormSettings({
    required String formId,
    required int leadStatusId,
    List<int>? managerIds,
    bool appendAnswers = false,
  }) async {
    try {
      final path = await _appendQueryParams('/meta-ads/lead-forms/$formId');
      final response = await _postRequest(path, {
        'lead_status_id': leadStatusId,
        if (managerIds != null) 'manager_ids': managerIds,
        'append_answers': appendAnswers ? 1 : 0,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiAdvertisingX.saveLeadFormSettings error: $e');
      }
      return false;
    }
  }
}

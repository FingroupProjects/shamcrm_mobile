part of '../api_service.dart';

extension ApiLeadsX on ApiService {
  Future<LeadById> getLeadById(int leadId) async {
    try {
      final path = await _appendQueryParams('/lead/$leadId');
      //debugPrint('ApiService: getLeadById - Generated path: $path');

      final response = await _analyticsRequest(path, bypassCache: true);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic> jsonLead = decodedJson['result'];
        return LeadById.fromJson(jsonLead, jsonLead['leadStatus']['id']);
      } else {
        throw Exception('Ошибка загрузки лида ID!');
      }
    } catch (e) {
      //debugPrint('ApiService: getLeadById - Error:');
      throw Exception('Ошибка загрузки лида ID!');
    }
  }

  Future<Map<String, dynamic>> uniteLead(
    int leadId, {
    required int unitedLeadId,
  }) async {
    try {
      final organizationId = await getSelectedOrganization();
      final salesFunnelId = await getSelectedSalesFunnel();
      final path = await _appendQueryParams('/lead/unite/$leadId');
      final response = await _postRequest(
        path,
        {
          'lead_id': unitedLeadId,
          'organization_id': organizationId ?? '1',
          'sales_funnel_id': salesFunnelId ?? '1',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final message = (data is Map<String, dynamic> ? data['message'] : null)
                ?.toString() ??
            'Не удалось объединить лид';
        throw Exception(message);
      }

      throw Exception('Не удалось объединить лид');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> acceptLead(int leadId) async {
    try {
      final path = await _appendQueryParams('/lead/accept/$leadId');
      final response = await _postRequest(path, {});

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final message = (data is Map<String, dynamic> ? data['message'] : null)
                ?.toString() ??
            'Ошибка валидации при создании сделки';
        throw Exception(message);
      }

      throw Exception('Ошибка создания сделки из лида');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> declineLead(
    int leadId, {
    int? reasonForRefusalId,
    String? reasonForRefusal,
  }) async {
    try {
      final path = await _appendQueryParams('/lead/decline/$leadId');
      final payload = <String, dynamic>{
        if (reasonForRefusalId != null)
          'reason_for_refusal_id': reasonForRefusalId,
        if (reasonForRefusal != null && reasonForRefusal.trim().isNotEmpty)
          'reason_for_refusal': reasonForRefusal.trim(),
      };

      final response = await _postRequest(path, payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final message = (data is Map<String, dynamic> ? data['message'] : null)
                ?.toString() ??
            'Ошибка валидации при отказе лида';
        throw LeadStatusUpdateException(422, message);
      }

      throw Exception('Ошибка отказа от лида');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Lead>> getLeads(
    int? leadStatusId, {
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? managers,
    List<int>? regions,
    int? regionId,
    List<int>? cityIds,
    List<int>? sources,
    List<int>? channelIds,
    List<int>? advertisingCampaignIds,
    List<int>? reasonForRefusalIds,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    bool? hasSuccessDeals,
    bool? hasInProgressDeals,
    bool? hasFailureDeals,
    bool? hasNotices,
    bool? hasContact,
    bool? hasChat,
    bool? hasDeal,
    bool? hasOrders,
    int? daysWithoutActivity,
    int? numberOfDaysDeal,
    bool? hasNoReplies,
    bool? hasUnreadMessages,
    List<Map<String, dynamic>>? directoryValues,
    Map<String, List<String>>? customFieldFilters,
    int? salesFunnelId, // Новый параметр
    bool bypassAnalyticsCache = false,
  }) async {
    // Формируем базовый путь
    String path = '/lead?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getLeads - After _appendQueryParams: $path');
    }

    // // Добавляем sales_funnel_id из аргумента, если он передан
    // if (salesFunnelId != null) {
    //   path += '&sales_funnel_id=$salesFunnelId';
    // }

    bool hasFilters = (search != null && search.isNotEmpty) ||
        (managers != null && managers.isNotEmpty) ||
        (regions != null && regions.isNotEmpty) ||
        (regionId != null) ||
        (cityIds != null && cityIds.isNotEmpty) ||
        (sources != null && sources.isNotEmpty) ||
        (channelIds != null && channelIds.isNotEmpty) ||
        (advertisingCampaignIds != null && advertisingCampaignIds.isNotEmpty) ||
        (reasonForRefusalIds != null && reasonForRefusalIds.isNotEmpty) ||
        (fromDate != null) ||
        (toDate != null) ||
        (hasSuccessDeals == true) ||
        (hasInProgressDeals == true) ||
        (hasFailureDeals == true) ||
        (hasNotices == true) ||
        (hasContact == true) ||
        (hasChat == true) ||
        (hasDeal == true) ||
        (hasOrders == true) ||
        (hasNoReplies == true) ||
        (hasUnreadMessages == true) ||
        (daysWithoutActivity != null) ||
        (numberOfDaysDeal != null) ||
        (statuses != null) ||
        (directoryValues != null && directoryValues.isNotEmpty) ||
        (customFieldFilters != null && customFieldFilters.isNotEmpty);

    if (leadStatusId != null && !hasFilters) {
      path += '&lead_status_id=$leadStatusId';
    }

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    if (managers != null && managers.isNotEmpty) {
      for (int i = 0; i < managers.length; i++) {
        path += '&managers[$i]=${managers[i]}';
      }
    }
    if (regions != null && regions.isNotEmpty) {
      for (int i = 0; i < regions.length; i++) {
        path += '&regions[$i]=${regions[i]}';
      }
    }
    if (regionId != null) {
      path += '&region_id=$regionId';
    }
    if (cityIds != null && cityIds.isNotEmpty) {
      for (int i = 0; i < cityIds.length; i++) {
        path += '&city_id[$i]=${cityIds[i]}';
      }
    }
    if (sources != null && sources.isNotEmpty) {
      for (int i = 0; i < sources.length; i++) {
        path += '&sources[$i]=${sources[i]}';
      }
    }
    if (channelIds != null && channelIds.isNotEmpty) {
      for (int i = 0; i < channelIds.length; i++) {
        path += '&channels[$i]=${channelIds[i]}';
      }
    }
    if (advertisingCampaignIds != null && advertisingCampaignIds.isNotEmpty) {
      for (int i = 0; i < advertisingCampaignIds.length; i++) {
        path += '&campaign[$i]=${advertisingCampaignIds[i]}';
      }
    }
    if (reasonForRefusalIds != null && reasonForRefusalIds.isNotEmpty) {
      for (int i = 0; i < reasonForRefusalIds.length; i++) {
        path += '&reason_for_refusals[$i]=${reasonForRefusalIds[i]}';
      }
    }
    if (hasNoReplies == true) {
      path += '&hasNoReplies=1';
    }
    if (hasUnreadMessages == true) {
      path += '&hasUnreadMessages=1';
    }
    if (statuses != null) {
      path += '&lead_status_id=$statuses';
    }
    if (fromDate != null && toDate != null) {
      final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
      path += '&from=$formattedFromDate&to=$formattedToDate';
    }
    if (hasSuccessDeals == true) {
      path += '&hasSuccessDeals=1';
    }
    if (hasInProgressDeals == true) {
      path += '&hasInProgressDeals=1';
    }
    if (hasFailureDeals == true) {
      path += '&hasFailureDeals=1';
    }
    if (hasNotices == true) {
      path += '&hasNotices=1';
    }
    if (hasContact == true) {
      path += '&hasContact=1';
    }
    if (hasChat == true) {
      path += '&hasChat=1';
    }
    if (hasDeal == true) {
      path += '&withoutDeal=1';
    }
    if (hasOrders == true) {
      path += '&hasOrders=1';
    }
    if (daysWithoutActivity != null) {
      path += '&lastUpdate=$daysWithoutActivity';
    }
    if (numberOfDaysDeal != null) {
      path += '&numberOfDaysDeal=$numberOfDaysDeal';
    }
    if (directoryValues != null && directoryValues.isNotEmpty) {
      final Map<String, LinkedHashSet<String>> groupedDirectoryValues = {};

      for (final dynamic rawValue in directoryValues) {
        if (rawValue is! Map) {
          continue;
        }

        final Map value = rawValue;
        final directoryIdRaw = value['directory_id'];
        final entryIdRaw = value['entry_id'];

        if (directoryIdRaw == null || entryIdRaw == null) {
          continue;
        }

        final directoryId = directoryIdRaw.toString();
        final Iterable<String> entryIds = entryIdRaw is List
            ? entryIdRaw
                .where((entry) => entry != null && entry.toString().isNotEmpty)
                .map((entry) => entry.toString())
            : [entryIdRaw.toString()];

        if (entryIds.isEmpty) {
          continue;
        }

        final entries = groupedDirectoryValues.putIfAbsent(
          directoryId,
          () => LinkedHashSet<String>(),
        );
        entries.addAll(entryIds);
      }

      if (groupedDirectoryValues.isNotEmpty) {
        var directoryIndex = 0;
        groupedDirectoryValues.forEach((directoryId, entryIds) {
          if (entryIds.isEmpty) {
            return;
          }
          path +=
              '&directory_values[$directoryIndex][directory_id]=$directoryId';

          var entryIndex = 0;
          for (final entryId in entryIds) {
            path +=
                '&directory_values[$directoryIndex][entry_id][$entryIndex]=$entryId';
            entryIndex++;
          }

          directoryIndex++;
        });
      }
    }
    if (customFieldFilters != null && customFieldFilters.isNotEmpty) {
      int index = 0;
      customFieldFilters.forEach((fieldKey, values) {
        if (values.isEmpty) {
          return;
        }
        final encodedKey = Uri.encodeQueryComponent(fieldKey);
        path += '&custom_fields[$index][key]=$encodedKey';
        for (int i = 0; i < values.length; i++) {
          final encodedValue = Uri.encodeQueryComponent(values[i]);
          path += '&custom_fields[$index][value][$i]=$encodedValue';
        }
        index++;
      });
    }

    if (kDebugMode) {
      debugPrint('ApiService: getLeads - Final path: $path');
    }
    final response = await _analyticsRequest(
      path,
      bypassCache: bypassAnalyticsCache,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        final leadsData = data['result']['data'] as List;
        if (kDebugMode) {
          debugPrint('ApiService: getLeads loaded ${leadsData.length} leads');
        }
        return leadsData
            .map((json) => Lead.fromJson(json, leadStatusId ?? -1))
            .toList();
      } else {
        throw Exception('Данные лидов отсутствуют в ответе');
      }
    } else {
      throw Exception('Ошибка загрузки лидов!');
    }
  }

  Future<int> getLeadCountAll() async {
    final path = await _appendQueryParams('/lead/count-all');
    final response = await _getRequest(path);

    if (response.statusCode != 200) {
      throw Exception('Failed to load lead count');
    }

    final data = jsonDecode(response.body);
    final result = data['result'];

    if (result is int) return result;
    if (result is String) return int.tryParse(result) ?? 0;
    if (result is Map<String, dynamic>) {
      final dynamic count = result['count'] ??
          result['total'] ??
          result['all'] ??
          result['leads_count'];
      if (count is int) return count;
      if (count is String) return int.tryParse(count) ?? 0;
    }

    return 0;
  }

  Future<List<LeadStatus>> getLeadStatuses({
    List<int>? managers,
    List<int>? regions,
    int? regionId,
    List<int>? cityIds,
    List<int>? sources,
    List<int>? channelIds,
    List<int>? advertisingCampaignIds,
    List<int>? reasonForRefusalIds,
    DateTime? fromDate,
    DateTime? toDate,
    bool? hasSuccessDeals,
    bool? hasInProgressDeals,
    bool? hasFailureDeals,
    bool? hasNotices,
    bool? hasContact,
    bool? hasChat,
    bool? hasNoReplies,
    bool? hasUnreadMessages,
    bool? hasDeal,
    bool? hasOrders,
    int? daysWithoutActivity,
    int? numberOfDaysDeal,
    List<Map<String, dynamic>>? directoryValues,
    int? salesFunnelId,
    bool bypassAnalyticsCache = false,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();
    final effectiveSalesFunnelId =
        salesFunnelId?.toString() ?? await getSelectedSalesFunnel();

    if (organizationId == null ||
        organizationId.isEmpty ||
        organizationId == 'null') {
      throw Exception('Organization ID is required but missing');
    }

    if (kDebugMode) {
      debugPrint('🔍 getLeadStatuses - START WITH FILTERS');
      debugPrint('🔍 getLeadStatuses - organizationId: $organizationId');
      debugPrint(
          '🔍 getLeadStatuses - salesFunnelId: ${effectiveSalesFunnelId ?? "NULL"}');
    }

    final cacheKey =
        'cachedLeadStatuses_${organizationId}_funnel_${effectiveSalesFunnelId ?? "null"}';

    try {
      String path = '/lead/statuses?organization_id=$organizationId';

      if (effectiveSalesFunnelId != null &&
          effectiveSalesFunnelId.isNotEmpty &&
          effectiveSalesFunnelId != 'null') {
        path += '&sales_funnel_id=$effectiveSalesFunnelId';
      }

      // Добавляем фильтры к запросу статусов
      if (managers != null && managers.isNotEmpty) {
        for (int i = 0; i < managers.length; i++) {
          path += '&managers[$i]=${managers[i]}';
        }
      }
      if (regions != null && regions.isNotEmpty) {
        for (int i = 0; i < regions.length; i++) {
          path += '&regions[$i]=${regions[i]}';
        }
      }
      if (regionId != null) {
        path += '&region_id=$regionId';
      }
      if (cityIds != null && cityIds.isNotEmpty) {
        for (int i = 0; i < cityIds.length; i++) {
          path += '&city_id[$i]=${cityIds[i]}';
        }
      }
      if (sources != null && sources.isNotEmpty) {
        for (int i = 0; i < sources.length; i++) {
          path += '&sources[$i]=${sources[i]}';
        }
      }
      if (channelIds != null && channelIds.isNotEmpty) {
        for (int i = 0; i < channelIds.length; i++) {
          path += '&channels[$i]=${channelIds[i]}';
        }
      }
      if (advertisingCampaignIds != null && advertisingCampaignIds.isNotEmpty) {
        for (int i = 0; i < advertisingCampaignIds.length; i++) {
          path += '&campaign[$i]=${advertisingCampaignIds[i]}';
        }
      }
      if (reasonForRefusalIds != null && reasonForRefusalIds.isNotEmpty) {
        for (int i = 0; i < reasonForRefusalIds.length; i++) {
          path += '&reason_for_refusals[$i]=${reasonForRefusalIds[i]}';
        }
      }
      if (fromDate != null && toDate != null) {
        final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
        final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
        path += '&from=$formattedFromDate&to=$formattedToDate';
      }
      if (hasSuccessDeals == true) path += '&hasSuccessDeals=1';
      if (hasInProgressDeals == true) path += '&hasInProgressDeals=1';
      if (hasFailureDeals == true) path += '&hasFailureDeals=1';
      if (hasNotices == true) path += '&hasNotices=1';
      if (hasContact == true) path += '&hasContact=1';
      if (hasChat == true) path += '&hasChat=1';
      if (hasNoReplies == true) path += '&hasNoReplies=1';
      if (hasUnreadMessages == true) path += '&hasUnreadMessages=1';
      if (hasDeal == true) path += '&withoutDeal=1';
      if (hasOrders == true) path += '&hasOrders=1';
      if (daysWithoutActivity != null)
        path += '&lastUpdate=$daysWithoutActivity';
      if (numberOfDaysDeal != null)
        path += '&numberOfDaysDeal=$numberOfDaysDeal';
      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          final directoryId = directoryValues[i]['directory_id'];
          final entryId = directoryValues[i]['entry_id'];
          path += '&directory_values[$i][directory_id]=$directoryId';
          path += '&directory_values[$i][entry_id]=$entryId';
        }
      }

      if (kDebugMode) {
        debugPrint('📤 getLeadStatuses WITH FILTERS - Final path: $path');
      }

      final response = await _analyticsRequest(
        path,
        bypassCache: bypassAnalyticsCache,
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка ${response.statusCode}!');
      }

      final dynamic data = json.decode(response.body);
      List<dynamic>? statusList;

      if (data is List) {
        statusList = data;
      } else if (data is Map<String, dynamic>) {
        if (data['result'] is List) {
          statusList = data['result'] as List;
        } else if (data['result'] is Map<String, dynamic>) {
          final result = data['result'] as Map<String, dynamic>;
          if (result['data'] is List) {
            statusList = result['data'] as List;
          } else if (result['statuses'] is List) {
            statusList = result['statuses'] as List;
          }
        } else if (data['data'] is List) {
          statusList = data['data'] as List;
        } else if (data['statuses'] is List) {
          statusList = data['statuses'] as List;
        }
      }

      if (statusList == null) {
        throw Exception('Результат отсутствует в ответе');
      }

      // Пустой список — валидный ответ сервера: пользователь может не иметь
      // доступных статусов при включённом управлении видимостью.
      await prefs.setString(cacheKey, json.encode(statusList));

      final statuses = statusList
          .whereType<Map<String, dynamic>>()
          .map(LeadStatus.fromJson)
          .toList();

      await LeadCache.updatePersistentCountsFromStatuses(statuses);

      if (kDebugMode) {
        debugPrint(
            '✅ getLeadStatuses WITH FILTERS - Got ${statuses.length} statuses');
      }

      return statuses;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ getLeadStatuses WITH FILTERS - Error: $e');
      }

      // При принудительном запросе нельзя подменять ответ сервера кэшем:
      // вызывающий код должен получить настоящую причину ошибки.
      if (bypassAnalyticsCache) {
        rethrow;
      }

      final cachedStatuses = prefs.getString(cacheKey);
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => LeadStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
        throw Exception(
            'Ошибка загрузки статусов лидов и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasLeads(int leadStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<Lead> leads =
          await getLeads(leadStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return leads.isNotEmpty;
    } catch (e) {
      ////debugPrint('Error while checking if status has leads!');
      return false;
    }
  }

  Future<Map<String, dynamic>> createLeadStatus(
    String title,
    String color,
    bool? isFailure,
    bool? isSuccess,
    bool isUnassembled,
    List<int>? userIds,
  ) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead-status');
    if (kDebugMode) {
      //debugPrint('ApiService: createLeadStatus - Generated path: $path');
    }

    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    final response = await _postRequest(path, {
      'title': title,
      'color': color,
      "is_success": isSuccess == true ? 1 : 0,
      "is_failure": isFailure == true ? 1 : 0,
      "is_unassembled": isUnassembled,
      "organization_id": organizationId?.toString() ?? '',
      if (salesFunnelId != null) "sales_funnel_id": salesFunnelId.toString(),
      if (userIds != null) "users": userIds,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Статус лида создан успешно'};
    } else {
      return {'success': false, 'message': 'Ошибка создания статуса лида!'};
    }
  }

  Future<void> updateLeadStatus(
    int leadId,
    int position,
    int statusId, {
    int? reasonForRefusalId,
    String? reasonForRefusal,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/changeStatus/$leadId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateLeadStatus - Generated path: $path');
    }

    final payload = <String, dynamic>{
      'position': position,
      'status_id': statusId,
      if (reasonForRefusalId != null)
        'reason_for_refusal_id': reasonForRefusalId,
      if (reasonForRefusal != null && reasonForRefusal.trim().isNotEmpty)
        'reason_for_refusal': reasonForRefusal.trim(),
    };

    final response = await _postRequest(path, payload);

    if (response.statusCode == 200) {
      ////debugPrint('Статус задачи успешно обновлен');
    } else if (response.statusCode == 422) {
      final responseData = jsonDecode(response.body);
      final errorMessage = (responseData is Map<String, dynamic>
                  ? responseData['message']
                  : null)
              ?.toString() ??
          'Вы не можете переместить лид на этот статус';

      throw LeadStatusUpdateException(422, errorMessage);
    } else {
      throw Exception('Ошибка обновления задач лида!');
    }
  }

  Future<List<LeadHistory>> getLeadHistory(int leadId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/lead/history/$leadId');
      if (kDebugMode) {
        //debugPrint('ApiService: getLeadHistory - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => LeadHistory.fromJson(json)).toList();
      } else {
        ////debugPrint('Failed to load lead history!');
        throw Exception('Ошибка загрузки истории лида!');
      }
    } catch (e) {
      ////debugPrint('Error occurred!');
      throw Exception('Ошибка загрузки истории лида!');
    }
  }

  Future<List<NoticeHistory>> getNoticeHistory(int leadId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path =
          await _appendQueryParams('/notices/history-by-lead-id/$leadId');
      if (kDebugMode) {
        //debugPrint('ApiService: getNoticeHistory - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result'];
        return jsonList.map((json) => NoticeHistory.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки истории заметок!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки истории заметок!');
    }
  }

  Future<List<DealHistoryLead>> getDealHistoryLead(int leadId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/deal/history-by-lead-id/$leadId');
      if (kDebugMode) {
        //debugPrint('ApiService: getDealHistoryLead - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result'];
        return jsonList.map((json) => DealHistoryLead.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки истории сделок!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки истории сделок!');
    }
  }

  Future<List<Notes>> getLeadNotes(int leadId,
      {int page = 1, int perPage = 20}) async {
    // Формируем базовый путь
    final basePath = '/notices/$leadId?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(basePath);
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadNotes - Generated path: $path');
    }

    // Для заметок лида нужен актуальный ответ, без analytics-cache.
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result']['data'] as List)
          .map((note) => Notes.fromJson(note))
          .toList();
    } else {
      throw Exception('Ошибка загрузки заметок');
    }
  }

  Future<Map<String, dynamic>> createNotes({
    required String title,
    required String body,
    required int leadId,
    int? dealId,
    DateTime? date,
    required int sendSms,
    required List<int> users,
    List<String>? filePaths, // Новое поле для файлов
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/notices');
      if (kDebugMode) {
        //debugPrint('ApiService: createNotes - Generated path: $path');
      }
      var uri = Uri.parse('$baseUrl$path');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем поля в запрос
      request.fields['title'] = title;
      request.fields['body'] = body;
      request.fields['lead_id'] = leadId.toString();
      if (dealId != null) {
        request.fields['deal_id'] = dealId.toString();
      }
      if (date != null) {
        request.fields['date'] = DateFormat('yyyy-MM-dd HH:mm').format(date);
      }
      request.fields['send_sms'] = sendSms.toString();
      final organizationId = await getSelectedOrganization();
      request.fields['organization_id'] = organizationId?.toString() ?? '2';
      for (int i = 0; i < users.length; i++) {
        request.fields['users[$i]'] = users[i].toString();
      }

      // Добавляем файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      final response = await _multipartPostRequest('', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'note_created_successfully'};
      } else if (response.statusCode == 422) {
        if (response.body.contains('title')) {
          return {'success': false, 'message': 'invalid_title_length'};
        } else if (response.body.contains('body')) {
          return {'success': false, 'message': 'error_field_is_not_empty'};
        } else if (response.body.contains('date')) {
          return {'success': false, 'message': 'error_valid_date'};
        } else if (response.body.contains('users')) {
          return {'success': false, 'message': 'error_users'};
        } else {
          return {'success': false, 'message': 'validation_error'};
        }
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'error_server_text'};
      } else {
        return {'success': false, 'message': 'error_create_note'};
      }
    } catch (e) {
      return {'success': false, 'message': 'error_create_note'};
    }
  }

  Future<Map<String, dynamic>> updateNotes({
    required int noteId,
    required int leadId,
    required String title,
    required String body,
    DateTime? date,
  }) async {
    date ??= DateTime.now();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/notices/$noteId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateNotes - Generated path: $path');
    }

    final response = await _patchRequest(path, {
      'title': title,
      'body': body,
      'lead_id': leadId,
      'date': date.toIso8601String(),
    });

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Заметка успешно обновлена'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('title')) {
        return {'success': false, 'message': 'error_field_is_not_empty'};
      } else if (response.body.contains('body')) {
        return {'success': false, 'message': 'error_field_is_not_empty'};
      } else if (response.body.contains('date')) {
        return {'success': false, 'message': 'error_valid_date'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else {
      return {'success': false, 'message': 'error_update_note'};
    }
  }

  Future<Map<String, dynamic>> deleteNotes(int noteId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/notices/$noteId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteNotes - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete note!');
    }
  }

  Future<List<LeadDeal>> getLeadDeals(int leadId,
      {int page = 1, int perPage = 20}) async {
    // Формируем базовый путь
    final basePath =
        '/deal/get-by-lead-id/$leadId?page=$page&per_page=$perPage';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(basePath);
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadDeals - Generated path: $path');
    }

    // Для списка сделок лида нужен актуальный ответ, без analytics-cache.
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result']['data'] as List)
          .map((deal) => LeadDeal.fromJson(deal))
          .toList();
    } else {
      throw Exception('Ошибка загрузки заметок');
    }
  }

  Future<Map<String, dynamic>> createLeadWithData(
      Map<String, dynamic> data) async {
    // Формируем путь с query-параметрами
    final updatedPath = await _appendQueryParams('/lead');
    if (kDebugMode) {
      debugPrint(
          'ApiService: createLeadWithData - Generated path: $updatedPath');
    }

    final token = await getToken();
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl$updatedPath'));

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
    });

    // Добавляем обычные поля
    data.forEach((key, value) {
      // Пропускаем массивы - их обработаем отдельно
      if (key != 'lead_custom_fields' && key != 'directory_values') {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      }
    });

    // Обрабатываем lead_custom_fields как массив объектов
    if (data['lead_custom_fields'] != null &&
        data['lead_custom_fields'] is List &&
        (data['lead_custom_fields'] as List).isNotEmpty) {
      List<Map<String, dynamic>> customFields =
          List<Map<String, dynamic>>.from(data['lead_custom_fields']);
      for (int i = 0; i < customFields.length; i++) {
        request.fields['lead_custom_fields[$i][key]'] =
            customFields[i]['key']?.toString() ?? '';
        request.fields['lead_custom_fields[$i][value]'] =
            customFields[i]['value']?.toString() ?? '';
        request.fields['lead_custom_fields[$i][type]'] =
            customFields[i]['type']?.toString() ?? 'string';
      }
    }

    // ВАЖНО: Обрабатываем directory_values как массив объектов
    if (data['directory_values'] != null &&
        data['directory_values'] is List &&
        (data['directory_values'] as List).isNotEmpty) {
      List<Map<String, dynamic>> directoryValues =
          List<Map<String, dynamic>>.from(data['directory_values']);
      for (int i = 0; i < directoryValues.length; i++) {
        request.fields['directory_values[$i][directory_id]'] =
            directoryValues[i]['directory_id'].toString();
        request.fields['directory_values[$i][entry_id]'] =
            directoryValues[i]['entry_id'].toString();
      }
    }
    // Добавляем файлы
    if (data['files'] != null && (data['files'] as List).isNotEmpty) {
      final filesList = data['files'] as List<FileHelper>;
      for (var fileData in filesList) {
        try {
          final file = await http.MultipartFile.fromPath(
            'files[]',
            fileData.path,
            filename: fileData.name,
          );
          request.files.add(file);
        } catch (e) {
          debugPrint("Error adding file ${fileData.name}: $e");
        }
      }
    }

    if (data['price_type_id'] != null) {
      request.fields['price_type_id'] = data['price_type_id'].toString();
    }

    if (kDebugMode) {
      debugPrint('ApiService: createLeadWithData - Request fields:');
      request.fields.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }

    final response = await _multipartPostRequest(updatedPath, request);

    if (kDebugMode) {
      debugPrint(
          'ApiService: createLeadWithData - Response status: ${response.statusCode}');
      debugPrint(
          'ApiService: createLeadWithData - Response body: ${response.body}');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'lead_created_successfully'};
    } else if (response.statusCode == 422) {
      final serverMessage = _extractPrimaryMessageFromResponse(response);

      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {'success': false, 'message': 'error_enter_email'};
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('insta_login')) {
        return {'success': false, 'message': 'instagram_login_exists'};
      }
      if (response.body.contains('facebook_login')) {
        return {'success': false, 'message': 'facebook_login_exists'};
      }
      if (response.body.contains('tg_nick')) {
        return {'success': false, 'message': 'telegram_nick_exists'};
      }
      if (response.body.contains('birthday')) {
        return {'success': false, 'message': 'invalid_birthday'};
      }
      if (response.body.contains('wa_phone')) {
        return {'success': false, 'message': 'whatsapp_number_exists'};
      }
      if (response.body.contains('type')) {
        return {'success': false, 'message': 'invalid_field_type'};
      }
      if (response.body.contains('lead_custom_fields')) {
        return {'success': false, 'message': 'invalid_custom_fields'};
      }
      if (response.body.contains('price_type_id')) {
        return {'success': false, 'message': 'invalid_price_type_id'};
      }
      if (response.body.contains('directory_values')) {
        return {'success': false, 'message': 'invalid_directory_values'};
      }
      return {
        'success': false,
        'message': serverMessage?.trim().isNotEmpty == true
            ? serverMessage!.trim()
            : 'unknown_error'
      };
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      final serverMessage = _extractPrimaryMessageFromResponse(response);
      return {
        'success': false,
        'message': serverMessage?.trim().isNotEmpty == true
            ? serverMessage!.trim()
            : 'lead_creation_error'
      };
    }
  }

  Future<Map<String, dynamic>> updateLead({
    required int leadId,
    required String name,
    required int leadStatusId,
    required String phone,
    int? regionId,
    int? sourceId,
    int? managerId,
    String? instaLogin,
    String? facebookLogin,
    String? tgNick,
    DateTime? birthday,
    String? email,
    String? description,
    String? waPhone,
    List<Map<String, dynamic>>? customFields, // Изменён тип
    List<Map<String, int>>? directoryValues,
    String? priceTypeId, // Добавляем priceTypeId
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/$leadId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateLead - Generated path: $path');
    }

    final response = await _patchRequest(
      path,
      {
        'name': name,
        'lead_status_id': leadStatusId,
        'phone': phone,
        if (regionId != null) 'region_id': regionId,
        if (sourceId != null) 'source_id': sourceId,
        if (managerId != null) 'manager_id': managerId,
        if (instaLogin != null) 'insta_login': instaLogin,
        if (facebookLogin != null) 'facebook_login': facebookLogin,
        if (tgNick != null) 'tg_nick': tgNick,
        if (birthday != null) 'birthday': birthday.toIso8601String(),
        if (email != null) 'email': email,
        if (description != null) 'description': description,
        if (waPhone != null) 'wa_phone': waPhone,
        if (priceTypeId != null)
          'price_type_id': priceTypeId, // Добавляем price_type_id
        'lead_custom_fields': customFields ?? [],
        'directory_values': directoryValues ?? [],
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'lead_updated_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {'success': false, 'message': 'error_enter_email'};
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('insta_login')) {
        return {'success': false, 'message': 'instagram_login_exists'};
      }
      if (response.body.contains('facebook_login')) {
        return {'success': false, 'message': 'facebook_login_exists'};
      }
      if (response.body.contains('tg_nick')) {
        return {'success': false, 'message': 'telegram_nick_exists'};
      }
      if (response.body.contains('birthday remont_nullable')) {
        return {'success': false, 'message': 'invalid_birthday'};
      }
      if (response.body.contains('wa_phone')) {
        return {'success': false, 'message': 'whatsapp_number_exists'};
      }
      if (response.body.contains('type')) {
        return {'success': false, 'message': 'invalid_field_type'};
      }
      if (response.body.contains('price_type_id')) {
        return {'success': false, 'message': 'invalid_price_type_id'};
      }
      if (response.body.contains('lead_custom_fields')) {
        return {'success': false, 'message': 'invalid_fields'};
      }
      return {'success': false, 'message': 'unknown_error'};
    } else {
      return {'success': false, 'message': 'error_updated_lead'};
    }
  }

  Future<Map<String, dynamic>> updateLeadWithData({
    required int leadId,
    required Map<String, dynamic> data,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/$leadId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateLeadWithData - Generated path: $path');
    }
    var uri = Uri.parse('$baseUrl$path');

    var request = http.MultipartRequest('POST', uri);

    final token = await getToken();
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
    });

    request.fields['name'] = data['name']?.toString() ?? '';
    request.fields['lead_status_id'] = data['lead_status_id']?.toString() ?? '';
    request.fields['phone'] = data['phone']?.toString() ?? '';
    if (data['region_id'] != null) {
      request.fields['region_id'] = data['region_id'].toString();
    }
    if (data['source_id'] != null) {
      request.fields['source_id'] = data['source_id'].toString();
    }
    if (data['manager_id'] != null) {
      request.fields['manager_id'] = data['manager_id'].toString();
    }
    if (data['insta_login'] != null) {
      request.fields['insta_login'] = data['insta_login'].toString();
    }
    if (data['facebook_login'] != null) {
      request.fields['facebook_login'] = data['facebook_login'].toString();
    }
    if (data['tg_nick'] != null) {
      request.fields['tg_nick'] = data['tg_nick'].toString();
    }
    if (data['birthday'] != null) {
      request.fields['birthday'] = data['birthday'].toString();
    }
    if (data['email'] != null) {
      request.fields['email'] = data['email'].toString();
    }
    if (data['description'] != null) {
      request.fields['description'] = data['description'].toString();
    }
    if (data['wa_phone'] != null) {
      request.fields['wa_phone'] = data['wa_phone'].toString();
    }
    if (data['currency_id'] != null) {
      request.fields['currency_id'] = data['currency_id'].toString();
    }
    if (data['price_type_id'] != null) {
      request.fields['price_type_id'] =
          data['price_type_id'].toString(); // Добавляем price_type_id
    }

    if (data['files'] != null && (data['files'] as List).isNotEmpty) {
      final filesList = data['files'] as List<FileHelper>;
      for (var fileData in filesList) {
        try {
          if (fileData.path.startsWith('http')) {
            // If it's a URL, you need to download it first or send as URL
            // For now, skip URLs
            debugPrint("Skipping URL file: ${fileData.path}");
            continue;
          }

          final file = await http.MultipartFile.fromPath(
            'files[]',
            fileData.path,
            filename: fileData.name,
          );
          request.files.add(file);
        } catch (e) {
          debugPrint("Error adding file ${fileData.name}: $e");
        }
      }
    }

    // Добавляем sales_funnel_id из данных, если он присутствует
    if (data['sales_funnel_id'] != null) {
      request.fields['sales_funnel_id'] = data['sales_funnel_id'].toString();
    }
    if (data['duplicate'] != null) {
      request.fields['duplicate'] =
          data['duplicate'].toString(); // Добавляем duplicate
    }
    if (data['reason_for_refusal_id'] != null) {
      request.fields['reason_for_refusal_id'] =
          data['reason_for_refusal_id'].toString();
    }
    if (data['reason_for_refusal'] != null &&
        data['reason_for_refusal'].toString().trim().isNotEmpty) {
      request.fields['reason_for_refusal'] =
          data['reason_for_refusal'].toString().trim();
    }
    // Обрабатываем lead_custom_fields
    final customFields = data['lead_custom_fields'] as List<dynamic>? ?? [];
    if (customFields.isNotEmpty) {
      for (int i = 0; i < customFields.length; i++) {
        var field = customFields[i] as Map<String, dynamic>;
        request.fields['lead_custom_fields[$i][key]'] =
            field['key']?.toString() ?? '';
        request.fields['lead_custom_fields[$i][value]'] =
            field['value']?.toString() ?? '';
        request.fields['lead_custom_fields[$i][type]'] =
            field['type']?.toString() ?? 'string';
      }
    }

    // Обрабатываем directory_values
    final directoryValues = data['directory_values'] as List<dynamic>? ?? [];
    if (directoryValues.isNotEmpty) {
      for (int i = 0; i < directoryValues.length; i++) {
        var value = directoryValues[i] as Map<String, dynamic>;
        request.fields['directory_values[$i][directory_id]'] =
            value['directory_id'].toString();
        request.fields['directory_values[$i][entry_id]'] =
            value['entry_id'].toString();
      }
    }

    final response = await _multipartPostRequest(path, request);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'lead_updated_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {'success': false, 'message': 'error_enter_email'};
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('insta_login')) {
        return {'success': false, 'message': 'instagram_login_exists'};
      }
      if (response.body.contains('facebook_login')) {
        return {'success': false, 'message': 'facebook_login_exists'};
      }
      if (response.body.contains('tg_nick')) {
        return {'success': false, 'message': 'telegram_nick_exists'};
      }
      if (response.body.contains('birthday')) {
        return {'success': false, 'message': 'invalid_birthday'};
      }
      if (response.body.contains('wa_phone')) {
        return {'success': false, 'message': 'whatsapp_number_exists'};
      }
      if (response.body.contains('type')) {
        return {'success': false, 'message': 'invalid_field_type'};
      }
      if (response.body.contains('lead_custom_fields')) {
        return {'success': false, 'message': 'invalid_custom_fields'};
      }
      if (response.body.contains('duplicate')) {
        return {'success': false, 'message': 'invalid_duplicate_value'};
      }
      if (response.body.contains('price_type_id')) {
        return {'success': false, 'message': 'invalid_price_type_id'};
      }
      return {'success': false, 'message': 'unknown_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'error_update_lead'};
    }
  }

  Future<RegionsDataResponse> getAllRegion({String? search}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/region');
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (kDebugMode) {
      //debugPrint('ApiService: getAllRegion - Generated path: $path');
    }

    final response = await _getRequest(path);

    late RegionsDataResponse dataRegion;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataRegion = RegionsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {
      // ////debugPrint('getAll region!');
    }

    return dataRegion;
  }

  Future<RegionsDataResponse> getAllState({String? search}) async {
    String path = await _appendQueryParams('/region?type=state');
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        return RegionsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении областей!');
    }
  }

  Future<CitiesDataResponse> getAllCity({String? search, int? parentId}) async {
    String path = await _appendQueryParams('/region?type=city');
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (parentId != null) {
      path += '&parent_id=$parentId';
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        return CitiesDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении городов!');
    }
  }

  Future<List<ReasonForRefusalData>> getReasonsForRefusal({
    required String type,
    int perPage = 100,
  }) async {
    final safeType = type.trim().isEmpty ? 'lead' : type.trim();
    final basePath = '/reason-for-refusal?type=$safeType&per_page=$perPage';
    final path = await _appendQueryParams(basePath);

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final parsed = ReasonForRefusalResponse.fromJson(data);
      return parsed.data;
    } else {
      throw Exception('Ошибка при получении причин отказа!');
    }
  }

  Future<List<SourceData>> getAllSource() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/source');
    if (kDebugMode) {
      //debugPrint('ApiService: getAllSource - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null) {
        List<SourceData> dataSource = List<SourceData>.from(
            data.map((source) => SourceData.fromJson(source)));
        return dataSource;
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }
  }

  Future<List<LeadFilterChannelData>> getLeadFilterChannels() async {
    final path =
        await _appendQueryParams('/integrations/get-by-category/messenger');

    final response = await _getRequest(path);

    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки каналов!');
    }

    final data = json.decode(response.body);
    final result = data['result'];
    if (result is! List) {
      return [];
    }

    return result
        .whereType<Map<String, dynamic>>()
        .map(LeadFilterChannelData.fromJson)
        .toList();
  }

  Future<List<AdvertisingCampaignData>> getAllAdvertisingCampaigns() async {
    final organizationId = await getSelectedOrganization();
    if (organizationId == null ||
        organizationId.isEmpty ||
        organizationId == 'null') {
      throw Exception('Organization ID is required but missing');
    }

    if (!await _isSessionValid()) {
      await _forceLogoutAndRedirect();
      throw Exception('Session is invalid');
    }

    if (baseUrl == null) {
      await _initializeIfDomainExists();
      if (baseUrl == null) {
        throw Exception('Base URL is not initialized');
      }
    }

    final token = await getToken();
    final uri = Uri.parse(
      '$baseUrl/advertising-campaigns?organization_id=$organizationId&per_page=1000',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Device': 'mobile',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final campaigns = result?['data'] as List<dynamic>?;

      if (campaigns == null) {
        return <AdvertisingCampaignData>[];
      }

      return campaigns
          .map((campaign) => AdvertisingCampaignData.fromJson(
              campaign as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Ошибка при получении рекламных кампаний!');
    }
  }

  Future<ManagersDataResponse> getAllManager({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path =
        await _appendQueryParams('/manager?page=$page&per_page=$perPage');
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (kDebugMode) {
      //debugPrint('ApiService: getAllManager - Generated path: $path');
    }

    // Используем общий метод для выполнения GET-запроса
    final response = await _getRequest(path);

    late ManagersDataResponse dataManager;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataManager = ManagersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {}

    return dataManager;
  }

  Future<LeadsMultiDataResponse> getAllLeadMulti({
    String? search,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String basePath = '/lead';
    if (search != null && search.trim().isNotEmpty) {
      basePath += '?search=${Uri.encodeQueryComponent(search.trim())}';
    }
    final path = await _appendQueryParams(basePath);
    if (kDebugMode) {
      //debugPrint('ApiService: getAllLeadMulti - Generated path: $path');
    }

    // Используем общий метод для выполнения GET-запроса
    final response = await _getRequest(path);

    late LeadsMultiDataResponse dataLead;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataLead = LeadsMultiDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {}

    return dataLead;
  }

  Future<LeadsDataResponse> getLeadPage(
    int page, {
    bool showDebt = false,
    String? search,
    bool bypassCache = false,
  }) async {
    try {
      // Формируем путь с параметром страницы
      String basePath = '/lead?page=$page';

      // Добавляем параметр show_debt если нужно
      if (showDebt) {
        basePath += '&show_debt=1';
      }

      if (search != null && search.trim().isNotEmpty) {
        basePath += '&search=${Uri.encodeComponent(search.trim())}';
      }

      // Добавляем остальные query параметры (язык, токен и т.д.)
      final path = await _appendQueryParams(basePath);

      if (kDebugMode) {
        debugPrint(
          'ApiService: getLeadPage - Loading page $page, path: $path, bypassCache=$bypassCache',
        );
      }

      // Выполняем GET запрос
      final response = await _analyticsRequest(path, bypassCache: bypassCache);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] != null) {
          // Парсим ответ в модель LeadsDataResponse
          final pageResponse = LeadsDataResponse.fromJson(data);

          if (kDebugMode) {
            debugPrint(
                'ApiService: Page $page loaded successfully with ${pageResponse.result?.length ?? 0} items');
            if (pageResponse.pagination != null) {
              debugPrint(
                  'ApiService: Pagination - current: ${pageResponse.pagination!.currentPage}, total pages: ${pageResponse.pagination!.totalPages}');
            }
          }

          return pageResponse;
        } else {
          // Если result пустой, возвращаем пустой response
          return LeadsDataResponse(result: [], errors: null, pagination: null);
        }
      } else {
        throw Exception(
            'Ошибка при получении данных со страницы $page! Статус: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: Error loading page $page: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteLeadStatuses(int leadStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead-status/$leadStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteLeadStatuses - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete leadStatus!');
    }
  }

  Future<Map<String, dynamic>> updateLeadStatusEdit(
    int leadStatusId,
    String title,
    bool isSuccess,
    bool isFailure,
    bool isUnassembled,
    List<int>? userIds,
  ) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead-status/$leadStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateLeadStatusEdit - Generated path: $path');
    }

    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    final payload = {
      "title": title,
      "is_success": isSuccess ? 1 : 0,
      "is_failure": isFailure ? 1 : 0,
      "is_unassembled": isUnassembled,
      "organization_id": organizationId?.toString() ?? '',
      if (salesFunnelId != null) "sales_funnel_id": salesFunnelId.toString(),
      if (userIds != null) "users": userIds,
    };

    final response = await _patchRequest(
      path, // Исправлено: Передача пути с query-параметрами
      payload, // Исправлено: Передача `payload` как второго аргумента
    );

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update leadStatus!');
    }
  }

  Future<Map<String, dynamic>> deleteLead(int leadId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/$leadId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteLead - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'success': true, 'result': 'Success'};
    }

    String message = 'error_delete_lead';
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final serverMessage =
            SafeConverters.toSafeString(decoded['message']).trim();
        if (serverMessage.isNotEmpty) {
          message = serverMessage;
        }
      }
    } catch (_) {}

    return {
      'success': false,
      'result': 'Error',
      'message': message,
      'status_code': response.statusCode,
    };
  }

  Future<List<ContactPerson>> getContactPerson(int leadId) async {
    // Формируем базовый путь
    final basePath = '/contactPerson/$leadId';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(basePath);
    if (kDebugMode) {
      //debugPrint('ApiService: getContactPerson - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((contactPerson) => ContactPerson.fromJson(contactPerson))
          .toList();
    } else {
      throw Exception('Ошибка загрузки Контактное Лицо ');
    }
  }

  Future<Map<String, dynamic>> createContactPerson({
    required int leadId,
    required String name,
    required String phone,
    required String position,
    String? email,
    String? tgId,
    String? address,
    int? regionId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/contactPerson');
    if (kDebugMode) {
      //debugPrint('ApiService: createContactPerson - Generated path: $path');
    }

    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    final body = <String, dynamic>{
      'lead_id': leadId,
      'name': name,
      'phone': phone,
      'position': position,
      if (email != null && email.isNotEmpty) 'email': email,
      if (tgId != null && tgId.isNotEmpty) 'tg_id': tgId,
      if (address != null && address.isNotEmpty) 'address': address,
      if (regionId != null) 'region_id': regionId,
      if (organizationId != null && organizationId.isNotEmpty)
        'organization_id': organizationId,
      if (salesFunnelId != null && salesFunnelId.isNotEmpty)
        'sales_funnel_id': salesFunnelId,
    };

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'contact_create_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      } else if (response.body.contains('position')) {
        return {'success': false, 'message': 'field_is_not_empty'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else {
      return {'success': false, 'message': 'error_contact_create'};
    }
  }

  Future<Map<String, dynamic>> updateContactPerson({
    required int leadId,
    required int contactpersonId,
    required String name,
    required String phone,
    required String position,
    String? email,
    String? tgId,
    String? address,
    int? regionId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/contactPerson/$contactpersonId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateContactPerson - Generated path: $path');
    }

    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    final body = <String, dynamic>{
      'lead_id': leadId,
      'name': name,
      'phone': phone,
      'position': position,
      if (email != null && email.isNotEmpty) 'email': email,
      if (tgId != null && tgId.isNotEmpty) 'tg_id': tgId,
      if (address != null && address.isNotEmpty) 'address': address,
      if (regionId != null) 'region_id': regionId,
      if (organizationId != null && organizationId.isNotEmpty)
        'organization_id': organizationId,
      if (salesFunnelId != null && salesFunnelId.isNotEmpty)
        'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'contact_update_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      } else if (response.body.contains('position')) {
        return {'success': false, 'message': 'field_is_not_empty'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else {
      return {'success': false, 'message': 'error_contact_update_successfully'};
    }
  }

  Future<Map<String, dynamic>> deleteContactPerson(int contactpersonId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/contactPerson/$contactpersonId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteContactPerson - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete contactPerson!');
    }
  }

  Future<List<LeadNavigateChat>> getLeadToChat(int leadId) async {
    // Формируем базовый путь
    final basePath = '/lead/$leadId/chats';
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(basePath);
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadToChat - Generated path: $path');
    }

    final response = await _getRequest(path);
    ////debugPrint('Request path: $path');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((leadtochat) => LeadNavigateChat.fromJson(leadtochat))
          .toList();
    } else {
      throw Exception('Ошибка загрузки чата в Лид');
    }
  }

  Future<List<SourceLead>> getSourceLead({String? search}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/source');
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (kDebugMode) {
      //debugPrint('ApiService: getSourceLead - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные: $data');
      return (data as List)
          .map((sourceLead) => SourceLead.fromJson(sourceLead))
          .toList();
    } else {
      throw Exception('Ошибка загрузки источников');
    }
  }

  Future<List<LeadStatusForFilter>> getLeadStatusForFilter() async {
    final path = await _appendQueryParams('/lead/statuses');
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadStatusForFilter - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((leadStatus) => LeadStatusForFilter.fromJson(leadStatus))
          .toList();
    } else {
      throw Exception('Ошибка загрузки статусов лидов');
    }
  }

  /// Метод для отправки на 1С
  Future<void> postLeadToC(int leadId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/lead/sendToOneC/$leadId');
      if (kDebugMode) {
        //debugPrint('ApiService: postLeadToC - Generated path: $path');
      }

      final response = await _postRequest(path, {});

      if (response.statusCode == 200) {
        ////debugPrint('Успешно отправлено в 1С');
      } else {
        ////debugPrint('Ошибка отправки в 1С Лид!');
        throw Exception('Ошибка отправки в 1С!');
      }
    } catch (e) {
      ////debugPrint('Произошла ошибка!');
      throw Exception('Ошибка отправки в 1С!');
    }
  }

  Future getData1C() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/get-all-data');
    if (kDebugMode) {
      //debugPrint('ApiService: getData1C - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List).toList();
      } else {
        // throw Exception('Результат отсутствует в ответе');
      }
    } else if (response.statusCode == 500) {
      throw Exception('Ошибка сервера (500): Внутреняя ошибка сервера');
    } else if (response.statusCode == 422) {
      throw Exception('Ошибка валидации (422): Некорректные данные');
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<Map<String, dynamic>> getCustomFieldslead() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/get/custom-fields');
    if (kDebugMode) {
      //debugPrint('ApiService: getCustomFieldslead - Generated path: $path');
    }

    // Выполняем запрос
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<LeadStatus> getLeadStatus(int leadStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead-status/$leadStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadStatus - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return LeadStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

  Future<Map<String, dynamic>> addLeadsFromContacts(
      int statusId, List<Map<String, dynamic>> contacts) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead/insert');
    if (kDebugMode) {
      //debugPrint('ApiService: addLeadsFromContacts - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'leads': contacts,
      },
    );

    // Parse the response body
    final responseData = json.decode(response.body);

    // If status code is not 200, throw an exception with the response data
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    // Return the response data even for 200 status code
    // since it may contain partial errors
    return responseData;
  }

  Future<DirectoryLinkResponse> getLeadDirectoryLinks() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directoryLink/lead');
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadDirectoryLinks - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        return DirectoryLinkResponse.fromJson(data);
      } else {
        throw Exception('Данные отсутствуют в ответе');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw Exception('Внутренняя ошибка сервера');
    } else {
      throw Exception('Ошибка при получении связанных справочников!');
    }
  }

  /// Получение каналов привлечения лидов
  /// Endpoint: /api/dashboard/lead-channels
  Future<LeadChannelsResponse> getLeadChannels() async {
    final path = await _appendQueryParams('/dashboard/lead-channels');

    if (kDebugMode) {
      debugPrint('ApiService: getLeadChannels - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getLeadChannels',
      fallbackMessage: 'Ошибка загрузки данных каналов!',
    );
    return LeadChannelsResponse.fromJson(jsonData);
  }

  Future<IntegrationForLead> getIntegrationForLead(int chatId) async {
    final token = await getToken();
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/v2/chat/get-integration/$chatId');
    if (kDebugMode) {
      //debugPrint('ApiService: getIntegrationForLead - Generated path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // debug//debugPrint('API response: $data'); // Лог для отладки
      if (data['result'] != null) {
        return IntegrationForLead.fromJson(data['result']);
      } else {
        // debug//debugPrint('Integration not found in response: $data');
        throw Exception('Интеграция не найдена в ответе');
      }
    } else {
      // debug//debugPrint('API error: ${response.statusCode}, body: ${response.body}');
      throw Exception(
          'Ошибка ${response.statusCode}: Не удалось получить интеграцию');
    }
  }

  Future<List<String>> getLeadCustomFields() async {
    final path = await _appendQueryParams('/lead/get/custom-fields');

    if (kDebugMode) {
      debugPrint('ApiService: getLeadCustomFields - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList.map((field) => field.toString()).toList();
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка загрузки пользовательских полей лидов',
        response.statusCode,
      );
    }
  }

  Future<List<String>> getLeadCustomFieldValues(String key) async {
    final path =
        await _appendQueryParams('/lead/get/custom-field-values?key=$key');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getLeadCustomFieldValues - Generated path: $path');
    }
    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList.map((value) => value.toString()).toList();
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка загрузки значений пользовательского поля лидов',
        response.statusCode,
      );
    }
  }

  bool _isMissingMasterclassCheckInRoute(http.Response response) {
    if (response.statusCode != 404) return false;
    final message =
        (_extractPrimaryMessageFromResponse(response) ?? '').toLowerCase();
    return message.isEmpty ||
        message.contains('could not be found') ||
        message.contains('route');
  }

  bool _isTechnicalMasterclassToken(String text) {
    final value = text.trim();
    if (value.isEmpty) return true;
    if (value.startsWith('{') || value.startsWith('[')) return true;
    if (RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) return true;
    if (RegExp(r'^\d+$').hasMatch(value)) return true;
    return false;
  }

  bool _isUserFacingMasterclassText(String text) {
    if (_isTechnicalMasterclassToken(text)) return false;
    return RegExp(r'[A-Za-zА-Яа-яЁё]').hasMatch(text) &&
        (text.contains(' ') || RegExp(r'[А-Яа-яЁё]').hasMatch(text));
  }

  void _collectMasterclassUserTexts(dynamic value, List<String> texts) {
    if (value == null) return;
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();
        if (key == 'id' ||
            key == 'lead_status_id' ||
            key == 'status_id' ||
            key == 'name' ||
            key == 'phone' ||
            key == 'telephone' ||
            key == 'mobile' ||
            key == 'code' ||
            key == 'status' ||
            key == 'type') {
          continue;
        }
        _collectMasterclassUserTexts(entry.value, texts);
      }
      return;
    }
    if (value is List) {
      for (final item in value) {
        _collectMasterclassUserTexts(item, texts);
      }
      return;
    }

    final text = value
        .toString()
        .replaceAll(RegExp(r'\{[^}]*\}'), ' ')
        .trim();
    if (text.contains('\n')) {
      for (final line in text.split('\n')) {
        _collectMasterclassUserTexts(line, texts);
      }
      return;
    }
    if (_isUserFacingMasterclassText(text) && !texts.contains(text)) {
      texts.add(text);
    }
  }

  String? _extractMasterclassPhone(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final rawPhone = value['phone'] ??
          value['telephone'] ??
          value['mobile'] ??
          value['phone_number'];
      if (rawPhone != null) {
        final phone = rawPhone.toString().trim();
        if (phone.isNotEmpty && phone != 'null') return phone;
      }
      for (final item in value.values) {
        final nested = _extractMasterclassPhone(item);
        if (nested != null) return nested;
      }
      return null;
    }
    if (value is List) {
      for (final item in value) {
        final nested = _extractMasterclassPhone(item);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  Map<String, dynamic> _parseMasterclassCheckInResponse(
      http.Response response) {
    Map<String, dynamic> body = {};
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      } else if (decoded is Map) {
        body = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    final texts = <String>[];
    const messageKeys = {
      'message',
      'error',
      'errors',
      'description',
      'detail',
      'details',
      'title',
      'text',
      'info',
    };

    void walk(dynamic value) {
      if (value is Map) {
        value.forEach((key, nested) {
          if (messageKeys.contains(key.toString().toLowerCase())) {
            _collectMasterclassUserTexts(nested, texts);
          } else {
            walk(nested);
          }
        });
      } else if (value is List) {
        for (final item in value) {
          walk(item);
        }
      }
    }

    walk(body);

    return {
      'texts': texts,
      'phone': _extractMasterclassPhone(body),
    };
  }

  Future<Map<String, dynamic>> checkInMasterclassTicket(String qr) async {
    final body = {'qr': qr};
    var response =
        await _postRequest('/v3/masterclass-tickets/check-in', body);

    if (_isMissingMasterclassCheckInRoute(response)) {
      response = await _postRequest('/masterclass-tickets/check-in', body);
    }

    final parsed = _parseMasterclassCheckInResponse(response);
    return {
      'statusCode': response.statusCode,
      'texts': parsed['texts'],
      'phone': parsed['phone'],
    };
  }
}

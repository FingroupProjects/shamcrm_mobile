part of '../api_service.dart';

extension ApiDealsX on ApiService {
  Future<void> clearDealStatusesPersistentCache({
    bool includeAll = false,
    int? salesFunnelId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();
    String? funnelId = salesFunnelId?.toString();

    if (funnelId == null || funnelId.isEmpty || funnelId == 'null') {
      funnelId = await getSelectedDealSalesFunnel();
    }

    final cacheKey = includeAll
        ? 'cachedDealStatuses_all_${organizationId}_funnel_${funnelId ?? "null"}'
        : 'cachedDealStatuses_${organizationId}_funnel_${funnelId ?? "null"}';

    if (kDebugMode) {
      debugPrint(
          '🧹 ApiService.clearDealStatusesPersistentCache: removing key=$cacheKey');
    }

    await prefs.remove(cacheKey);
  }

  Future<List<Notes>> getDealNotes(int dealId,
      {int page = 1, int perPage = 20}) async {
    final basePath =
        '/notices/get-by-deal/$dealId?page=$page&per_page=$perPage';
    final path = await _appendQueryParams(basePath);

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result']['data'] as List)
          .map((note) => Notes.fromJson(note))
          .toList();
    } else {
      throw Exception('Ошибка загрузки заметок сделки');
    }
  }

  Future<Map<String, dynamic>> createDealNotice({
    String? title,
    required String body,
    required int leadId,
    required int dealId,
    DateTime? date,
    List<int>? users,
  }) async {
    try {
      final token = await getToken();
      final path = await _appendQueryParams('/notices');
      final uri = Uri.parse('$baseUrl$path');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile',
      });

      if (title != null && title.trim().isNotEmpty) {
        request.fields['title'] = title.trim();
      }
      request.fields['body'] = body;
      request.fields['lead_id'] = leadId.toString();
      request.fields['deal_id'] = dealId.toString();
      if (date != null) {
        request.fields['date'] = DateFormat('yyyy/MM/dd HH:mm').format(date);
      }
      if (users != null && users.isNotEmpty) {
        for (int i = 0; i < users.length; i++) {
          request.fields['users[$i]'] = users[i].toString();
        }
      }

      final response = await _multipartPostRequest('', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'note_created_successfully'};
      }
      if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final message = (data is Map<String, dynamic> ? data['message'] : null)
                ?.toString() ??
            'Ошибка валидации';
        return {'success': false, 'message': message};
      }
      return {'success': false, 'message': 'error_create_note'};
    } catch (e) {
      return {'success': false, 'message': 'error_create_note'};
    }
  }

  Future<DealNameDataResponse> getAllDealNames({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams(
      '/service/by-sales-funnel-id?page=$page&per_page=$perPage',
    );
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (kDebugMode) {
      //debugPrint('ApiService: getAllDealNames - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DealNameDataResponse.fromJson(data);
    } else {
      throw ('Failed to load deal names');
    }
  }

  Future<DealById> getDealById(int dealId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/deal/$dealId');
      if (kDebugMode) {
        debugPrint('ApiService: getDealById - Generated path: $path');
      }

      // Детали сделки должны приходить всегда актуальными, без in-memory analytics cache.
      final response = await _analyticsRequest(path, bypassCache: true);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonDeal = decodedJson['result'];

        if (jsonDeal == null || jsonDeal['deal_status'] == null) {
          throw Exception('Некорректные данные от API');
        }

        return DealById.fromJson(jsonDeal, jsonDeal['deal_status']['id'] ?? 0);
      } else {
        throw Exception('Ошибка загрузки deal ID!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки deal ID!');
    }
  }

  Future<List<Deal>> getDeals(
    int? dealStatusId, {
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? managers,
    List<int>? regions,
    int? regionId,
    List<int>? cityIds,
    List<int>? executorIds,
    List<int>? sources,
    List<int>? leads,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    int? daysWithoutActivity,
    bool? hasTasks,
    bool? withoutNotices,
    bool? overdueNotices,
    List<int>? leadStatuses,
    List<int>? reasonForRefusalIds,
    List<Map<String, dynamic>>? directoryValues,
    List<String>? names,
    int? salesFunnelId, // ← КРИТИЧНО: Явный параметр
    Map<String, List<String>>? customFieldFilters,
  }) async {
    // ✅ КРИТИЧНО: Формируем базовый путь БЕЗ _appendQueryParams
    String path = '/deal?page=$page&per_page=$perPage';

    // ✅ ПЕРВЫМ делом добавляем organization_id
    final organizationId = await getSelectedOrganization();
    if (organizationId != null &&
        organizationId.isNotEmpty &&
        organizationId != 'null') {
      path += '&organization_id=$organizationId';
    }

    // ✅ ВТОРЫМ добавляем sales_funnel_id (если есть)
    if (salesFunnelId != null) {
      path += '&sales_funnel_id=$salesFunnelId';
      debugPrint('ApiService: getDeals - Added salesFunnelId: $salesFunnelId');
    } else {
      // Fallback: пробуем получить из SharedPreferences
      final savedFunnelId = await getSelectedDealSalesFunnel();
      if (savedFunnelId != null &&
          savedFunnelId.isNotEmpty &&
          savedFunnelId != 'null') {
        path += '&sales_funnel_id=$savedFunnelId';
        debugPrint(
            'ApiService: getDeals - Added savedFunnelId: $savedFunnelId');
      }
    }

    // Проверяем наличие фильтров
    bool hasFilters = (search != null && search.isNotEmpty) ||
        (managers != null && managers.isNotEmpty) ||
        (regions != null && regions.isNotEmpty) ||
        (regionId != null) ||
        (cityIds != null && cityIds.isNotEmpty) ||
        (executorIds != null && executorIds.isNotEmpty) ||
        (sources != null && sources.isNotEmpty) ||
        (leads != null && leads.isNotEmpty) ||
        (fromDate != null) ||
        (toDate != null) ||
        (daysWithoutActivity != null) ||
        (hasTasks == true) ||
        (withoutNotices == true) ||
        (overdueNotices == true) ||
        (statuses != null) ||
        (leadStatuses != null && leadStatuses.isNotEmpty) ||
        (reasonForRefusalIds != null && reasonForRefusalIds.isNotEmpty) ||
        (directoryValues != null && directoryValues.isNotEmpty) ||
        (names != null && names.isNotEmpty) ||
        (customFieldFilters != null &&
            customFieldFilters.isNotEmpty); // Учитываем кастомные поля

    // ✅ Добавляем dealStatusId только если нет фильтров
    if (dealStatusId != null && !hasFilters) {
      path += '&deal_statuses=$dealStatusId';
    }

    // Добавляем остальные параметры
    if (search != null && search.isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search)}';
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

    if (executorIds != null && executorIds.isNotEmpty) {
      for (int i = 0; i < executorIds.length; i++) {
        path += '&users[$i]=${executorIds[i]}';
      }
    }

    if (sources != null && sources.isNotEmpty) {
      for (int i = 0; i < sources.length; i++) {
        path += '&sources[$i]=${sources[i]}';
      }
    }

    if (leads != null && leads.isNotEmpty) {
      for (int i = 0; i < leads.length; i++) {
        path += '&clients[$i]=${leads[i]}';
      }
    }

    if (daysWithoutActivity != null) {
      path += '&lastUpdate=$daysWithoutActivity';
    }

    if (hasTasks == true) {
      path += '&withTasks=1';
    }

    if (withoutNotices == true) {
      path += '&without_notices=1';
    }

    if (overdueNotices == true) {
      path += '&overdue_notices=1';
    }

    if (statuses != null) {
      path += '&deal_statuses=$statuses';
    }

    if (leadStatuses != null && leadStatuses.isNotEmpty) {
      for (int i = 0; i < leadStatuses.length; i++) {
        path += '&lead_statuses[$i]=${leadStatuses[i]}';
      }
    }

    if (reasonForRefusalIds != null && reasonForRefusalIds.isNotEmpty) {
      for (int i = 0; i < reasonForRefusalIds.length; i++) {
        path += '&reason_for_refusals[$i]=${reasonForRefusalIds[i]}';
      }
    }

    if (fromDate != null && toDate != null) {
      final formattedFromDate =
          "${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}";
      final formattedToDate =
          "${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}";
      path += '&from=$formattedFromDate&to=$formattedToDate';
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

    if (names != null && names.isNotEmpty) {
      for (int i = 0; i < names.length; i++) {
        path += '&names[$i]=${Uri.encodeComponent(names[i])}';
      }
    }

    debugPrint("ApiService: getDeals - Final path: $path");

    final response = await _getRequest(path);
    debugPrint(
        "ApiService: getDeals - Response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null && data['result']['data'] != null) {
        final deals = (data['result']['data'] as List)
            .map((json) => Deal.fromJson(json, dealStatusId ?? -1))
            .toList();

        debugPrint("ApiService: getDeals - Loaded ${deals.length} deals");
        return deals;
      } else {
        debugPrint("ApiService: getDeals - No data in response");
        return []; // Возвращаем пустой массив вместо ошибки
      }
    } else {
      debugPrint("ApiService: getDeals - Error ${response.statusCode}");
      throw Exception('Ошибка загрузки сделок!');
    }
  }

  Future<List<DealStatus>> getDealStatuses({
    bool includeAll = false,
    int? salesFunnelId, // ← КРИТИЧНО: Добавили явный параметр
    List<int>? managers,
    List<int>? regions,
    int? regionId,
    List<int>? cityIds,
    List<int>? executorIds,
    List<int>? sources,
    List<int>? leads,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    int? daysWithoutActivity,
    bool? hasTasks,
    bool? withoutNotices,
    bool? overdueNotices,
    List<int>? leadStatuses,
    List<int>? reasonForRefusalIds,
    List<Map<String, dynamic>>? directoryValues,
    List<String>? names,
    bool bypassCache = false,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    // ✅ ПРИОРИТЕТ: Сначала используем переданный параметр
    String? funnelId = salesFunnelId?.toString();

    // ✅ FALLBACK: Если не передан - читаем из SharedPreferences
    if (funnelId == null || funnelId.isEmpty || funnelId == 'null') {
      funnelId = await getSelectedDealSalesFunnel();
    }

    // Проверка organizationId
    if (organizationId == null ||
        organizationId.isEmpty ||
        organizationId == 'null') {
      throw Exception('Organization ID is required but missing');
    }

    if (kDebugMode) {
      debugPrint('🔍 getDealStatuses - START: includeAll=$includeAll');
      debugPrint('🔍 getDealStatuses - organizationId: $organizationId');
      debugPrint(
          '🔍 getDealStatuses - salesFunnelId (параметр): $salesFunnelId');
      debugPrint('🔍 getDealStatuses - funnelId (итоговый): $funnelId');
      debugPrint('🔍 getDealStatuses - bypassCache: $bypassCache');
    }

    final basePath = includeAll ? '/deal/statuses/all' : '/deal/statuses';
    final cacheKey = includeAll
        ? 'cachedDealStatuses_all_${organizationId}_funnel_${funnelId ?? "null"}'
        : 'cachedDealStatuses_${organizationId}_funnel_${funnelId ?? "null"}';

    try {
      // ✅ КРИТИЧНО: Формируем путь БЕЗ использования _appendQueryParams
      // Потому что _appendQueryParams может перезаписать наш salesFunnelId
      String path = '$basePath?organization_id=$organizationId';

      // ВСЕГДА добавляем sales_funnel_id если он есть
      if (funnelId != null && funnelId.isNotEmpty && funnelId != 'null') {
        path += '&sales_funnel_id=$funnelId';
        if (kDebugMode) {
          debugPrint('✅ getDealStatuses - Added sales_funnel_id: $funnelId');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ getDealStatuses - No funnel selected, loading ALL deal statuses');
        }
      }

      if (reasonForRefusalIds != null && reasonForRefusalIds.isNotEmpty) {
        for (int i = 0; i < reasonForRefusalIds.length; i++) {
          path += '&reason_for_refusals[$i]=${reasonForRefusalIds[i]}';
        }
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

      if (executorIds != null && executorIds.isNotEmpty) {
        for (int i = 0; i < executorIds.length; i++) {
          path += '&users[$i]=${executorIds[i]}';
        }
      }

      if (sources != null && sources.isNotEmpty) {
        for (int i = 0; i < sources.length; i++) {
          path += '&sources[$i]=${sources[i]}';
        }
      }

      if (leads != null && leads.isNotEmpty) {
        for (int i = 0; i < leads.length; i++) {
          path += '&clients[$i]=${leads[i]}';
        }
      }

      if (daysWithoutActivity != null) {
        path += '&lastUpdate=$daysWithoutActivity';
      }

      if (hasTasks == true) {
        path += '&withTasks=1';
      }

      if (withoutNotices == true) {
        path += '&without_notices=1';
      }

      if (overdueNotices == true) {
        path += '&overdue_notices=1';
      }

      if (statuses != null) {
        path += '&deal_statuses=$statuses';
      }

      if (leadStatuses != null && leadStatuses.isNotEmpty) {
        for (int i = 0; i < leadStatuses.length; i++) {
          path += '&lead_statuses[$i]=${leadStatuses[i]}';
        }
      }

      if (fromDate != null && toDate != null) {
        final formattedFromDate =
            "${fromDate.day.toString().padLeft(2, '0')}.${fromDate.month.toString().padLeft(2, '0')}.${fromDate.year}";
        final formattedToDate =
            "${toDate.day.toString().padLeft(2, '0')}.${toDate.month.toString().padLeft(2, '0')}.${toDate.year}";
        path += '&from=$formattedFromDate&to=$formattedToDate';
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
                  .where(
                      (entry) => entry != null && entry.toString().isNotEmpty)
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

      if (names != null && names.isNotEmpty) {
        for (int i = 0; i < names.length; i++) {
          path += '&names[$i]=${Uri.encodeComponent(names[i])}';
        }
      }

      if (kDebugMode) {
        debugPrint('📤 getDealStatuses - Final path: $path');
      }

      final response = await _analyticsRequest(path, bypassCache: bypassCache);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint(
              'ApiService: getDealStatuses - Response: ${response.body}');
        }

        List<dynamic>? statusList;

        // Определяем структуру ответа
        if (data is List) {
          statusList = data;
        } else if (data is Map) {
          if (data['result'] != null) {
            statusList = data['result'] is List
                ? data['result']
                : (data['result']['data'] as List?);
          } else if (data['data'] != null) {
            statusList = data['data'] as List;
          } else if (data['statuses'] != null) {
            statusList = data['statuses'] as List;
          }
        }

        // ✅ КРИТИЧНО: Обрабатываем ПУСТОЙ массив как валидный результат
        if (statusList != null) {
          if (statusList.isEmpty) {
            debugPrint(
                '⚠️ getDealStatuses - API вернул пустой массив статусов');
            // Очищаем кэш для этой воронки
            await prefs.remove(cacheKey);
            return []; // Возвращаем пустой список (это не ошибка!)
          }

          // Обновляем кэш
          await prefs.setString(cacheKey, json.encode(statusList));

          if (kDebugMode) {
            debugPrint(
                '✅ getDealStatuses - Loaded ${statusList.length} statuses');
          }

          return statusList
              .map((status) => DealStatus.fromJson(status))
              .toList();
        } else {
          debugPrint("❌ getDealStatuses - No valid data in response");
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ getDealStatuses - Ошибка: $e');
      if (bypassCache) {
        debugPrint(
            '🛑 getDealStatuses - bypassCache=true, skip persistent fallback cache');
        rethrow;
      }
      debugPrint('⚠️ getDealStatuses - Используем кэш');

      final cachedStatuses = prefs.getString(cacheKey);
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => DealStatus.fromJson(status))
            .toList();

        debugPrint(
            '✅ getDealStatuses - Загружено ${cachedList.length} статусов из кэша');
        return cachedList;
      } else {
        debugPrint('❌ getDealStatuses - Нет кэшированных данных');
        throw Exception(
            'Ошибка загрузки статусов сделок и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasDeals(int dealStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<Deal> deals =
          await getDeals(dealStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return deals.isNotEmpty;
    } catch (e) {
      ////debugPrint('Error while checking if status has deals!');
      return false;
    }
  }

  Future<Map<String, dynamic>> createDealStatus(
    String title,
    String color,
    int? day,
    String? notificationMessage,
    bool showOnMainPage,
    bool isSuccess,
    bool isFailure,
    bool isUnassembled,
    List<int>? userIds,
    List<int>? changeStatusUserIds, // ✅ НОВОЕ
  ) async {
    final path = await _appendQueryParams('/deal/statuses');

    if (kDebugMode) {
      debugPrint('ApiService: createDealStatus - userIds: $userIds');
      debugPrint(
          'ApiService: createDealStatus - changeStatusUserIds: $changeStatusUserIds'); // ✅ НОВОЕ
    }

    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    final body = {
      'title': title,
      'day': day,
      'color': color,
      'notification_message': notificationMessage,
      'show_on_main_page': showOnMainPage ? 1 : 0,
      'is_success': isSuccess ? 1 : 0,
      'is_failure': isFailure ? 1 : 0,
      'is_unassembled': isUnassembled,
      'organization_id': organizationId?.toString() ?? '',
      if (salesFunnelId != null) 'sales_funnel_id': salesFunnelId.toString(),
      if (userIds != null) 'users': userIds,
      if (changeStatusUserIds != null)
        'change_status_users': changeStatusUserIds, // ✅ НОВОЕ
    };

    if (kDebugMode) {
      debugPrint('ApiService: createDealStatus request body: $body');
    }

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Статус сделки успешно создан'};
    } else {
      return {'success': false, 'message': 'Ошибка создания статуса сделки!'};
    }
  }

  Future<List<DealHistory>> getDealHistory(int dealId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/deal/history/$dealId');
      if (kDebugMode) {
        //debugPrint('ApiService: getDealHistory - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => DealHistory.fromJson(json)).toList();
      } else {
        ////debugPrint('Failed to load deal history!');
        throw Exception('Ошибка загрузки истории сделки!');
      }
    } catch (e) {
      ////debugPrint('Error occurred!');
      throw Exception('Ошибка загрузки истории сделки!');
    }
  }

  Future<List<OrderHistory>> getOrderHistory(int orderId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/history/$orderId');
      if (kDebugMode) {
        //debugPrint('ApiService: getOrderHistory - Generated path: $path');
      }

      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => OrderHistory.fromJson(json)).toList();
      } else {
        ////debugPrint('Failed to load order history!');
        throw Exception('Ошибка загрузки истории заказа!');
      }
    } catch (e) {
      ////debugPrint('Error occurred: $e');
      throw Exception('Ошибка загрузки истории заказа!');
    }
  }

  Future<void> updateDealStatus(
    int dealId,
    int currentStatusId, // from_status_id
    List<int> statusIds, // to_status_id (один или несколько)
    {
    bool isMultiSelect = false, // новый параметр
    String? organizationId,
    String? salesFunnelId,
    int? reasonForRefusalId,
    String? reasonForRefusal,
  }) async {
    if (isMultiSelect) {
      // ============ МУЛЬТИВЫБОР (как было) ============
      final path =
          await _appendQueryParams('/deal/change-multiple-status/$dealId');
      if (kDebugMode) {
        debugPrint('ApiService: MULTI-SELECT mode');
        debugPrint('ApiService: Path: $path');
        debugPrint('ApiService: Statuses: $statusIds');
      }

      final response = await _postRequest(
        path,
        {
          'position': 1,
          'statuses': statusIds,
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Статусы успешно обновлены (multi-select)');
        }
      } else if (response.statusCode == 422) {
        final responseData = jsonDecode(response.body);
        final errorMessage = (responseData is Map<String, dynamic>
                    ? responseData['message']
                    : null)
                ?.toString() ??
            'Вы не можете переместить задачу на эти статусы';
        throw DealStatusUpdateException(
          422,
          errorMessage,
        );
      } else {
        throw Exception('Ошибка обновления статусов сделки!');
      }
    } else {
      // ============ ОДИНОЧНЫЙ ВЫБОР (новая логика) ============
      if (statusIds.isEmpty) {
        throw Exception('Не выбран статус для перемещения');
      }

      final int toStatusId = statusIds.first; // берём первый (и единственный)

      // Формируем URL с query параметрами
      String path = '/deal/changeStatus1/$dealId';
      final queryParams = <String, String>{};

      if (organizationId != null) {
        queryParams['organization_id'] = organizationId;
      }
      if (salesFunnelId != null) {
        queryParams['sales_funnel_id'] = salesFunnelId;
      }

      // Добавляем параметры через _appendQueryParams или вручную
      if (queryParams.isNotEmpty) {
        final query =
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
        path = '$path?$query';
      }

      if (kDebugMode) {
        debugPrint('ApiService: SINGLE-SELECT mode');
        debugPrint('ApiService: Path: $path');
        debugPrint(
            'ApiService: from_status_id: $currentStatusId → to_status_id: $toStatusId');
      }

      final response = await _postRequest(
        path,
        {
          'from_status_id': currentStatusId,
          'to_status_id': toStatusId,
          'position': 1,
          'organization_id': organizationId ?? '1',
          'sales_funnel_id': salesFunnelId ?? '1',
          if (reasonForRefusalId != null)
            'reason_for_refusal_id': reasonForRefusalId,
          if (reasonForRefusal != null && reasonForRefusal.trim().isNotEmpty)
            'reason_for_refusal': reasonForRefusal.trim(),
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Статус успешно обновлён (single-select)');
        }
      } else if (response.statusCode == 422) {
        final responseData = jsonDecode(response.body);
        final errorMessage = (responseData is Map<String, dynamic>
                    ? responseData['message']
                    : null)
                ?.toString() ??
            'Вы не можете переместить задачу на этот статус';
        throw DealStatusUpdateException(
          422,
          errorMessage,
        );
      } else {
        throw Exception('Ошибка обновления статуса сделки!');
      }
    }
  }

  Future<List<DealTask>> getDealTasks(int dealId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/task/getByDeal/$dealId');
    if (kDebugMode) {
      //debugPrint('ApiService: getDealTasks - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((task) => DealTask.fromJson(task))
          .toList();
    } else {
      throw Exception('Ошибка загрузки сделки задачи');
    }
  }

  Future<Map<String, dynamic>> createDeal({
    required String name,
    required int dealStatusId,
    required int? managerId,
    required DateTime? startDate,
    required DateTime? endDate,
    required String sum,
    String? description,
    int? dealtypeId,
    int? leadId,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, int>>? directoryValues,
    List<FileHelper>? files,
    List<int>? userIds, // ✅ НОВОЕ
  }) async {
    try {
      final updatedPath = await _appendQueryParams('/deal');
      if (kDebugMode) {
        debugPrint('ApiService: createDeal - Generated path: $updatedPath');
        debugPrint('ApiService: createDeal - userIds: $userIds'); // ✅ НОВОЕ
      }

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl$updatedPath'));

      request.fields['name'] = name;
      request.fields['deal_status_id'] = dealStatusId.toString();
      request.fields['deal_status_ids[0]'] = dealStatusId.toString();
      request.fields['position'] = '1';

      if (managerId != null) {
        request.fields['manager_id'] = managerId.toString();
      }
      if (startDate != null) {
        request.fields['start_date'] =
            DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        request.fields['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      request.fields['sum'] = sum;

      if (description != null) {
        request.fields['description'] = description;
      }
      if (dealtypeId != null) {
        request.fields['deal_type_id'] = dealtypeId.toString();
      }
      if (leadId != null) {
        request.fields['lead_id'] = leadId.toString();
      }

      // ✅ НОВОЕ: Добавляем user_ids
      if (userIds != null && userIds.isNotEmpty) {
        for (int i = 0; i < userIds.length; i++) {
          request.fields['users[$i]'] = userIds[i].toString();
        }
        debugPrint('ApiService: createDeal - Added user_ids: $userIds');
      }

      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['deal_custom_fields[$i][key]'] = field['key'] ?? '';
          request.fields['deal_custom_fields[$i][value]'] =
              field['value'] ?? '';
          request.fields['deal_custom_fields[$i][type]'] =
              field['type'] ?? 'string';
        }
      }

      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          var directoryValue = directoryValues[i];
          request.fields['directory_values[$i][entry_id]'] =
              directoryValue['entry_id'].toString();
          request.fields['directory_values[$i][directory_id]'] =
              directoryValue['directory_id'].toString();
        }
      }

      if (files != null && files.isNotEmpty) {
        for (var fileData in files) {
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

      final response = await _multipartPostRequest('/deal', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'deal_created_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('name')) {
          return {'success': false, 'message': 'invalid_name_length'};
        }
        if (response.body.contains('directory_values')) {
          return {'success': false, 'message': 'error_directory_values'};
        }
        if (response.body.contains('type')) {
          return {'success': false, 'message': 'invalid_field_type'};
        }
        if (response.body.contains('deal_custom_fields')) {
          return {'success': false, 'message': 'invalid_deal_custom_fields'};
        }
        return {'success': false, 'message': 'unknown_error'};
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'error_server_text'};
      } else {
        return {'success': false, 'message': 'error_deal_create_successfully'};
      }
    } catch (e) {
      return {'success': false, 'message': 'error_deal_create_successfully'};
    }
  }

  Future<Map<String, dynamic>> updateDeal({
    required int dealId,
    required String name,
    required int dealStatusId,
    required int? managerId,
    required DateTime? startDate,
    required DateTime? endDate,
    required String sum,
    String? description,
    int? dealtypeId,
    required int? leadId,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, int>>? directoryValues,
    List<FileHelper>? files,
    List<int>? dealStatusIds, // ✅ НОВОЕ
    List<int>? existingFiles, // ID существующих файлов
    List<int>? userIds, // ✅ НОВОЕ: массив ID пользователей
    int? reasonForRefusalId,
    String? reasonForRefusal,
  }) async {
    // Формируем путь с query-параметрами
    final updatedPath = await _appendQueryParams('/deal/$dealId');
    if (kDebugMode) {
      debugPrint('ApiService: updateDeal - Generated path: $updatedPath');
      debugPrint('ApiService: updateDeal - userIds: $userIds'); // ✅ НОВОЕ
    }
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl$updatedPath'));

    request.fields['name'] = name;
    request.fields['deal_status_id'] = dealStatusId.toString();
    if (managerId != null) request.fields['manager_id'] = managerId.toString();
    if (startDate != null)
      request.fields['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
    if (endDate != null)
      request.fields['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
    if (sum.isNotEmpty) request.fields['sum'] = sum;
    if (description != null) request.fields['description'] = description;
    if (dealtypeId != null)
      request.fields['deal_type_id'] = dealtypeId.toString();
    if (leadId != null) request.fields['lead_id'] = leadId.toString();
    if (reasonForRefusalId != null) {
      request.fields['reason_for_refusal_id'] = reasonForRefusalId.toString();
    }
    if (reasonForRefusal != null && reasonForRefusal.trim().isNotEmpty) {
      request.fields['reason_for_refusal'] = reasonForRefusal.trim();
    }

    // Отправляем массив статусов
    if (dealStatusIds != null && dealStatusIds.isNotEmpty) {
      for (int i = 0; i < dealStatusIds.length; i++) {
        request.fields['deal_status_ids[$i]'] = dealStatusIds[i].toString();
      }
      debugPrint('ApiService: Отправка deal_status_ids: $dealStatusIds');
    }

    // ✅ НОВОЕ: Добавляем user_ids
    if (userIds != null && userIds.isNotEmpty) {
      for (int i = 0; i < userIds.length; i++) {
        request.fields['users[$i]'] = userIds[i].toString();
      }
      debugPrint('ApiService: updateDeal - Added user_ids: $userIds');
    }

    final customFieldsList = customFields ?? [];
    if (customFieldsList.isNotEmpty) {
      for (int i = 0; i < customFieldsList.length; i++) {
        var field = customFieldsList[i];
        request.fields['deal_custom_fields[$i][key]'] =
            field['key']!.toString();
        request.fields['deal_custom_fields[$i][value]'] =
            field['value']!.toString();
        request.fields['deal_custom_fields[$i][type]'] =
            field['type']?.toString() ?? 'string';
      }
    }

    final directoryValuesList = directoryValues ?? [];
    if (directoryValuesList.isNotEmpty) {
      for (int i = 0; i < directoryValuesList.length; i++) {
        var value = directoryValuesList[i];
        request.fields['directory_values[$i][directory_id]'] =
            value['directory_id'].toString();
        request.fields['directory_values[$i][entry_id]'] =
            value['entry_id'].toString();
      }
    }

    // Добавляем ID существующих файлов
    if (existingFiles != null && existingFiles.isNotEmpty) {
      for (int i = 0; i < existingFiles.length; i++) {
        request.fields['existing_files[$i]'] = existingFiles[i].toString();
      }
    }

    // Отправляем только новые файлы (id == 0)
    if (files != null && files.isNotEmpty) {
      final newFiles = files.where((f) => f.id == 0).toList();
      for (var fileData in newFiles) {
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

    final response = await _multipartPostRequest('/deal/$dealId', request);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'deal_updated_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('"name"')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('sum')) {
        return {'success': false, 'message': 'invalid_sum_format'};
      }
      if (response.body.contains('type')) {
        return {'success': false, 'message': 'invalid_field_type'};
      }
      if (response.body.contains('deal_custom_fields')) {
        return {'success': false, 'message': 'invalid_custom_fields'};
      }
      return {'success': false, 'message': 'unknown_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'error_deal_update'};
    }
  }

  Future<Map<String, dynamic>> deleteDealStatuses(int dealStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/deal/statuses/$dealStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteDealStatuses - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete dealStatus!');
    }
  }

  Future<Map<String, dynamic>> deleteDeal(int dealId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/deal/$dealId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteDeal - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete deal!');
    }
  }

  Future<Map<String, dynamic>> getCustomFieldsdeal() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/deal/get/custom-fields');
    if (kDebugMode) {
      //debugPrint('ApiService: getCustomFieldsdeal - Generated path: $path');
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

  Future<Map<String, dynamic>> updateDealStatusEdit(
    int dealStatusId,
    String title,
    int day,
    bool isSuccess,
    bool isFailure,
    bool isUnassembled,
    String notificationMessage,
    bool showOnMainPage,
    List<int>? userIds, // пользователи, которые могут ВИДЕТЬ сделки
    List<int>?
        changeStatusUserIds, // ✅ НОВОЕ: пользователи, которые могут ИЗМЕНЯТЬ статус
  ) async {
    final path = await _appendQueryParams('/deal/statuses/$dealStatusId');

    if (kDebugMode) {
      debugPrint('ApiService: updateDealStatusEdit - userIds: $userIds');
      debugPrint(
          'ApiService: updateDealStatusEdit - changeStatusUserIds: $changeStatusUserIds'); // ✅ НОВОЕ
    }

    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();

    final payload = {
      "title": title,
      "day": day,
      "color": "#000",
      "is_success": isSuccess ? 1 : 0,
      "is_failure": isFailure ? 1 : 0,
      "is_unassembled": isUnassembled,
      "notification_message": notificationMessage,
      "show_on_main_page": showOnMainPage ? 1 : 0,
      "organization_id": organizationId?.toString() ?? '',
      if (salesFunnelId != null) "sales_funnel_id": salesFunnelId.toString(),
      // ✅ Добавляем оба массива пользователей
      if (userIds != null) "users": userIds,
      if (changeStatusUserIds != null)
        "change_status_users": changeStatusUserIds, // ✅ НОВОЕ
    };

    if (kDebugMode) {
      debugPrint('ApiService: updateDealStatusEdit payload: $payload');
    }

    final response = await _patchRequest(path, payload);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update dealStatus!');
    }
  }

  Future<DealStatus> getDealStatus(int dealStatusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/deal/statuses/$dealStatusId');
    if (kDebugMode) {
      //debugPrint('ApiService: getDealStatus - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return DealStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

  Future<Map<String, dynamic>> createTaskFromDeal({
    required int dealId,
    required String name,
    required int? statusId,
    required int? taskStatusId,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    List<Map<String, dynamic>>? customFields,
    List<String>? filePaths,
    List<Map<String, int>>? directoryValues,
    int position = 1,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/task/createFromDeal/$dealId');
      if (kDebugMode) {
        //debugPrint('ApiService: createTaskFromDeal - Generated path: $path');
      }
      var uri = Uri.parse('$baseUrl$path');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['position'] = position.toString();

      if (priority != null) {
        request.fields['priority_level'] = priority.toString();
      }
      if (startDate != null) {
        request.fields['from'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        request.fields['to'] = DateFormat('yyyy-MM-dd').format(endDate);
      }
      if (projectId != null) {
        request.fields['project_id'] = projectId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      if (userId != null && userId.isNotEmpty) {
        for (int i = 0; i < userId.length; i++) {
          request.fields['users[$i][user_id]'] = userId[i].toString();
        }
      }

      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['task_custom_fields[$i][key]'] = field['key'] ?? '';
          request.fields['task_custom_fields[$i][value]'] =
              field['value'] ?? '';
          request.fields['task_custom_fields[$i][type]'] =
              field['type'] ?? 'string';
        }
      }

      if (directoryValues != null && directoryValues.isNotEmpty) {
        for (int i = 0; i < directoryValues.length; i++) {
          var directoryValue = directoryValues[i];
          request.fields['directory_values[$i][entry_id]'] =
              directoryValue['entry_id'].toString();
          request.fields['directory_values[$i][directory_id]'] =
              directoryValue['directory_id'].toString();
        }
      }

      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      final response = await _multipartPostRequest('', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_deal_create_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'error_start_date_task',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'error_end_date_task',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'error_priority_level',
          };
        }
        if (response.body.contains('directory_values')) {
          return {
            'success': false,
            'message': 'error_directory_values',
          };
        }
        if (response.body.contains('type')) {
          return {
            'success': false,
            'message': 'invalid_field_type',
          };
        }
        if (response.body.contains('task_custom_fields')) {
          return {
            'success': false,
            'message': 'invalid_task_custom_fields',
          };
        }
        return {
          'success': false,
          'message': 'unknown_error',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        return {
          'success': false,
          'message': 'error_create_task',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_create_task',
      };
    }
  }

  Future<DirectoryLinkResponse> getDealDirectoryLinks() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/directoryLink/deal');
    if (kDebugMode) {
      //debugPrint('ApiService: getDealDirectoryLinks - Generated path: $path');
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

  Future<UsersDataResponse> getDealExecutors({String? search}) async {
    final token = await getToken();
    String path = await _appendQueryParams('/department/get/users');
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (kDebugMode) {
      debugPrint('ApiService: getDealExecutors - Path: $path');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load deal executors: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (kDebugMode) {
      final result = data['result'];
      final count = result is List ? result.length : 0;
      debugPrint('ApiService: getDealExecutors - Loaded $count executors');
    }
    return UsersDataResponse.fromJson(data);
  }

  Future<List<String>> getDealCustomFields() async {
    final path = await _appendQueryParams('/deal/get/custom-fields');

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

  Future<List<String>> getDealCustomFieldValues(String key) async {
    final path =
        await _appendQueryParams('/deal/get/custom-field-values?key=$key');
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
}

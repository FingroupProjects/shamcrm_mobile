part of '../api_service.dart';

extension ApiAnalyticsX on ApiService {
  Never _throwAnalyticsChartApiError(
    http.Response response,
    String fallbackMessage,
  ) {
    final message = _extractErrorMessageFromResponse(response);
    throw ApiException(message ?? fallbackMessage, response.statusCode);
  }

  Future<List<UserTask>> getUserTask() async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/user');
      if (kDebugMode) {
        //debugPrint('ApiService: getUserTask - Generated path: $path');
      }

      ////debugPrint('Отправка запроса на /user');
      final response = await _analyticsRequest(path);
      // ////debugPrint('Статус ответа!');
      // ////debugPrint('Тело ответа!');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Убедитесь, что данные соответствуют ожидаемой структуре
        if (data['result'] != null && data['result'] is List) {
          final usersList = (data['result'] as List)
              .map((user) => UserTask.fromJson(user))
              .toList();

          return usersList;
        } else {
          throw Exception('Неверная структура данных пользователей');
        }
      } else {
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получение данных графика для дашборда
  Future<List<ChartData>> getLeadChart() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/lead-chart');
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadChart - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.map((json) => ChartData.fromJson(json)).toList();
      } else {
        throw ('Нет данных графика в ответе "Клиенты"');
      }
    } else {
      throw ('Ошибка загрузки данных график клиента!');
    }
  }

  Future<LeadConversion> getLeadConversionData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/leadConversion-chart');
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadConversionData - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final conversion = LeadConversion.fromJson(data);
        return conversion;
      } else {
        throw ('Нет данных графика в ответе "Конверсия лидов');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('');
    }
  }

  Future<DealStatsResponse> getDealStatsData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/dealStats');
    if (kDebugMode) {
      //debugPrint('ApiService: getDealStatsData - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getDealStatsData',
      fallbackMessage: 'Ошибка загрузки данных графика сделок!',
    );
    return DealStatsResponse.fromJson(jsonData);
  }

  Future<TaskChart> getTaskChartData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/task-chart');
    if (kDebugMode) {
      //debugPrint('ApiService: getTaskChartData - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['result'] != null && jsonMap['result']['data'] != null) {
          final taskChart = TaskChart.fromJson(jsonMap);
          return taskChart;
        } else {
          throw ('Нет данных графика в ответе "Задачи');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера!');
      } else {
        throw ('Ошибка загрузки данных графика!');
      }
    } catch (e) {
      throw ('Ошибка получения данных!');
    }
  }

  Future<ProcessSpeed> getProcessSpeedData() async {
    final enteredDomainMap = await ApiService().getEnteredDomain();
    // Извлекаем значения из Map
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/lead-process-speed');
    if (kDebugMode) {
      //debugPrint('ApiService: getProcessSpeedData - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final speed = ProcessSpeed.fromJson(data);
        return speed;
      } else {
        throw ('Нет данных графика в ответе "Скорость обработки"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных графика Скорость обработки');
    }
  }

  Future<List<UserTaskCompletion>> getUsersChartData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/users-chart');
    if (kDebugMode) {
      //debugPrint('ApiService: getUsersChartData - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['result'] != null) {
        final List<dynamic> resultList = data['result'];
        return resultList
            .map((item) => UserTaskCompletion.fromJson(item))
            .toList();
      } else {
        throw ('Нет данных графика в ответе "Выполнение целей"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных графика Выполнение целей!');
    }
  }

  /// Получение графика лидов с датами
  /// Endpoint: /api/dashboard/lead-chart?fromDate=YYYY-MM-DD&toDate=YYYY-MM-DD
  Future<LeadChartResponse> getLeadChartWithDates({
    required String fromDate,
    required String toDate,
  }) async {
    final path = await _appendQueryParams(
      '/dashboard/lead-chart?fromDate=$fromDate&toDate=$toDate',
    );

    if (kDebugMode) {
      debugPrint('ApiService: getLeadChartWithDates - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getLeadChartWithDates',
      fallbackMessage: 'Ошибка загрузки данных графика лидов!',
    );
    return LeadChartResponse.fromJson(jsonData);
  }

  /// Получение конверсии по статусам
  /// Endpoint: /api/v2/dashboard/leadConversion-by-statuses-chart
  Future<LeadConversionByStatusesResponse> getLeadConversionByStatuses() async {
    final path = await _appendQueryParams(
        '/v2/dashboard/leadConversion-by-statuses-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getLeadConversionByStatuses - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getLeadConversionByStatuses',
      fallbackMessage: 'Ошибка загрузки данных конверсии по статусам!',
    );
    return LeadConversionByStatusesResponse.fromJson(jsonData);
  }

  /// Получение скорости обработки лидов (V2)
  /// Endpoint: /api/v2/dashboard/lead-process-speed
  Future<LeadProcessSpeedResponse> getLeadProcessSpeedV2() async {
    final path = await _appendQueryParams('/v2/dashboard/lead-process-speed');

    if (kDebugMode) {
      debugPrint('ApiService: getLeadProcessSpeedV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getLeadProcessSpeedV2',
      fallbackMessage: 'Ошибка загрузки данных скорости обработки!',
    );
    return LeadProcessSpeedResponse.fromJson(jsonData);
  }

  /// Получение графика пользователей (V2)
  /// Endpoint: /api/v2/dashboard/users-chart
  Future<UsersChartResponse> getUsersChartV2() async {
    final path = await _appendQueryParams('/v2/dashboard/users-chart');

    if (kDebugMode) {
      debugPrint('ApiService: getUsersChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getUsersChartV2',
      fallbackMessage: 'Ошибка загрузки данных пользователей!',
    );
    return UsersChartResponse.fromJson(jsonData);
  }

  /// Получение статистики для 4 карточек (V2)
  /// Endpoint: /api/v2/dashboard/statistics
  Future<DashboardStatisticsResponse> getDashboardStatisticsV2() async {
    final path = await _appendQueryParams('/v2/dashboard/statistics');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getDashboardStatisticsV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DashboardStatisticsResponse.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки статистики!');
      }
    } catch (e) {
      debugPrint('ApiService: getDashboardStatisticsV2 error: $e');
      throw Exception('Ошибка получения статистики: $e');
    }
  }

  /// Получение настроек/доступов графиков для аналитики (V2)
  /// Endpoint: /api/v2/dashboard-settings
  Future<List<DashboardSettingItem>> getDashboardSettingsV2() async {
    final path = await _appendQueryParams('/v2/dashboard-settings');

    if (kDebugMode) {
      debugPrint('ApiService: getDashboardSettingsV2 - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode != 200) {
        throw Exception(
          'Ошибка загрузки настроек графиков! Код: ${response.statusCode}',
        );
      }

      final dynamic jsonData = json.decode(response.body);
      final dynamic result =
          jsonData is Map<String, dynamic> ? jsonData['result'] : null;

      if (result is! List) {
        return [];
      }

      return result
          .whereType<Map<String, dynamic>>()
          .map(DashboardSettingItem.fromJson)
          .where((item) => item.nameEn.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('ApiService: getDashboardSettingsV2 error: $e');
      rethrow;
    }
  }

  /// Применение фильтров аналитики (V2)
  /// Endpoint: /api/v2/dashboard/filters
  Future<void> applyAnalyticsFiltersV2(Map<String, dynamic> filters) async {
    const path = '/v2/dashboard/filters';

    if (kDebugMode) {
      debugPrint('ApiService: applyAnalyticsFiltersV2 - Filters: $filters');
    }

    try {
      final response = await _postRequest(path, filters);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw Exception('Ошибка применения фильтров аналитики!');
    } catch (e) {
      debugPrint('ApiService: applyAnalyticsFiltersV2 error: $e');
      throw Exception('Ошибка применения фильтров аналитики: $e');
    }
  }

  /// Конверсия лидов (V2)
  /// Endpoint: /api/v2/dashboard/leadConversion-chart
  Future<LeadConversion> getLeadConversionDataV2() async {
    final path = await _appendQueryParams('/v2/dashboard/leadConversion-chart');

    if (kDebugMode) {
      debugPrint('ApiService: getLeadConversionDataV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getLeadConversionDataV2',
      fallbackMessage: 'Ошибка загрузки данных конверсии лидов!',
    );

    if (jsonData.isEmpty) {
      throw Exception('Нет данных графика в ответе "Конверсия лидов"');
    }

    return LeadConversion.fromJson(jsonData);
  }

  /// Задачи (V2)
  /// Endpoint: /api/v2/dashboard/task-chart
  Future<TaskChartV2Response> getTaskChartDataV2() async {
    final path = await _appendQueryParams('/v2/dashboard/task-chart');

    if (kDebugMode) {
      debugPrint('ApiService: getTaskChartDataV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getTaskChartDataV2',
      fallbackMessage: 'Ошибка загрузки данных графика задач!',
    );
    return TaskChartV2Response.fromJson(jsonData);
  }

  /// Источники лидов (V2)
  /// Endpoint: /api/v2/dashboard/source-of-leads-chart
  Future<SourceOfLeadsChartResponse> getSourceOfLeadsChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/source-of-leads-chart');

    if (kDebugMode) {
      debugPrint('ApiService: getSourceOfLeadsChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getSourceOfLeadsChartV2',
      fallbackMessage: 'Ошибка загрузки источников лидов!',
    );
    return SourceOfLeadsChartResponse.fromJson(jsonData);
  }

  /// Сделки по менеджерам (V2)
  /// Endpoint: /api/v2/dashboard/deals-by-managers
  Future<DealsByManagersResponse> getDealsByManagersV2() async {
    final path = await _appendQueryParams('/v2/dashboard/deals-by-managers');

    if (kDebugMode) {
      debugPrint('ApiService: getDealsByManagersV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getDealsByManagersV2',
      fallbackMessage: 'Ошибка загрузки данных менеджеров!',
    );
    return DealsByManagersResponse.fromJson(jsonData);
  }

  /// Заказы интернет-магазина (V2)
  /// Endpoint: /api/v2/dashboard/online-store-orders-chart
  Future<OnlineStoreOrdersResponse> getOnlineStoreOrdersChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/online-store-orders-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getOnlineStoreOrdersChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getOnlineStoreOrdersChartV2',
      fallbackMessage: 'Ошибка загрузки заказов интернет-магазина!',
    );
    return OnlineStoreOrdersResponse.fromJson(jsonData);
  }

  /// Выполненные задачи (график)
  /// Endpoint: /api/v2/dashboard/completed-task-chart
  Future<CompletedTasksChartResponse> getCompletedTasksChartV2() async {
    final path = await _appendQueryParams('/v2/dashboard/completed-task-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getCompletedTasksChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getCompletedTasksChartV2',
      fallbackMessage: 'Ошибка загрузки выполненных задач!',
    );
    return CompletedTasksChartResponse.fromJson(jsonData);
  }

  /// Телефония и события (график)
  /// Endpoint: /api/v2/dashboard/telephony-and-events-chart
  Future<TelephonyEventsResponse> getTelephonyAndEventsChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/telephony-and-events-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getTelephonyAndEventsChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getTelephonyAndEventsChartV2',
      fallbackMessage: 'Ошибка загрузки телефонии и событий!',
    );
    return TelephonyEventsResponse.fromJson(jsonData);
  }

  /// Статистика задач по проектам
  /// Endpoint: /api/v2/dashboard/task-statistics-by-project-chart
  Future<TaskStatsByProjectResponse> getTaskStatsByProjectChartV2() async {
    final path = await _appendQueryParams(
        '/v2/dashboard/task-statistics-by-project-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getTaskStatsByProjectChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getTaskStatsByProjectChartV2',
      fallbackMessage: 'Ошибка загрузки статистики задач по проектам!',
    );
    return TaskStatsByProjectResponse.fromJson(jsonData);
  }

  /// Подключенные аккаунты
  /// Endpoint: /api/v2/dashboard/connected-accounts-chart
  Future<ConnectedAccountsResponse> getConnectedAccountsChartV2(
      {int? channel}) async {
    var path =
        await _appendQueryParams('/v2/dashboard/connected-accounts-chart');
    if (channel != null) {
      path += '&channel=$channel';
    }

    if (kDebugMode) {
      debugPrint(
          'ApiService: getConnectedAccountsChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getConnectedAccountsChartV2',
      fallbackMessage: 'Ошибка загрузки подключенных аккаунтов!',
    );
    return ConnectedAccountsResponse.fromJson(jsonData);
  }

  /// ROI рекламы (график)
  /// Endpoint: /api/v2/dashboard/advertising-ROI-chart
  Future<AdvertisingRoiResponse> getAdvertisingRoiChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/advertising-ROI-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getAdvertisingRoiChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getAdvertisingRoiChartV2',
      fallbackMessage: 'Ошибка загрузки ROI рекламы!',
    );
    return AdvertisingRoiResponse.fromJson(jsonData);
  }

  /// Аналитика звонков по часам
  /// Endpoint: /api/v2/dashboard/telephony-and-events-by-hour
  Future<TelephonyByHourResponse> getTelephonyByHourChartV2({
    DateTime? date,
  }) async {
    var path =
        await _appendQueryParams('/v2/dashboard/telephony-and-events-by-hour');
    if (date != null) {
      final oneDay = DateFormat('yyyy/MM/dd').format(date);
      final separator = path.contains('?') ? '&' : '?';
      path +=
          '${separator}date_from=${Uri.encodeComponent(oneDay)}&date_to=${Uri.encodeComponent(oneDay)}';
    }

    if (kDebugMode) {
      debugPrint(
          'ApiService: getTelephonyByHourChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getTelephonyByHourChartV2',
      fallbackMessage: 'Ошибка загрузки аналитики звонков по часам!',
    );
    return TelephonyByHourResponse.fromJson(jsonData);
  }

  /// Таргетированная реклама (Meta Ads)
  /// Endpoint: /api/v2/dashboard/targeted-advertising-chart
  Future<TargetedAdsResponse> getTargetedAdvertisingChartV2(
      {int? projectId}) async {
    var path =
        await _appendQueryParams('/v2/dashboard/targeted-advertising-chart');
    if (projectId != null) {
      path += '&project_id=$projectId';
    }

    if (kDebugMode) {
      debugPrint(
          'ApiService: getTargetedAdvertisingChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getTargetedAdvertisingChartV2',
      fallbackMessage: 'Ошибка загрузки таргетированной рекламы!',
    );
    return TargetedAdsResponse.fromJson(jsonData);
  }

  /// ТОП продаваемых товаров (V2)
  /// Endpoint: /api/v2/dashboard/top-selling-products-chart
  Future<TopSellingProductsResponse> getTopSellingProductsChartV2() async {
    final path =
        await _appendQueryParams('/v2/dashboard/top-selling-products-chart');

    if (kDebugMode) {
      debugPrint(
          'ApiService: getTopSellingProductsChartV2 - Generated path: $path');
    }

    final jsonData = await _getAnalyticsChartJsonMap(
      path,
      debugLabel: 'getTopSellingProductsChartV2',
      fallbackMessage: 'Ошибка загрузки данных товаров!',
    );
    return TopSellingProductsResponse.fromJson(jsonData);
  }

  Future<DealStatsResponseManager> getDealStatsManagerData() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/dealStats/for-manager');
    if (kDebugMode) {
      //debugPrint('ApiService: getDealStatsManagerData - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DealStatsResponseManager.fromJson(jsonData);
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера!');
      } else {
        throw Exception('Ошибка загрузки данных!');
      }
    } catch (e) {
      ////debugPrint('Ошибка запроса!');
      throw ('');
    }
  }

  /// Получение данных графика для дашборда
  Future<List<ChartDataManager>> getLeadChartManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/lead-chart/for-manager');
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadChartManager - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.map((json) => ChartDataManager.fromJson(json)).toList();
      } else {
        throw ('Нет данных графика в ответе "Клиенты"');
      }
    } else {
      throw ('Ошибка загрузки данных график клиента!');
    }
  }

  Future<LeadConversionManager> getLeadConversionDataManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/dashboard/leadConversion-chart/for-manager');
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadConversionDataManager - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final conversion = LeadConversionManager.fromJson(data);
        return conversion;
      } else {
        throw ('Нет данных графика в ответе "Конверсия лидов');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('');
    }
  }

  Future<ProcessSpeedManager> getProcessSpeedDataManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/dashboard/lead-process-speed/for/manager');
    if (kDebugMode) {
      //debugPrint('ApiService: getProcessSpeedDataManager - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final speed = ProcessSpeedManager.fromJson(data);
        return speed;
      } else {
        throw ('Нет данных графика в ответе "Скорость обработки"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных графика Скорость обработки');
    }
  }

  Future<TaskChartManager> getTaskChartDataManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/task-chart/for-manager');
    if (kDebugMode) {
      //debugPrint('ApiService: getTaskChartDataManager - Generated path: $path');
    }

    try {
      final response = await _analyticsRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['result'] != null && jsonMap['result']['data'] != null) {
          final taskChart = TaskChartManager.fromJson(jsonMap);
          return taskChart;
        } else {
          throw ('Нет данных графика в ответе "Задачи');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера!');
      } else {
        throw ('Ошибка загрузки данных графика!');
      }
    } catch (e) {
      throw ('Ошибка получения данных!');
    }
  }

  Future<UserTaskCompletionManager> getUserStatsManager() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/dashboard/completed-task-chart');
    if (kDebugMode) {
      //debugPrint('ApiService: getUserStatsManager - Generated path: $path');
    }

    final response = await _analyticsRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['result'] != null) {
        return UserTaskCompletionManager.fromJson(data);
      } else {
        throw ('Нет данных графика в ответе');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Неизвестная ошибка');
    }
  }
}

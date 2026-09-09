part of '../api_service.dart';

extension ApiWarehouseDashboardsX on ApiService {
  Future<List<EmployeeRemainingModel>> getEmployeesByRemaining({
    required String month,
  }) async {
    await ensureInitialized();

    try {
      final token = await getToken();
      if (token == null) {
        throw ApiException('Токен не найден', 401);
      }
      if (baseUrl == null || baseUrl!.isEmpty) {
        throw ApiException('Base URL is not initialized', 500);
      }

      final organizationId = await getSelectedOrganization();
      final salesFunnelId = await getSelectedSalesFunnel() ??
          await ensureSelectedSalesFunnelInitialized();

      if (organizationId == null ||
          organizationId.isEmpty ||
          organizationId == 'null') {
        throw ApiException('organization_id не найден', 400);
      }

      if (salesFunnelId == null ||
          salesFunnelId.isEmpty ||
          salesFunnelId == 'null') {
        throw ApiException('sales_funnel_id не найден', 400);
      }

      final uri = Uri.parse('$baseUrl/employee/get-by-remaining').replace(
        queryParameters: {
          'month': month,
          'organization_id': organizationId,
          'sales_funnel_id': salesFunnelId,
        },
      );

      debugPrint('ApiService: getEmployeesByRemaining -> $uri');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'web',
        },
      );
      debugPrint(
        'ApiService: getEmployeesByRemaining status=${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        final employeesData = rawData is List
            ? rawData
            : rawData is Map<String, dynamic>
                ? (rawData['result'] is List
                    ? rawData['result']
                    : rawData['result'] is Map<String, dynamic>
                        ? rawData['result']['data']
                        : rawData['data'])
                : null;

        if (employeesData is List) {
          return employeesData
              .whereType<Map<String, dynamic>>()
              .map(EmployeeRemainingModel.fromJson)
              .toList();
        }
        return const [];
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении списка сотрудников!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ResultDashboardGoodsReport> getSalesDashboardGoodsReport({
    int page = 1,
    int perPage = 20,
    Map<String, dynamic>? filters,
    String? search,
  }) async {
    String path = '/dashboard/goods-report?';

    final categoryId = filters?['category_id'] as int?;
    final daysWithoutMovement = filters?['days_without_movement'] as int?;
    final goodId = filters?['good_id'] as int?;
    final sumFrom = filters?['sum_from'] as String?;
    final sumTo = filters?['sum_to'] as String?;

    if (categoryId != null) path += '&category_id=$categoryId';
    if (daysWithoutMovement != null)
      path += '&days_without_movement=$daysWithoutMovement';
    if (goodId != null) path += '&good_id=$goodId';
    if (sumFrom != null && sumFrom.isNotEmpty) path += '&sum_from=$sumFrom';
    if (sumTo != null && sumTo.isNotEmpty) path += '&sum_to=$sumTo';
    if (search != null && search.isNotEmpty) path += '&search=$search';
    path += '&page=$page&per_page=$perPage';

    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint(
          'ApiService: getSalesDashboardGoodsReport - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = SafeConverters.toMap(json.decode(response.body));
        debugPrint("Полученные данные по отчёту товаров: $rawData");

        return ResultDashboardGoodsReport.fromJson(
          SafeConverters.toMap(rawData['result']),
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных отчёта товаров!',
          response.statusCode,
        );
      }
    } catch (e) {
      throw e;
    }
  }

  Future<String> getSalesDashboardGoodsReportTotalSum({
    Map<String, dynamic>? filters,
    String? search,
  }) async {
    String path = '/dashboard/goods-report-total-sum?';

    final categoryId = filters?['category_id'] as int?;
    final daysWithoutMovement = filters?['days_without_movement'] as int?;
    final goodId = filters?['good_id'] as int?;
    final sumFrom = filters?['sum_from'] as String?;
    final sumTo = filters?['sum_to'] as String?;

    if (categoryId != null) path += '&category_id=$categoryId';
    if (daysWithoutMovement != null) {
      path += '&days_without_movement=$daysWithoutMovement';
    }
    if (goodId != null) path += '&good_id=$goodId';
    if (sumFrom != null && sumFrom.isNotEmpty) path += '&sum_from=$sumFrom';
    if (sumTo != null && sumTo.isNotEmpty) path += '&sum_to=$sumTo';
    if (search != null && search.isNotEmpty) path += '&search=$search';

    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint(
          'ApiService: getSalesDashboardGoodsReportTotalSum - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученная общая сумма по отчёту товаров: $rawData");

        final resultData =
            rawData is Map<String, dynamic> ? rawData['result'] : null;
        final totalSource = resultData is Map
            ? Map<String, dynamic>.from(resultData)
            : rawData is Map<String, dynamic>
                ? rawData
                : <String, dynamic>{};

        return DashboardGoodsReportTotal.fromJson(totalSource).totalSum;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении общей суммы отчёта товаров!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BatchData>> getBatchRemainders({
    required int goodVariantId,
    required int storageId,
    required int supplierId,
  }) async {
    String path = '/supplier-return-documents/get/good-variant-batch-remainders'
        '?good_variant_id=$goodVariantId'
        '&storage_id=$storageId'
        '&supplier_id=$supplierId';

    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint('ApiService: getBatchRemainders - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученные данные по остаткам партий: $rawData");

        final resultData = rawData['result'] as List<dynamic>;
        return resultData
            .map((item) => BatchData.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных остатков партий!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _buildDetailedDashboardCommonParams({
    int? page,
    int? perPage,
    Map<String, dynamic>? filters,
    String? search,
  }) {
    final leadId = filters?['lead_id']?.toString() ?? '';
    return <String, String>{
      'page': (page ?? 1).toString(),
      'per_page': (perPage ?? 20).toString(),
      'limit': (perPage ?? 20).toString(),
      'lead_id': leadId,
      'client_id': leadId,
      'supplier_id': filters?['supplier_id']?.toString() ?? '',
      'date_from': _formatDetailedReportDate(filters?['date_from']),
      'date_to': _formatDetailedReportDate(filters?['date_to']),
      'sum_from': filters?['sum_from']?.toString() ?? '',
      'sum_to': filters?['sum_to']?.toString() ?? '',
      'category_id': filters?['category_id']?.toString() ?? '',
      'days_without_movement':
          filters?['days_without_movement']?.toString() ?? '',
      'article_id': filters?['article_id']?.toString() ?? '',
      'good_id': filters?['good_id']?.toString() ?? '',
      'status_id': filters?['status_id']?.toString() ?? '',
      'search': search?.trim() ?? '',
      'period': filters?['period']?.toString() ?? '',
      'year': filters?['year']?.toString() ?? '',
      'storage_id': filters?['storage_id']?.toString() ?? '',
    };
  }

  String _formatDetailedReportDate(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  /// Получение баланса денежных средств
  Future<DashboardTopPart> getSalesDashboardTopPart() async {
    // Формируем параметры запроса
    var path = await _appendQueryParams('/fin/dashboard');

    debugPrint("ApiService: getSalesDashboardTopPart path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DashboardTopPart.fromJson(SafeConverters.toMap(data));
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

  Future<List<AllExpensesData>> getExpenseStructure() async {
    // Define all periods to fetch
    final periods = [
      ExpensePeriodEnum.today,
      ExpensePeriodEnum.week,
      ExpensePeriodEnum.month,
      ExpensePeriodEnum.quarter,
      ExpensePeriodEnum.year
    ];

    // List to store results
    final List<AllExpensesData> allExpensesData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path = await _appendQueryParams(
          '/fin/dashboard/expense-structure?period=${period.name}');
      debugPrint("ApiService: getExpenseStructure path: $path");

      try {
        // Make the API request
        final response = await _getRequest(path);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final expenseDashboard = ExpenseDashboard.fromJson(SafeConverters.toMap(data));
          // Create AllExpensesData for this period
          allExpensesData.add(AllExpensesData(
            period: period,
            data: expenseDashboard,
          ));
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка для периода $period',
            response.statusCode,
          );
        }
      } catch (e) {
        // Log errors for individual periods
        debugPrint("Error fetching data for period $period: $e");
        rethrow; // Rethrow to allow caller to handle
      }
    }

    return allExpensesData;
  }

  /// Загрузка данных expense structure для конкретного периода
  Future<AllExpensesData> getExpenseStructureForPeriod(
    ExpensePeriodEnum period,
  ) async {
    final path = await _appendQueryParams(
        '/fin/dashboard/expense-structure?period=${period.name}');

    debugPrint(
        "ApiService: getExpenseStructureForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final expenseDashboard = ExpenseDashboard.fromJson(SafeConverters.toMap(data));

        return AllExpensesData(
          period: period,
          data: expenseDashboard,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching expense structure for period $period: $e");
      rethrow;
    }
  }

  Future<List<AllSalesDynamicsData>> getSalesDynamics() async {
    // Define all periods to fetch
    final periods = [
      SalesDynamicsTimePeriod.year,
      SalesDynamicsTimePeriod.previousYear,
    ];

    // List to store results
    final List<AllSalesDynamicsData> allSalesDynamicsData = [];

    // Iterate through each period
    for (final period in periods) {
      try {
        final periodData = await getSalesDynamicsForPeriod(period);
        allSalesDynamicsData.add(periodData);
      } catch (e) {
        debugPrint("Error fetching sales dynamics for period $period: $e");
        // Продолжаем загрузку других периодов даже при ошибке
      }
    }

    return allSalesDynamicsData;
  }

  /// Загрузка данных sales dynamics для конкретного периода
  Future<AllSalesDynamicsData> getSalesDynamicsForPeriod(
    SalesDynamicsTimePeriod period,
  ) async {
    // Формируем параметры в зависимости от периода
    String periodParam;
    switch (period) {
      case SalesDynamicsTimePeriod.year:
        periodParam = 'year';
        break;
      case SalesDynamicsTimePeriod.previousYear:
        periodParam = 'last_year';
        break;
    }

    var path = await _appendQueryParams(
        '/dashboard/sales-dynamics?period=$periodParam');

    debugPrint(
        "ApiService: getSalesDynamicsForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final salesResponse = SalesResponse.fromJson(SafeConverters.toMap(data));

        return AllSalesDynamicsData(
          period: period,
          data: salesResponse,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching sales dynamics for period $period: $e");
      rethrow;
    }
  }

  Future<List<AllNetProfitData>> getNetProfitData() async {
    // Define all periods to fetch
    final periods = [NetProfitPeriod.last_year, NetProfitPeriod.year];

    // List to store results
    final List<AllNetProfitData> allNetProfitData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path = await _appendQueryParams(
          '/dashboard/net-profit?period=${period.name}');
      debugPrint("ApiService: getNetProfitDashboard path: $path");

      try {
        final response = await _getRequest(path);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final netProfitDashboard = NetProfitDashboard.fromJson(SafeConverters.toMap(data));
          allNetProfitData.add(AllNetProfitData(
            period: period,
            data: netProfitDashboard,
          ));
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка для периода $period',
            response.statusCode,
          );
        }
      } catch (e) {
        debugPrint("Error fetching data for period $period: $e");
        rethrow;
      }
    }

    return allNetProfitData;
  }

  /// Загрузка данных net profit для конкретного периода
  Future<AllNetProfitData> getNetProfitDataForPeriod(
    NetProfitPeriod period,
  ) async {
    final path =
        await _appendQueryParams('/dashboard/net-profit?period=${period.name}');

    debugPrint(
        "ApiService: getNetProfitDataForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final netProfitDashboard = NetProfitDashboard.fromJson(SafeConverters.toMap(data));

        return AllNetProfitData(
          period: period,
          data: netProfitDashboard,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching net profit for period $period: $e");
      rethrow;
    }
  }

  Future<List<AllOrdersData>> getOrderDashboard() async {
    // Define all periods to fetch
    final periods = [
      OrderTimePeriod.week,
      OrderTimePeriod.month,
      OrderTimePeriod.year
    ];

    // List to store results
    final List<AllOrdersData> allOrdersData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path =
          await _appendQueryParams('/order/dashboard?period=${period.name}');
      debugPrint("ApiService: getOrderDashboard path: $path");

      try {
        // Make the API request
        final response = await _getRequest(path);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final orderDashboardResponse = OrderDashboardResponse.fromJson(SafeConverters.toMap(data));
          // Create AllOrdersData for this period
          allOrdersData.add(AllOrdersData(
            period: period,
            data: orderDashboardResponse.result,
          ));
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка для периода $period',
            response.statusCode,
          );
        }
      } catch (e) {
        // Optionally handle or log errors for individual periods
        debugPrint("Error fetching data for period $period: $e");
        // You can choose to continue with other periods or rethrow
        rethrow; // Or handle differently based on your requirements
      }
    }

    return allOrdersData;
  }

  /// Загрузка данных order dashboard для конкретного периода
  Future<AllOrdersData> getOrderDashboardForPeriod(
    OrderTimePeriod period,
  ) async {
    final path =
        await _appendQueryParams('/order/dashboard?period=${period.name}');

    debugPrint(
        "ApiService: getOrderDashboardForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orderDashboardResponse = OrderDashboardResponse.fromJson(SafeConverters.toMap(data));

        return AllOrdersData(
          period: period,
          data: orderDashboardResponse.result,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching order dashboard for period $period: $e");
      rethrow;
    }
  }

  Future<List<AllProfitabilityData>> getProfitability() async {
    // Define all periods to fetch
    final periods = [
      ProfitabilityTimePeriod.last_year,
      ProfitabilityTimePeriod.year
    ];

    // List to store results
    final List<AllProfitabilityData> allProfitabilityData = [];

    // Iterate through each period
    for (final period in periods) {
      // Form the query path for the current period
      final path = await _appendQueryParams(
          '/dashboard/profitability?period=${period.name}');
      debugPrint("ApiService: getProfitability path: $path");

      try {
        // Make the API request
        final response = await _getRequest(path);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final profitabilityResponse = ProfitabilityDashboard.fromJson(SafeConverters.toMap(data));
          // Create AllProfitabilityData for this period
          allProfitabilityData.add(AllProfitabilityData(
            period: period,
            data: profitabilityResponse,
          ));
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка для периода $period',
            response.statusCode,
          );
        }
      } catch (e) {
        // Log errors for individual periods
        debugPrint("Error fetching data for period $period: $e");
        rethrow; // Rethrow to allow caller to handle
      }
    }

    return allProfitabilityData;
  }

  /// Загрузка данных profitability для конкретного периода
  Future<AllProfitabilityData> getProfitabilityForPeriod(
    ProfitabilityTimePeriod period,
  ) async {
    final path = await _appendQueryParams(
        '/dashboard/profitability?period=${period.name}');

    debugPrint(
        "ApiService: getProfitabilityForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profitabilityResponse = ProfitabilityDashboard.fromJson(SafeConverters.toMap(data));

        return AllProfitabilityData(
          period: period,
          data: profitabilityResponse,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching profitability for period $period: $e");
      rethrow;
    }
  }

  Future<List<AllTopSellingData>> getTopSellingGoodsDashboard(
      {int perPage = 7}) async {
    // Define all periods to fetch
    final periods = [
      TopSellingTimePeriod.day,
      TopSellingTimePeriod.week,
      TopSellingTimePeriod.month,
      TopSellingTimePeriod.year,
    ];

    // List to store results
    final List<AllTopSellingData> allTopSellingData = [];

    // Iterate through each period
    for (final period in periods) {
      final query = ['per_page=$perPage', 'period=${period.name}'].join('&');

      final path =
          await _appendQueryParams('/dashboard/top-selling-goods?$query');
      debugPrint("ApiService: getTopSellingGoodsDashboard path: $path");

      try {
        final response = await _getRequest(path);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final topSellingResponse = TopSellingGoodsResponse.fromJson(SafeConverters.toMap(data));

          // Create AllTopSellingData for this period
          allTopSellingData.add(AllTopSellingData(
            period: period,
            data: topSellingResponse.result,
          ));
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка для периода $period',
            response.statusCode,
          );
        }
      } catch (e) {
        // Log errors for individual periods
        debugPrint("Error fetching data for period $period: $e");
        throw e;
      }
    }

    return allTopSellingData;
  }

  Future<List<TopSellingCardModel>> getTopSellingCardsByFilter({
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    // try{
    // Формируем параметры запроса

    debugPrint("ApiService: getTopSellingCardsByFilter filters: $filters");

    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        debugPrint("ApiService: filters['date_from']: ${filters['date_from']}");
        final dateFrom = filters['date_from'] as DateTime;
        queryParams['date_from'] = dateFrom.toIso8601String();
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
        final dateTo = filters['date_to'] as DateTime;
        queryParams['date_to'] = dateTo.toIso8601String();
      }

      if (filters.containsKey('sum_from') && filters['sum_from'] != null) {
        debugPrint("ApiService: filters['sum_from']: ${filters['sum_from']}");
        final sumFrom = filters['sum_from'] as double;
        queryParams['sum_from'] = sumFrom.toString();
      }

      if (filters.containsKey('sum_to') && filters['sum_to'] != null) {
        debugPrint("ApiService: filters['sum_to']: ${filters['sum_to']}");
        final sumTo = filters['sum_to'] as double;
        queryParams['sum_to'] = sumTo.toString();
      }

      if (filters.containsKey('good_id') && filters['good_id'] != null) {
        debugPrint("ApiService: filters['good_id']: ${filters['good_id']}");
        final goodId = filters['good_id'] as int;
        queryParams['good_id'] = goodId.toString();
      }

      if (filters.containsKey('category_id') &&
          filters['category_id'] != null) {
        debugPrint(
            "ApiService: filters['category_id']: ${filters['category_id']}");
        final categoryId = filters['category_id'] as int;
        queryParams['category_id'] = categoryId.toString();
      }
    }

    String path = await _appendQueryParams('/dashboard/top-selling-goods');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> dataList = data['result']['data'] as List<dynamic>;

        return dataList
            .map((item) => TopSellingCardModel.fromJson(item))
            .toList();
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных по топ продаваемым товарам!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<SalesResponse> getSalesDynamicsByFilter(
    Map<String, dynamic>? filters,
    String? search,
  ) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('period') && filters['period'] != null) {
        debugPrint("ApiService: filters['period']: ${filters['period']}");
        final period = filters['period'] as DateTime;
        queryParams['period'] = period.toIso8601String();
      }
      if (filters.containsKey('category_id') &&
          filters['category_id'] != null) {
        debugPrint(
            "ApiService: filters['category_id']: ${filters['category_id']}");
        final categoryId = filters['category_id'] as int;
        queryParams['category_id'] = categoryId.toString();
      }
      if (filters.containsKey('good_id') && filters['good_id'] != null) {
        debugPrint("ApiService: filters['good_id']: ${filters['good_id']}");
        final goodId = filters['good_id'] as int;
        queryParams['good_id'] = goodId.toString();
      }
    }
    // Формируем параметры запроса
    var path = await _appendQueryParams('/dashboard/sales-dynamics');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    debugPrint("ApiService: getSalesDynamics path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SalesResponse.fromJson(SafeConverters.toMap(data));
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

  Future<NetProfitResponse> getNetProfitByFilter(
    Map<String, dynamic>? filters,
    String? search,
  ) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('period') && filters['period'] != null) {
        debugPrint("ApiService: filters['period']: ${filters['period']}");
        final period = filters['period'] as DateTime;
        queryParams['period'] = period.toIso8601String();
      }
      if (filters.containsKey('category_id') &&
          filters['category_id'] != null) {
        debugPrint(
            "ApiService: filters['category_id']: ${filters['category_id']}");
        final categoryId = filters['category_id'] as int;
        queryParams['category_id'] = categoryId.toString();
      }
      if (filters.containsKey('good_id') && filters['good_id'] != null) {
        debugPrint("ApiService: filters['good_id']: ${filters['good_id']}");
        final goodId = filters['good_id'] as int;
        queryParams['good_id'] = goodId.toString();
      }
    }
    // Формируем параметры запроса
    var path = await _appendQueryParams('/dashboard/net-profit');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    debugPrint("ApiService: getNetProfit path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return NetProfitResponse.fromJson(SafeConverters.toMap(data));
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

  Future<ProfitabilityResponse> getProfitabilityByFilter(
    Map<String, dynamic>? filters,
    String? search,
  ) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('period') && filters['period'] != null) {
        debugPrint("ApiService: filters['period']: ${filters['period']}");
        final period = filters['period'] as DateTime;
        queryParams['period'] = period.toIso8601String();
      }
      if (filters.containsKey('category_id') &&
          filters['category_id'] != null) {
        debugPrint(
            "ApiService: filters['category_id']: ${filters['category_id']}");
        final categoryId = filters['category_id'] as int;
        queryParams['category_id'] = categoryId.toString();
      }
      if (filters.containsKey('good_id') && filters['good_id'] != null) {
        debugPrint("ApiService: filters['good_id']: ${filters['good_id']}");
        final goodId = filters['good_id'] as int;
        queryParams['good_id'] = goodId.toString();
      }
    }
    // Формируем параметры запроса
    var path = await _appendQueryParams('/dashboard/profitability');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    debugPrint("ApiService: getProfitability path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ProfitabilityResponse.fromJson(SafeConverters.toMap(data));
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

  Future<DashboardExpenseResponse> getExpenseStructureByFilter(
    Map<String, dynamic>? filters,
    String? search,
  ) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        debugPrint("ApiService: filters['date_from']: ${filters['date_from']}");
        final dateFrom = filters['date_from'] as DateTime;
        queryParams['date_from'] = dateFrom.toIso8601String();
      }
      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
        final dateTo = filters['date_to'] as DateTime;
        queryParams['date_to'] = dateTo.toIso8601String();
      }
      if (filters.containsKey('category_id') &&
          filters['category_id'] != null) {
        debugPrint(
            "ApiService: filters['category_id']: ${filters['category_id']}");
        final categoryId = filters['category_id'] as int;
        queryParams['category_id'] = categoryId.toString();
      }
      if (filters.containsKey('article_id') && filters['article_id'] != null) {
        debugPrint(
            "ApiService: filters['article_id']: ${filters['article_id']}");
        final articleId = filters['article_id'] as int;
        queryParams['article_id'] = articleId.toString();
      }
    }
    // Формируем параметры запроса
    var path = await _appendQueryParams('/fin/dashboard/expense-structure');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    debugPrint("ApiService: getExpenseStructure path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DashboardExpenseResponse.fromJson(SafeConverters.toMap(data));
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

  Future<List<CategoryDashboardWarehouse>>
      getCategoryDashboardWarehouse() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/category');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getCategoryDashboardWarehouse - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Полученные данные: $data'); // Для отладки, как в примере
      // Данные в "result", не прямой массив
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList
          .map((category) => CategoryDashboardWarehouse.fromJson(category))
          .toList();
    } else {
      throw Exception('Ошибка загрузки категорий');
    }
  }

  Future<List<OrderStatusWarehouse>> getOrderStatusWarehouse() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order-status');
    if (kDebugMode) {
      debugPrint('ApiService: getOrderStatusWarehouse - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Полученные данные: $data'); // Для отладки
      // Данные в "result", не прямой массив
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList
          .map((orderStatus) => OrderStatusWarehouse.fromJson(orderStatus))
          .toList();
    } else {
      throw Exception('Ошибка загрузки статусов заказов');
    }
  }

  Future<List<DashboardGoodsMovementHistory>>
      getDashboardGoodsMovementHistoryList(int goodId) async {
    final path =
        await _appendQueryParams('/dashboard/good-movement-history/$goodId');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getDashboardGoodsMovementHistoryList - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        debugPrint(
            'ApiService: Полученные данные истории движения товара $goodId: $data');
      }
      final resultList = SafeConverters.toList(
        SafeConverters.toMap(data)['result'],
      );
      return SafeConverters.toModelList(
        resultList,
        DashboardGoodsMovementHistory.fromJson,
      );
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка при получении истории перемещений товаров!',
        response.statusCode,
      );
    }
  }

  Future<dgrmodel.GoodDashboardWarehouseResponse> getGoodDashboardWarehousePage(
      int page) async {
    try {
      // Form path with page parameter
      String basePath = '/good?page=$page';

      // Add other query parameters (language, token, etc.)
      final path = await _appendQueryParams(basePath);

      if (kDebugMode) {
        debugPrint(
            'ApiService: getGoodDashboardWarehousePage - Loading page $page, path: $path');
      }

      // Execute GET request
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint('ApiService: Received data: $data');
        }

        final resultObj = SafeConverters.toMapOrNull(
          SafeConverters.toMap(data)['result'],
        );

        if (resultObj != null) {
          final goodsList = SafeConverters.toModelList(
            resultObj['data'],
            dgrmodel.GoodDashboardWarehouse.fromJson,
          );

          if (resultObj['pagination'] != null) {
            final pagination = dgrmodel.Pagination.fromJson(
              SafeConverters.toMap(resultObj['pagination']),
            );

            if (kDebugMode) {
              debugPrint(
                  'ApiService: Page $page loaded successfully with ${goodsList.length} items');
              debugPrint(
                  'ApiService: Pagination - current: ${pagination.currentPage}, total pages: ${pagination.totalPages}');
            }

            return dgrmodel.GoodDashboardWarehouseResponse(
              data: goodsList,
              pagination: pagination,
            );
          } else {
            return dgrmodel.GoodDashboardWarehouseResponse(
              data: goodsList,
              pagination: null,
            );
          }
        } else {
          // If result is empty, return empty response
          return dgrmodel.GoodDashboardWarehouseResponse(
            data: [],
            pagination: null,
          );
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

  Future<List<ExpenseArticleDashboardWarehouse>>
      getExpenseArticleDashboardWarehouse() async {
    final path = await _appendQueryParams('/article?type=expense');
    if (kDebugMode) {
      debugPrint(
          'ApiService: getExpenseArticleDashboardWarehouse - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Полученные данные статей расхода: $data');

      // Navigate to nested data: result -> data
      final resultData = data['result'];
      if (resultData == null) {
        return [];
      }

      final dataList = resultData['data'] as List?;
      if (dataList == null) {
        return [];
      }

      return dataList
          .map((article) => ExpenseArticleDashboardWarehouse.fromJson(article))
          .toList();
    } else {
      throw Exception('Ошибка загрузки статей расхода');
    }
  }
}

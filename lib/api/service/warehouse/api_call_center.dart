part of '../api_service.dart';

extension ApiWarehouseCallCenterX on ApiService {
  Future<CallById> getCallById({
    required int callId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/calls/$callId');
    if (kDebugMode) {
      //debugPrint('ApiService: getCallById - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      //debugPrint("API response for getCallById: $data");
      if (data['result'] != null && data['result'] is Map<String, dynamic>) {
        return CallById.fromJson(data['result'] as Map<String, dynamic>);
      } else {
        throw ('Invalid or missing call data in response');
      }
    } else {
      throw ('Failed to load call data');
    }
  }

  Future<Map<String, dynamic>> getCallHistoryById({
    required int callId,
    required int page,
    required int perPage,
  }) async {
    var path = '/calls/$callId/history?page=$page&per_page=$perPage';
    path = await _appendQueryParams(path);

    final response = await _getRequest(path);

    if (response.statusCode != 200) {
      throw ('Ошибка загрузки истории звонков');
    }

    final data = json.decode(response.body);
    if (data['result'] == null || data['result']['data'] == null) {
      throw ('Нет данных истории звонков в ответе');
    }

    final calls = (data['result']['data'] as List)
        .map((json) => CallLogEntry.fromJson(json))
        .toList();
    final pagination =
        (data['result']['pagination'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    return {
      'calls': calls,
      'pagination': pagination,
    };
  }

  Future<CallStatistics> getCallStatistics() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/calls/statistic/get-call-statistics');
    if (kDebugMode) {
      //debugPrint('ApiService: getCallStatistics - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['result'] != null && jsonData['result'].isNotEmpty) {
          return CallStatistics.fromJson(jsonData);
        } else {
          throw ('Нет данных статистики звонков в ответе');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера: 500');
      } else {
        throw ('Ошибка загрузки данных статистики звонков');
      }
    } catch (e) {
      debugPrint('ApiService: getCallStatistics error: $e');
      throw Exception('Ошибка получения данных статистики звонков: $e');
    }
  }

  Future<CallAnalytics> getCallAnalytics() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path =
        await _appendQueryParams('/calls/statistic/get-call-analytics');
    if (kDebugMode) {
      //debugPrint('ApiService: getCallAnalytics - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['result'] != null) {
          return CallAnalytics.fromJson(jsonData);
        } else {
          throw ('Нет данных статистики звонков в ответе');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера: 500');
      } else {
        throw ('Ошибка загрузки данных статистики звонков');
      }
    } catch (e) {
      debugPrint('ApiService: getCallAnalytics error: $e');
      throw Exception('Ошибка получения данных статистики звонков: $e');
    }
  }

  Future<MonthlyCallStats> getMonthlyCallStats(int operatorId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(
        '/calls/statistic/monthly-stats?operator_id=$operatorId');
    if (kDebugMode) {
      //debugPrint('ApiService: getMonthlyCallStats - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['result'] != null && jsonData['result'].isNotEmpty) {
          return MonthlyCallStats.fromJson(jsonData);
        } else {
          throw ('Нет данных месячной статистики звонков в ответе');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера: 500');
      } else {
        throw ('Ошибка загрузки данных месячной статистики звонков');
      }
    } catch (e) {
      throw ('Ошибка получения данных месячной статистики звонков');
    }
  }

  Future<CallSummaryStats> getCallSummaryStats(int operatorId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams(
        '/calls/statistic/summary?operator_id=$operatorId');
    if (kDebugMode) {
      //debugPrint('ApiService: getCallSummaryStats - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['result'] != null) {
          return CallSummaryStats.fromJson(jsonData);
        } else {
          throw ('Нет данных сводной статистики звонков в ответе');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера: 500');
      } else {
        throw ('Ошибка загрузки данных сводной статистики звонков: ${response.statusCode}');
      }
    } catch (e) {
      throw ('Ошибка получения данных сводной статистики звонков');
    }
  }

  Future<OperatorList> getOperators() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/operators');
    if (kDebugMode) {
      //debugPrint('ApiService: getOperators - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['result'] != null) {
          return OperatorList.fromJson(jsonData);
        } else {
          throw ('Нет данных операторов в ответе');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера: 500');
      } else {
        throw ('Ошибка загрузки данных операторов');
      }
    } catch (e) {
      debugPrint('ApiService: getOperators error: $e');
      throw Exception('Ошибка получения данных операторов: $e');
    }
  }
}

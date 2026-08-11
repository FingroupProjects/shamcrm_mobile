import 'package:crm_task_manager/utils/safe_converters.dart';

class DealStatsResponse {
  final List<MonthData> data;

  DealStatsResponse({
    required this.data,
  }) {
    // print('DealStatsResponse: Создан новый объект');
    // print('DealStatsResponse: количество месяцев = ${data.length}');
  }

  factory DealStatsResponse.fromJson(Map<String, dynamic> json) {
    // print('DealStatsResponse: Начало парсинга JSON');
    // print('DealStatsResponse: Входящий JSON = $json');
    
    if (json['result'] == null || json['result']['data'] == null) {
      throw Exception('Отсутствует ключ "result" или "data" в JSON');
    }

    final rawData = SafeConverters.toList(json['result']['data']);
    final monthlyData =
        rawData.map((item) => MonthData.fromJson(SafeConverters.toMap(item))).toList();

    final response = DealStatsResponse(
      data: monthlyData,
    );
    
    // print('DealStatsResponse: Успешно создан объект из JSON');
    return response;
  }
}

class MonthData {
  final double totalSum;
  final double successfulSum;

  MonthData({
    required this.totalSum,
    required this.successfulSum,
  });

  factory MonthData.fromJson(Map<String, dynamic> json) {
    return MonthData(
      totalSum: SafeConverters.toDouble(json['total_sum']),
      successfulSum: SafeConverters.toDouble(json['successful_sum']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sum': totalSum,
      'successful_sum': successfulSum,
    };
  }
}

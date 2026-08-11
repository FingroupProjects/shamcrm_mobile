import 'package:crm_task_manager/utils/safe_converters.dart';

class DealStatsResponseManager {
  final List<MonthData> data;

  DealStatsResponseManager({
    required this.data,
  }) {
  }

  factory DealStatsResponseManager.fromJson(Map<String, dynamic> json) {
    
    if (json['result'] == null || json['result']['data'] == null) {
      throw Exception('Отсутствует ключ "result" или "data" в JSON');
    }

    final rawData = SafeConverters.toList(json['result']['data']);
    final monthlyData =
        rawData.map((item) => MonthData.fromJson(SafeConverters.toMap(item))).toList();

    final response = DealStatsResponseManager(
      data: monthlyData,
    );
    
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

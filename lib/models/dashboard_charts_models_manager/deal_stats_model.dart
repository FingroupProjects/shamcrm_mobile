class DealStatsResponseManager {
  final List<MonthData> data;

  DealStatsResponseManager({
    required this.data,
  }) {
    print('DealStatsResponseManager: Создан новый объект');
    print('DealStatsResponseManager: количество месяцев = ${data.length}');
  }

  factory DealStatsResponseManager.fromJson(Map<String, dynamic> json) {
    print('DealStatsResponseManager: Начало парсинга JSON');
    print('DealStatsResponseManager: Входящий JSON = $json');
    
    if (json['result'] == null || json['result']['data'] == null) {
      throw Exception('Отсутствует ключ "result" или "data" в JSON');
    }

    List<dynamic> rawData = json['result']['data'] as List<dynamic>;
    List<MonthData> monthlyData = rawData.map((item) => MonthData.fromJson(item)).toList();

    final response = DealStatsResponseManager(
      data: monthlyData,
    );
    
    print('DealStatsResponseManager: Успешно создан объект из JSON');
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
      totalSum: (json['total_sum'] as num).toDouble(),
      successfulSum: (json['successful_sum'] as num).toDouble(),
    );
  }
}
class DealStatsResponse {
  final List<MonthData> data;

  DealStatsResponse({
    required this.data,
  }) {
    print('DealStatsResponse: Создан новый объект');
    print('DealStatsResponse: количество месяцев = ${data.length}');
  }

  factory DealStatsResponse.fromJson(Map<String, dynamic> json) {
    print('DealStatsResponse: Начало парсинга JSON');
    print('DealStatsResponse: Входящий JSON = $json');
    
    if (json['result'] == null || json['result']['data'] == null) {
      throw Exception('Отсутствует ключ "result" или "data" в JSON');
    }

    List<dynamic> rawData = json['result']['data'] as List<dynamic>;
    List<MonthData> monthlyData = rawData.map((item) => MonthData.fromJson(item)).toList();

    final response = DealStatsResponse(
      data: monthlyData,
    );
    
    print('DealStatsResponse: Успешно создан объект из JSON');
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
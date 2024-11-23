// deal_stats_model.dart
class DealStatsResponse {
  final List<MonthlyStats> monthlyStats;

  DealStatsResponse({
    required this.monthlyStats,
  }) {
    print('DealStatsResponse: Создан новый объект');
    print('DealStatsResponse: количество месяцев = ${monthlyStats.length}');
  }

  factory DealStatsResponse.fromJson(Map<String, dynamic> json) {
    print('DealStatsResponse: Начало парсинга JSON');
    print('DealStatsResponse: Входящий JSON = $json');

    if (json['result'] == null) {
      throw Exception('Отсутствует ключ "result" в JSON');
    }

    List<dynamic> resultList = json['result'] as List;
    List<MonthlyStats> stats = resultList.map((monthData) => 
      MonthlyStats.fromJson(monthData as Map<String, dynamic>)
    ).toList();

    final response = DealStatsResponse(
      monthlyStats: stats,
    );

    print('DealStatsResponse: Успешно создан объект из JSON');
    return response;
  }
}

class MonthlyStats {
  final String month;
  final int count;

  MonthlyStats({
    required this.month,
    required this.count,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      month: json['month'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
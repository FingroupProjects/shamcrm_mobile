class DealStatsResponse {
  final List<int> monthlyStats;

  DealStatsResponse({
    required this.monthlyStats,
  }) {
    print('DealStatsResponse: Создан новый объект');
    print('DealStatsResponse: количество месяцев = ${monthlyStats.length}');
  }

  factory DealStatsResponse.fromJson(Map<String, dynamic> json) {
  print('DealStatsResponse: Начало парсинга JSON');
  print('DealStatsResponse: Входящий JSON = $json');

  if (json['result'] == null || json['result']['data'] == null) {
    throw Exception('Отсутствует ключ "result" или "data" в JSON');
  }

  // Преобразование значений в int
  List<int> stats = (json['result']['data'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList();

  final response = DealStatsResponse(
    monthlyStats: stats,
  );

  print('DealStatsResponse: Успешно создан объект из JSON');
  return response;
}
}
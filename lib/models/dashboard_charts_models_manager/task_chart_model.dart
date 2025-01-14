class TaskChartManager {
  final List<double> data;

  TaskChartManager({
    required this.data,
  });

  factory TaskChartManager.fromJson(Map<String, dynamic> json) {
    // Извлекаем данные из ключа "result" -> "data"
    final data = (json['result']['data'] as List<dynamic>)
        .map((x) => (x as num).toDouble())
        .toList();

    return TaskChartManager(data: data);
  }
}
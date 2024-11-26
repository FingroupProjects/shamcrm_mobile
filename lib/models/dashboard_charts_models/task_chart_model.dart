class TaskChart {
  final List<double> data;

  TaskChart({
    required this.data,
  });

  factory TaskChart.fromJson(Map<String, dynamic> json) {
    // Извлекаем данные из ключа "result" -> "data"
    final data = (json['result']['data'] as List<dynamic>)
        .map((x) => (x as num).toDouble())
        .toList();

    return TaskChart(data: data);
  }
}
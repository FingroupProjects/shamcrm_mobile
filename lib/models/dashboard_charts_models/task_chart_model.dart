// task_chart_model.dart
class TaskChart {
  final List<double> data;
  final String color;

  TaskChart({
    required this.data,
    required this.color,
  });

  factory TaskChart.fromJson(List<dynamic> jsonList) {
    // Берем первый элемент списка, так как структура всегда [{"data": [...], "color": "..."}]
    final json = jsonList.first as Map<String, dynamic>;
    final data = (json['data'] as List<dynamic>).map((x) => (x as num).toDouble()).toList();
    
    return TaskChart(
      data: data,
      color: json['color'] as String,
    );
  }
}

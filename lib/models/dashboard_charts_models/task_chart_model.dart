import 'package:crm_task_manager/utils/safe_converters.dart';

class TaskChart {
  final List<double> data;

  TaskChart({
    required this.data,
  });

  factory TaskChart.fromJson(Map<String, dynamic> json) {
    // Извлекаем данные из ключа "result" -> "data"
    final data = SafeConverters.toList(json['result']['data'])
        .map(SafeConverters.toDouble)
        .toList();

    return TaskChart(data: data);
  }
}

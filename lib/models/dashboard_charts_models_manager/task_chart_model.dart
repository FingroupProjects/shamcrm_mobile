import 'package:crm_task_manager/utils/safe_converters.dart';

class TaskChartManager {
  final List<double> data;

  TaskChartManager({
    required this.data,
  });

  factory TaskChartManager.fromJson(Map<String, dynamic> json) {
    // Извлекаем данные из ключа "result" -> "data"
    final data = SafeConverters.toList(json['result']['data'])
        .map(SafeConverters.toDouble)
        .toList();

    return TaskChartManager(data: data);
  }
}

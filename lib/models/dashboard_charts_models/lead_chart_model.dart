import 'package:crm_task_manager/utils/safe_converters.dart';

class ChartData {
  final String label;
  final List<double> data;
  final String color;

  ChartData({
    required this.label,
    required this.data,
    required this.color,
  });

  // Преобразование объекта ChartData в JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'data': data,
      'color': color,
    };
  }

  // Создание объекта ChartData из JSON
  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: SafeConverters.toSafeString(json['label'] ?? json['status']),
      data: SafeConverters.toList(json['data']).map(SafeConverters.toDouble).toList(),
      color: SafeConverters.toSafeString(json['color'], defaultValue: '#000000'),
    );
  }
}

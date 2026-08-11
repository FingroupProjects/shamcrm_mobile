import 'package:crm_task_manager/utils/safe_converters.dart';

class ChartDataManager {
  final String label;
  final List<double> data;
  final String color;

  ChartDataManager({
    required this.label,
    required this.data,
    required this.color,
  });

  factory ChartDataManager.fromJson(Map<String, dynamic> json) {
    return ChartDataManager(
      label: SafeConverters.toSafeString(json['label'] ?? json['status']),
      data: SafeConverters.toList(json['data']).map(SafeConverters.toDouble).toList(),
      color: SafeConverters.toSafeString(json['color'], defaultValue: '#000000'),
    );
  }

  // toJson method to convert ChartDataManager instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'data': data.map((x) => x).toList(), // List<double> to JSON-compatible list
      'color': color,
    };
  }
}

import 'package:crm_task_manager/utils/safe_converters.dart';

// models/project_chart_model.dart
class ProjectChart {
  final int id;
  final String name;
  final List<int> data;

  ProjectChart({
    required this.id,
    required this.name,
    required this.data,
  });

  factory ProjectChart.fromJson(Map<String, dynamic> json) {
    return ProjectChart(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      data: SafeConverters.toIntList(json['data']),
    );
  }
}

class ProjectChartResponse {
  final List<ProjectChart> result;
  final dynamic errors;

  ProjectChartResponse({
    required this.result,
    this.errors,
  });

  factory ProjectChartResponse.fromJson(Map<String, dynamic> json) {
    return ProjectChartResponse(
      result: SafeConverters.toList(json['result'])
          .whereType<Map<String, dynamic>>()
          .map((item) => ProjectChart.fromJson(item))
          .toList(),
      errors: json['errors'],
    );
  }
}

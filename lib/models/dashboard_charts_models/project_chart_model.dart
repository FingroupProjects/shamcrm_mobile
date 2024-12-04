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
      id: json['id'] as int,
      name: json['name'] as String,
      data: List<int>.from(json['data'] as List),
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
      result: (json['result'] as List)
          .map((item) => ProjectChart.fromJson(item))
          .toList(),
      errors: json['errors'],
    );
  }
}

import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Model for completed tasks chart from /api/v2/dashboard/completed-task-chart
/// Response: {"result": [0, 0, ...]} (12 months)
class CompletedTasksChartResponse {
  final List<int> monthlyCompleted;

  CompletedTasksChartResponse({required this.monthlyCompleted});

  factory CompletedTasksChartResponse.fromJson(Map<String, dynamic> json) {
    final data = json['result'];
    return CompletedTasksChartResponse(
      monthlyCompleted: SafeConverters.toIntList(data, expectedLength: 12),
    );
  }
}

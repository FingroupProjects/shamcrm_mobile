import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Model for task chart data from /api/dashboard/task-chart
/// Response: {result: {data: [completed, in_progress, overdue]}}
class TaskChartModel {
  final int completed;
  final int inProgress;
  final int overdue;

  TaskChartModel({
    required this.completed,
    required this.inProgress,
    required this.overdue,
  });

  factory TaskChartModel.fromJson(Map<String, dynamic> json) {
    final data = json['result']?['data'];

    if (data is List && data.length >= 3) {
      return TaskChartModel(
        completed: SafeConverters.toInt(data[0]),
        inProgress: SafeConverters.toInt(data[1]),
        overdue: SafeConverters.toInt(data[2]),
      );
    }

    // Return empty data if parsing fails
    return TaskChartModel(
      completed: 0,
      inProgress: 0,
      overdue: 0,
    );
  }

  int get total => completed + inProgress + overdue;

  double get completionRate {
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'inProgress': inProgress,
      'overdue': overdue,
    };
  }
}

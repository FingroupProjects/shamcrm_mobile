import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Model for /api/v2/dashboard/task-chart
class TaskChartV2Response {
  final List<int> data;
  final int overallKpi;
  final int completedTasks;
  final int totalTasks;

  TaskChartV2Response({
    required this.data,
    required this.overallKpi,
    required this.completedTasks,
    required this.totalTasks,
  });

  factory TaskChartV2Response.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final dataRaw = result['data'];
      final data = dataRaw is List
          ? SafeConverters.toIntList(dataRaw, expectedLength: 3)
          : <int>[0, 0, 0];

      return TaskChartV2Response(
        data: data,
        overallKpi: SafeConverters.toInt(result['overall_kpi']),
        completedTasks: SafeConverters.toInt(result['completed_tasks']),
        totalTasks: SafeConverters.toInt(result['total_tasks']),
      );
    }

    return TaskChartV2Response(
      data: [0, 0, 0],
      overallKpi: 0,
      completedTasks: 0,
      totalTasks: 0,
    );
  }

  int get overdue => data.isNotEmpty ? data[0] : 0;
  int get inProgress => data.length > 1 ? data[1] : 0;
  int get completed => data.length > 2 ? data[2] : 0;

  int get total => totalTasks > 0 ? totalTasks : overdue + inProgress + completed;

  double get completionRate {
    if (overallKpi > 0) return overallKpi.toDouble();
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }
}

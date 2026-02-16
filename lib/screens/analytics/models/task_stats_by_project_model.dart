import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class ProjectTaskStatus {
  final String statusName;
  final String color;
  final int count;

  ProjectTaskStatus({
    required this.statusName,
    required this.color,
    required this.count,
  });

  factory ProjectTaskStatus.fromJson(Map<String, dynamic> json) {
    return ProjectTaskStatus(
      statusName: SafeConverters.toSafeString(json['status_name']),
      color: SafeConverters.toSafeString(json['color'], defaultValue: '#000000'),
      count: SafeConverters.toInt(json['count']),
    );
  }
}

class ProjectTaskStats {
  final String projectName;
  final int projectId;
  final int totalTasks;
  final List<ProjectTaskStatus> statuses;

  ProjectTaskStats({
    required this.projectName,
    required this.projectId,
    required this.totalTasks,
    required this.statuses,
  });

  factory ProjectTaskStats.fromJson(Map<String, dynamic> json) {
    final statusesData = json['statuses'];
    return ProjectTaskStats(
      projectName: SafeConverters.toSafeString(json['project_name']),
      projectId: SafeConverters.toInt(json['project_id']),
      totalTasks: SafeConverters.toInt(json['total_tasks']),
      statuses: statusesData is List
          ? statusesData.map((e) => ProjectTaskStatus.fromJson(e)).toList()
          : <ProjectTaskStatus>[],
    );
  }
}

class TaskStatsByProjectResponse {
  final List<ProjectTaskStats> projects;

  TaskStatsByProjectResponse({required this.projects});

  factory TaskStatsByProjectResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is List) {
      return TaskStatsByProjectResponse(
        projects: result.map((e) => ProjectTaskStats.fromJson(e)).toList(),
      );
    }

    return TaskStatsByProjectResponse(projects: []);
  }
}

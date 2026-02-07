import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Model for user goals data from /api/dashboard/users-chart
class UserGoalModel {
  final String name;
  final int userId;
  final double finishedTasksPercent;
  final int completedTasks;
  final int totalTasks;

  UserGoalModel({
    required this.name,
    required this.userId,
    required this.finishedTasksPercent,
    required this.completedTasks,
    required this.totalTasks,
  });

  // Convenience getters for chart usage
  String get userName => name;
  int get completionPercentage => finishedTasksPercent.round();

  factory UserGoalModel.fromJson(Map<String, dynamic> json) {
    return UserGoalModel(
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Unknown'),
      userId: SafeConverters.toInt(json['user_id']),
      finishedTasksPercent:
          SafeConverters.toDouble(json['finishedTasksprocent']),
      completedTasks: SafeConverters.toInt(json['completedTasks']),
      totalTasks: SafeConverters.toInt(json['totalTasks']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'user_id': userId,
      'finishedTasksprocent': finishedTasksPercent,
      'completedTasks': completedTasks,
      'totalTasks': totalTasks,
    };
  }
}

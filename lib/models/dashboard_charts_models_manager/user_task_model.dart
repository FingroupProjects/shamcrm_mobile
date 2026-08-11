import 'package:crm_task_manager/utils/safe_converters.dart';

// Model
class UserTaskCompletionManager {
  final List<double> finishedTasksPercent;

  UserTaskCompletionManager({
    required this.finishedTasksPercent,
  });

  factory UserTaskCompletionManager.fromJson(Map<String, dynamic> json) {
    return UserTaskCompletionManager(
      finishedTasksPercent: SafeConverters.toList(json['result'])
          .map(SafeConverters.toDouble)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'result': finishedTasksPercent,
      };
}

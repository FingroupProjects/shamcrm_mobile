import 'package:crm_task_manager/utils/safe_converters.dart';

class UserTaskCompletion {
  final int id;
  final String name;
  final double finishedTasksprocent;

  UserTaskCompletion({
    required this.id,
    required this.name,
    required this.finishedTasksprocent,
  });

  factory UserTaskCompletion.fromJson(Map<String, dynamic> json) {
    return UserTaskCompletion(
      id: SafeConverters.toInt(json['user_id']),
      name: SafeConverters.toSafeString(json['name']),
      finishedTasksprocent: SafeConverters.toDouble(json['finishedTasksprocent']),
    );
  }

  // Можно добавить метод toJson если потребуется
  Map<String, dynamic> toJson() => {
    'user_id': id,
    'name': name,
    'finishedTasksprocent': finishedTasksprocent,
  };
}

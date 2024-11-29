import 'package:crm_task_manager/models/task_model.dart';

class TaskProfile {
  final int id;
  final String name;
  final int taskNumber;
  final TaskStatus taskStatus;
  final String from;
  final String to;
  

  TaskProfile({
    required this.id,
    required this.name,
    required this.taskNumber,
    required this.taskStatus,
    required this.from,
    required this.to, 
  });

  factory TaskProfile.fromJson(Map<String, dynamic> json) {
    return TaskProfile(
      id: json['id'],
      name: json['name'],
      taskNumber: json['task_number'],
      taskStatus: TaskStatus.fromJson(json['taskStatus']),
      from: json['from'],
      to: json['to'],

    );
  }
}


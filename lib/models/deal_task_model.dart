import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/task_model.dart';

class DealTask {
  final int id;
  final int taskNumber;
  final String name;
  final String? description;
  final String from;
  final String to;
  final Project? project; 
  final TaskStatus? taskStatus;


  DealTask({
    required this.id,
    required this.taskNumber,
    required this.name,
    this.description,
    required this.from,
    required this.to,
    this.project, 
    this.taskStatus, 
  });

  factory DealTask.fromJson(Map<String, dynamic> json) {
    return DealTask(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      taskNumber: json['task_number'] is int
          ? json['task_number']
          : int.tryParse(json['task_number'].toString()) ?? 0, 
      name: json['name'] ?? 'Без имени',
      description: json['description'],
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      project: json['project'] != null ? Project.fromJson(json['project']) : null, 
      taskStatus: json['taskStatus'] != null && json['taskStatus'] is Map<String, dynamic>
      ? TaskStatus.fromJson(json['taskStatus'])
      : null,
    );
  }
}
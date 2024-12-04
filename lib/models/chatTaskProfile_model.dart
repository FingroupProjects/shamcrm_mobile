import 'package:crm_task_manager/models/task_model.dart';

class TaskProfile {
  final int id;
  final String name;
  final int taskNumber;
  final TaskStatus taskStatus;
  final String from;
  final String to;
  final String authorName; // Поле для имени автора
  final String usersNames; // Поле для имен пользователей
  final String? priority_level;

  TaskProfile({
    required this.id,
    required this.name,
    required this.taskNumber,
    required this.taskStatus,
    required this.from,
    required this.to,
    required this.authorName,
    required this.usersNames,
    this.priority_level,
  });

  factory TaskProfile.fromJson(Map<String, dynamic> json) {
    // Обработка имени автора
    final String authorName = json['author']?['name'] ?? 'Неизвестно';

    // Обработка списка пользователей
    final List<dynamic> users = json['users'] ?? [];
    final String usersNames = users
        .map((user) => user['name'] ?? 'Неизвестно')
        .join(', '); // Объединяем имена через запятую

    return TaskProfile(
      id: json['id'],
      name: json['name'],
      taskNumber: json['task_number'],
      taskStatus: TaskStatus.fromJson(json['taskStatus']),
      from: json['from'],
      to: json['to'],
      priority_level: json['priority_level'],
      authorName: authorName,
      usersNames: usersNames,
    );
  }
}

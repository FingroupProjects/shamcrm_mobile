import 'package:crm_task_manager/models/task/task_model.dart';

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
  // Имя проекта из объекта project в ответе /task/getByChat.
  final String? projectName;

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
    this.projectName,
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
      projectName: _readProjectName(json),
    );
  }
}

/// Сервер отдаёт проект объектом {id, name} или строкой.
/// Если поля нет, карточка покажет «Не указан».
String? _readProjectName(Map<String, dynamic> json) {
  final project = json['project'] ?? json['project_name'];
  if (project == null) return null;

  if (project is String) {
    final name = project.trim();
    return name.isEmpty ? null : name;
  }

  if (project is Map) {
    final name = project['name']?.toString().trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  return null;
}

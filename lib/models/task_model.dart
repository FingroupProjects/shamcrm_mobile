
class Task {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int statusId;

  Task({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.description,
    required this.statusId,
  });

  factory Task.fromJson(Map<String, dynamic> json, int taskStatusId) {
    return Task(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      startDate: json['start_date'] is String ? json['start_date'] : null,
      endDate: json['end_date'] is String ? json['end_date'] : null,
      description: json['description'] is String ? json['description'] : '',
      statusId: taskStatusId,
      
      
    );
  }

  String? get priority => null;
}


class TaskStatus {
  final int id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskStatus({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    return TaskStatus(
      id: json['id'],
      name: json['name'] is String ? json['name'] : 'Без имени',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}

class Project {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  Project({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }
}




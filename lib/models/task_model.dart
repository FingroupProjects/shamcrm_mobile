
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
  // final String needs_permission;
  final String? createdAt;
  final String? updatedAt;

  TaskStatus( {
    required this.id,
    required this.name,
    // required this.needs_permission,
    this.createdAt,
    this.updatedAt,
    
  });

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    return TaskStatus(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      // needs_permission: json['needs_permission'] is String ? json['needs_permission'] : null,
    
    );
  }
}

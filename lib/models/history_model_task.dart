class TaskHistory {
  final int id;
  final User user;
  final String status;
  final DateTime date;
  final Changes? changes;

  TaskHistory({
    required this.id,
    required this.user,
    required this.status,
    required this.date,
    this.changes,
  });

  factory TaskHistory.fromJson(Map<String, dynamic> json) {
  try {
    final userJson = json['user'];
    final user = userJson != null ? User.fromJson(userJson) : User(id: 0, name: 'Система', email: '', phone: '');

    return TaskHistory(
      id: json['id'] ?? 0,
      user: user,
      status: json['status'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      changes: _parseChanges(json['changes']),
    );
  } catch (e) {
    print('Ошибка при парсинге TaskHistory!');
    return TaskHistory(
      id: 0,
      user: User(id: 0, name: 'Система', email: 'Не указано', phone: 'Не указано'),
      status: 'Создан',
      date: DateTime.now(),
      changes: null,
    );
  }
}


 static Changes? _parseChanges(dynamic changesJson) {
  if (changesJson is List && changesJson.isNotEmpty) {
    final body = changesJson[0]['body'];
    if (body != null && body is Map<String, dynamic>) {
      return Changes.fromJson(body);
    }
  }
  return null;
}
}

class User {
  final int id;
  final String name;
  final String email;
  final String phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Система', 
      email: json['email'] ?? 'Не указано', 
      phone: json['phone'] ?? 'Не указано', 
    );
  }
}

class Changes {
  final String? taskStatusNewValue;
  final String? taskStatusPreviousValue;
  final String? historyNameNewValue;
  final String? historyNamePreviousValue;
  final String? isFinishedNewValue;  
  final String? isFinishedPreviousValue;  
  final String? startDateNewValue; 
  final String? startDatePreviousValue;  
  final String? endDateNewValue; 
  final String? endDatePreviousValue;  
  final String? projectNewValue; 
  final String? projectPreviousValue;  
  final String? usersNewValue; 
  final String? usersPreviousValue;  
  final String? descriptionNewValue; 
  final String? descriptionPreviousValue;  

  Changes({
    this.taskStatusNewValue,
    this.taskStatusPreviousValue,
    this.historyNameNewValue,
    this.historyNamePreviousValue,
    this.isFinishedNewValue,
    this.isFinishedPreviousValue,
    this.startDateNewValue,
    this.startDatePreviousValue,
    this.endDateNewValue,
    this.endDatePreviousValue,
    this.projectNewValue,
    this.projectPreviousValue,
    this.usersNewValue,
    this.usersPreviousValue,
    this.descriptionNewValue,
    this.descriptionPreviousValue,
  });

  factory Changes.fromJson(Map<String, dynamic> json) {
    return Changes(
      taskStatusNewValue: json['task_status']?['new_value']?.toString(),
      taskStatusPreviousValue: json['task_status']?['previous_value']?.toString(),
      isFinishedNewValue: json['is_finished']?['new_value']?.toString(),
      isFinishedPreviousValue: json['is_finished']?['previous_value']?.toString(),
      historyNameNewValue: json['name']?['new_value']?.toString(),
      historyNamePreviousValue: json['name']?['previous_value']?.toString(),
      startDateNewValue:json['from']?['new_value']?.toString(),
      startDatePreviousValue: json['from']?['previous_value']?.toString(),
      endDateNewValue: json['to']?['new_value']?.toString(),
      endDatePreviousValue: json['to']?['previous_value']?.toString(),
      projectNewValue: json['project']?['new_value']?.toString(),
      projectPreviousValue: json['project']?['previous_value']?.toString(),
      usersNewValue: json['users']?['new_value']?.toString(),
      usersPreviousValue: json['users']?['previous_value']?.toString(),
      descriptionNewValue: json['description']?['new_value']?.toString(),
      descriptionPreviousValue: json['description']?['previous_value']?.toString(),
    );
  }

// static DateTime? _parseDateTime(dynamic value) {
//     if (value == null) return null;
//     if (value is String) {
//       try {
//         return DateTime.parse(value);
//       } catch (_) {
//         return null; 
//       }
//     }
//     return null;
//   }
}


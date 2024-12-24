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
      // Проверка на наличие необходимых полей
      final userJson = json['user'];
      if (userJson == null) {
        throw FormatException('User data is null');
      }

      return TaskHistory(
        id: json['id'] ?? 0,
        user: User.fromJson(userJson),
        status: json['status'] ?? '', 
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
        changes: _parseChanges(json['changes']),
      );
    } catch (e) {
      print('Ошибка при парсинге TaskHistory: $e');
      return TaskHistory(
        id: 0,
        user: User(
            id: 0,
            name: 'Система',
            email: 'Не указано',
            image: 'Не указано',
            phone: 'Не указано'),
        status: 'Создан',
        date: DateTime.now(),
        changes: null,
      );
    }
  }

  static Changes? _parseChanges(dynamic changesJson) {
    if (changesJson is List && changesJson.isNotEmpty) {
      final body = changesJson[0]['body'];
      if (body is Map<String, dynamic>) {
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
  final String image; 

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указано', 
      email: json['email'] ?? 'Не указано', 
      phone: json['phone'] ?? 'Не указано', 
      image: json['image'] ?? 'Не указано', 
    );
  }
}


class Changes {
  final String? taskStatusNewValue;
  final String? taskStatusPreviousValue;
  final int? positionNewValue;
  final int? positionPreviousValue;

  Changes({
    this.taskStatusNewValue,
    this.taskStatusPreviousValue,
    this.positionNewValue,
    this.positionPreviousValue,
  });

  factory Changes.fromJson(Map<String, dynamic> json) {
    return Changes(
      taskStatusNewValue: json['task_status']?['new_value']?.toString(),
      taskStatusPreviousValue: json['task_status']?['previous_value']?.toString(),
      positionNewValue: json['position']?['new_value'],
      positionPreviousValue: json['position']?['previous_value'],
    );
  }
}

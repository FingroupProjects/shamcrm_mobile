class LeadHistory {
  final int id;
  final User user;
  final String status;
  final DateTime date;
  final Changes? changes;

  LeadHistory({
    required this.id,
    required this.user,
    required this.status,
    required this.date,
    this.changes,
  });

  factory LeadHistory.fromJson(Map<String, dynamic> json) {
    try {
      return LeadHistory(
        id: json['id'],
        user: User.fromJson(json['user']),
        status: json['status'],
        date: DateTime.parse(json['date']),
        changes: _parseChanges(json['changes']),
      );
    } catch (e) {
      print('Ошибка при парсинге LeadHistory: $e');
      return LeadHistory(
        id: 0,
        user: User(id: 0, name: '', email: '', phone: ''),
        status: '',
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

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class Changes {
  final String? leadStatusNewValue;
  final String? leadStatusPreviousValue;
  final int? positionNewValue;
  final int? positionPreviousValue;

  Changes({
    this.leadStatusNewValue,
    this.leadStatusPreviousValue,
    this.positionNewValue,
    this.positionPreviousValue,
  });

  factory Changes.fromJson(Map<String, dynamic> json) {
    return Changes(
      leadStatusNewValue: json['lead_status']?['new_value'],
      leadStatusPreviousValue: json['lead_status']?['previous_value'],
      positionNewValue: json['position']?['new_value'],
      positionPreviousValue: json['position']?['previous_value'],
    );
  }
}

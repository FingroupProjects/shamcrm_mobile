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
    final userJson = json['user'];
    final user = userJson != null ? User.fromJson(userJson) : User(id: 0, name: 'Система', email: '', phone: '');

    return LeadHistory(
      id: json['id'] ?? 0,
      user: user,
      status: json['status'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      changes: _parseChanges(json['changes']),
    );
  } catch (e) {
    print('Ошибка при парсинге LeadHistory: $e');
    return LeadHistory(
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
  final String? leadStatusNewValue;
  final String? leadStatusPreviousValue;
  final String? historyNameNewValue;
  final String? historyNamePreviousValue;
  final String? phoneNewValue;
  final String? phonePreviousValue;
  final String? emailNewValue;
  final String? emailPreviousValue;
  final int? regionNewValue;
  final int? regionPreviousValue;
  final String? managerNewValue; 
  final String? managerPreviousValue;
  final String? tgNickNewValue;  
  final String? tgNickPreviousValue;
  final String? birthdayNewValue; 
  final String? birthdayPreviousValue;
  final String? descriptionNewValue; 
  final String? descriptionPreviousValue;
  final String? instaLoginNewValue;  
  final String? instaLoginPreviousValue;
  final String? facebookLoginNewValue; 
  final String? facebookLoginPreviousValue;

  Changes({
    this.leadStatusNewValue,
    this.leadStatusPreviousValue,
    this.historyNameNewValue,
    this.historyNamePreviousValue,
    this.phoneNewValue,
    this.phonePreviousValue,
    this.emailNewValue,
    this.emailPreviousValue,
    this.regionNewValue,
    this.regionPreviousValue,
    this.managerNewValue,
    this.managerPreviousValue,
    this.tgNickNewValue,
    this.tgNickPreviousValue,
    this.birthdayNewValue,
    this.birthdayPreviousValue,
    this.descriptionNewValue,
    this.descriptionPreviousValue,
    this.instaLoginNewValue,
    this.instaLoginPreviousValue,
    this.facebookLoginNewValue,
    this.facebookLoginPreviousValue,
  });

  factory Changes.fromJson(Map<String, dynamic> json) {
  return Changes(
    leadStatusNewValue: json['lead_status']?['new_value'] as String?,
    leadStatusPreviousValue: json['lead_status']?['previous_value'] as String?,
    historyNameNewValue: json['name']?['new_value'] as String?,
    historyNamePreviousValue: json['name']?['previous_value'] as String?,
    phoneNewValue: json['phone']?['new_value'] as String?,
    phonePreviousValue: json['phone']?['previous_value'] as String?,
    emailNewValue: json['email']?['new_value'] as String?,
    emailPreviousValue: json['email']?['previous_value'] as String?,
    regionNewValue: json['region']?['new_value'] as int?,
    regionPreviousValue: json['region']?['previous_value'] as int?,
    managerNewValue: json['manager']?['new_value'] as String?,
    managerPreviousValue: json['manager']?['previous_value'] as String?,
    tgNickNewValue: json['tg_nick']?['new_value'] as String?,
    tgNickPreviousValue: json['tg_nick']?['previous_value'] as String?,
    birthdayNewValue: json['birthday']?['new_value'] as String?,
    birthdayPreviousValue: json['birthday']?['previous_value'] as String?,
    descriptionNewValue: json['description']?['new_value'] as String?,
    descriptionPreviousValue: json['description']?['previous_value'] as String?,
    instaLoginNewValue: json['insta_login']?['new_value'] as String?,
    instaLoginPreviousValue: json['insta_login']?['previous_value'] as String?,
    facebookLoginNewValue: json['facebook_login']?['new_value'] as String?,
    facebookLoginPreviousValue: json['facebook_login']?['previous_value'] as String?,
  );
}

}

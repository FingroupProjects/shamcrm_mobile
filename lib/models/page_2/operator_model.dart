class OperatorList {
  final List<Operator> result;
  final String? errors;

  OperatorList({
    required this.result,
    this.errors,
  });

  factory OperatorList.fromJson(Map<String, dynamic> json) {
    final resultList = (json['result'] as List?) ?? const [];
    final operators = resultList
        .whereType<Map<String, dynamic>>()
        .map(Operator.fromJson)
        .toList();

    return OperatorList(
      result: operators,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result.map((operator) => operator.toJson()).toList(),
      'errors': errors,
    };
  }
}

class Operator {
  final int id;
  final String name;
  final String lastname;
  final String login;
  final String email;
  final String phone;
  final String image;
  final String? telegramUserId;
  final String jobTitle;
  final String fullName;
  final int isFirstLogin;
  final int? departmentId;
  final String uniqueId;
  final double? operatorAvgRating; // Изменено на double?

  Operator({
    required this.id,
    required this.name,
    required this.lastname,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    this.telegramUserId,
    required this.jobTitle,
    required this.fullName,
    required this.isFirstLogin,
    this.departmentId,
    required this.uniqueId,
    this.operatorAvgRating, // Теперь опционально
  });

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static String _toStringValue(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  factory Operator.fromJson(Map<String, dynamic> json) {
    final name = _toStringValue(json['name']);
    final lastname = _toStringValue(json['lastname']);
    final fullName = _toStringValue(
      json['full_name'],
      defaultValue: [name, lastname].where((part) => part.isNotEmpty).join(' ').trim(),
    );

    return Operator(
      id: _toInt(json['id']),
      name: name,
      lastname: lastname,
      login: _toStringValue(json['login']),
      email: _toStringValue(json['email']),
      phone: _toStringValue(json['phone']),
      image: _toStringValue(json['image']),
      telegramUserId: json['telegram_user_id']?.toString(),
      jobTitle: _toStringValue(json['job_title']),
      fullName: fullName,
      isFirstLogin: _toInt(json['is_first_login']),
      departmentId:
          json['department_id'] == null ? null : _toInt(json['department_id']),
      uniqueId: _toStringValue(json['unique_id']),
      operatorAvgRating: _toDoubleOrNull(json['operator_avg_rating']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastname': lastname,
      'login': login,
      'email': email,
      'phone': phone,
      'image': image,
      'telegram_user_id': telegramUserId,
      'job_title': jobTitle,
      'full_name': fullName,
      'is_first_login': isFirstLogin,
      'department_id': departmentId,
      'unique_id': uniqueId,
      'operator_avg_rating': operatorAvgRating,
    };
  }
}

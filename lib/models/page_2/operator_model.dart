import 'dart:convert';

class OperatorList {
  final List<Operator> result;
  final String? errors;

  OperatorList({
    required this.result,
    this.errors,
  });

  factory OperatorList.fromJson(Map<String, dynamic> json) {
    var resultList = json['result'] as List;
    List<Operator> operators = resultList.map((item) => Operator.fromJson(item)).toList();

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
  final double operatorAvgRating;

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
    required this.operatorAvgRating,
  });

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
      telegramUserId: json['telegram_user_id'],
      jobTitle: json['job_title'],
      fullName: json['full_name'],
      isFirstLogin: json['is_first_login'],
      departmentId: json['department_id'],
      uniqueId: json['unique_id'],
      operatorAvgRating: json['operator_avg_rating'].toDouble(),
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
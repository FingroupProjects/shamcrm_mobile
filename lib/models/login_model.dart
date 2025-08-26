import 'package:crm_task_manager/models/user.dart';

class LoginModel {
  final String login;
  final String password;

  LoginModel({required this.login, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'login': login,
      'password': password,
    };
  }
}

class LoginResponse {
  final String token;
  final User user;
  final List<String> permissions;
  final String? organizationId; // Новое поле для organization_id

  LoginResponse({
    required this.token,
    required this.user,
    required this.permissions,
    this.organizationId, // Может быть null, если сервер не возвращает
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      user: User.fromMap(json['user']),
      permissions: List<String>.from(json['permissions']),
      organizationId: json['organization_id']?.toString(), // Извлекаем organization_id
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toMap(),
      'permissions': permissions,
      'organization_id': organizationId,
    };
  }
}
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
  final String token; // Или другие поля, которые возвращает ваш API
  final User user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'], // Или другие поля
      user: User.fromMap(json['user']),
    );
  }
}

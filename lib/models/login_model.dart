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
  final List<String> permissions; // Добавлено для прав доступа

  LoginResponse({required this.token, required this.permissions});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      permissions: List<String>.from(json['permissions']), // Инициализируем права доступа из JSON
    );
  }
}


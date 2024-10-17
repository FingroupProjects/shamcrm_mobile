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

  LoginResponse({required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'], // Или другие поля
    );
  }
}

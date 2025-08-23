abstract class LoginEvent {}

class CheckLogin extends LoginEvent {
  final String login;
  final String password;

  CheckLogin(this.login, this.password);
}

class CheckCode extends LoginEvent {
  final String code;

  CheckCode(this.code);
}
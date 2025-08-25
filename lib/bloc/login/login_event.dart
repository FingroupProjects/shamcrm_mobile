import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class CheckLogin extends LoginEvent {
  final String login;
  final String password;

  CheckLogin(this.login, this.password);

  @override
  List<Object> get props => [login, password];
}
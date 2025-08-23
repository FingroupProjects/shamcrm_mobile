import 'package:crm_task_manager/models/login_model.dart';
import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginLoaded extends LoginState {
  final LoginResponse user;

  const LoginLoaded(this.user);

  @override
  List<Object> get props => [user];
}

class CodeChecking extends LoginState {}

class CodeChecked extends LoginState {
  final String domain;
  final String login;

  const CodeChecked(this.domain, this.login);

  @override
  List<Object> get props => [domain, login];
}

class LoginError extends LoginState {
  final String message;

  const LoginError(this.message);

  @override
  List<Object> get props => [message];
}
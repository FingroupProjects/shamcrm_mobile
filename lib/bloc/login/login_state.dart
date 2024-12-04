import 'package:crm_task_manager/models/user.dart';
import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginLoaded extends LoginState {
  final String token;
  final User user;

  const LoginLoaded(this.token, this.user);

  @override
  List<Object> get props => [token, user];
}

class LoginError extends LoginState {
  final String message;

  LoginError(this.message);

  @override
  List<Object> get props => [message];
}
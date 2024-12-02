import 'package:equatable/equatable.dart';

abstract class ForgotPinEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class RequestForgotPin extends ForgotPinEvent {
  final String login;
  final String password;

  RequestForgotPin({required this.login, this.password = ''});

  @override
  List<Object?> get props => [login, password];
}
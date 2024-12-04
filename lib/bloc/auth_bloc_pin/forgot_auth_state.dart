import 'package:equatable/equatable.dart';

abstract class ForgotPinState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ForgotPinInitial extends ForgotPinState {}

class ForgotPinLoading extends ForgotPinState {}

class ForgotPinSuccess extends ForgotPinState {
  final int pin;

  ForgotPinSuccess(this.pin);

  @override
  List<Object?> get props => [pin];
}

class ForgotPinFailure extends ForgotPinState {
  final String error;

  ForgotPinFailure(this.error);

  @override
  List<Object?> get props => [error];
}

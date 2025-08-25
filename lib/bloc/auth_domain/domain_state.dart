import 'package:equatable/equatable.dart';
import '../../models/domain_check.dart'; 

abstract class DomainState extends Equatable {
  const DomainState();

  @override
  List<Object> get props => [];
}

class DomainInitial extends DomainState {}

class DomainLoading extends DomainState {}

// Новое состояние для успешной верификации email
class EmailVerified extends DomainState {
  final String login;

  EmailVerified(this.login);

  @override
  List<Object> get props => [login];
}

// Старые состояния для обратной совместимости
class DomainLoaded extends DomainState {
  final DomainCheck domainCheck;

  DomainLoaded(this.domainCheck);

  @override
  List<Object> get props => [domainCheck];
}

class DomainError extends DomainState {
  final String message;

  DomainError(this.message);

  @override
  List<Object> get props => [message];
}
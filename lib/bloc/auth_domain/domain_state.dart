import 'package:equatable/equatable.dart';
import '../../models/domain_check.dart';

abstract class DomainState extends Equatable {
  const DomainState();

  @override
  List<Object?> get props => [];
}

class DomainInitial extends DomainState {}

class DomainLoading extends DomainState {}

// Состояние для успешной проверки email
class EmailVerified extends DomainState {
  final String login;
  
  const EmailVerified(this.login);
  
  @override
  List<Object?> get props => [login];
}

// Состояние для валидной сессии
class SessionValid extends DomainState {}

// Состояние для очищенной сессии
class SessionCleared extends DomainState {}

// Старое состояние для обратной совместимости
class DomainLoaded extends DomainState {
  final DomainCheck domainCheck;
  
  const DomainLoaded(this.domainCheck);
  
  @override
  List<Object?> get props => [domainCheck];
}

class DomainError extends DomainState {
  final String message;
  
  const DomainError(this.message);
  
  @override
  List<Object?> get props => [message];
}
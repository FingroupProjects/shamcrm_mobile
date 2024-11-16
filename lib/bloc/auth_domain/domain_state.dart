import 'package:equatable/equatable.dart';
import '../../models/domain_check.dart'; // Импортируй модель DomainCheck

abstract class DomainState extends Equatable {
  const DomainState();

  @override
  List<Object> get props => [];
}

class DomainInitial extends DomainState {}

class DomainLoading extends DomainState {}

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

import 'package:crm_task_manager/models/organization_model.dart';
import 'package:equatable/equatable.dart';

abstract class OrganizationState extends Equatable {
  const OrganizationState();

  @override
  List<Object> get props => [];
}

class OrganizationInitial extends OrganizationState {}

class OrganizationLoading extends OrganizationState {}

class OrganizationLoaded extends OrganizationState {
  final List<Organization> organizations;

  const OrganizationLoaded(this.organizations);

  @override
  List<Object> get props => [organizations];
}

class OrganizationError extends OrganizationState {
  final String message;

  const OrganizationError(this.message);

  @override
  List<Object> get props => [message];
}

// Новое состояние специально для ошибок авторизации
class OrganizationAuthError extends OrganizationState {
  final String message;

  const OrganizationAuthError(this.message);

  @override
  List<Object> get props => [message];
}
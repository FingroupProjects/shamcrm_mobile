import 'package:crm_task_manager/models/manager_model.dart';
import 'package:equatable/equatable.dart';

abstract class ManagerState extends Equatable {
  const ManagerState();

  @override
  List<Object> get props => [];
}

class ManagerInitial extends ManagerState {}

class ManagerLoading extends ManagerState {}

class ManagerLoaded extends ManagerState {
  final List<Manager> managers;

  const ManagerLoaded(this.managers);

  @override
  List<Object> get props => [managers];
}

class ManagerError extends ManagerState {
  final String message;

  const ManagerError(this.message);

  @override
  List<Object> get props => [message];
}

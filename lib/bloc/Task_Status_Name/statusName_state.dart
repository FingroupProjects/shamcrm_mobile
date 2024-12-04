import 'package:crm_task_manager/models/task_Status_Name_model.dart';
import 'package:equatable/equatable.dart';

abstract class StatusNameState extends Equatable {
  const StatusNameState();

  @override
  List<Object> get props => [];
}

class StatusNameInitial extends StatusNameState {}

class StatusNameLoading extends StatusNameState {}

class StatusNameLoaded extends StatusNameState {
  final List<StatusName> statusName;

  const StatusNameLoaded(this.statusName);

  @override
  List<Object> get props => [statusName];
}

class StatusNameError extends StatusNameState {
  final String message;

  const StatusNameError(this.message);

  @override
  List<Object> get props => [message];
}

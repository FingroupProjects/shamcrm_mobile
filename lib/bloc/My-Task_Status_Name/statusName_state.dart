import 'package:crm_task_manager/models/my-task_Status_Name_model.dart';
import 'package:equatable/equatable.dart';

abstract class MyStatusNameState extends Equatable {
  const MyStatusNameState();

  @override
  List<Object> get props => [];
}

class MyStatusNameInitial extends MyStatusNameState {}

class MyStatusNameLoading extends MyStatusNameState {}

class MyStatusNameLoaded extends MyStatusNameState {
  final List<MyStatusName> statusName;

  const MyStatusNameLoaded(this.statusName);

  @override
  List<Object> get props => [statusName];
}

class MyStatusNameError extends MyStatusNameState {
  final String message;

  const MyStatusNameError(this.message);

  @override
  List<Object> get props => [message];
}

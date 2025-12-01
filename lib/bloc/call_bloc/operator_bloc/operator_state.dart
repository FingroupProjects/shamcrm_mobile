import 'package:crm_task_manager/models/page_2/operator_model.dart';

abstract class OperatorState {}

class OperatorInitial extends OperatorState {}

class OperatorLoading extends OperatorState {}

class OperatorLoaded extends OperatorState {
  final List<Operator> operators;

  OperatorLoaded(this.operators);
}

class OperatorError extends OperatorState {
  final String message;

  OperatorError(this.message);
}
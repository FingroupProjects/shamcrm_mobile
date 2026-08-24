import 'package:crm_task_manager/models/page_2/employee_model.dart';

abstract class EmployeeState {}

class EmployeeInitial extends EmployeeState {}

class EmployeeLoading extends EmployeeState {}

class EmployeeLoaded extends EmployeeState {
  final List<EmployeeModel> employees;

  EmployeeLoaded(this.employees);
}

class EmployeeError extends EmployeeState {
  final String message;

  EmployeeError(this.message);
}

class EmployeeSuccess extends EmployeeState {
  final String message;

  EmployeeSuccess(this.message);
}

import 'package:crm_task_manager/models/page_2/employee_model.dart';

abstract class EmployeeEvent {}

class FetchEmployees extends EmployeeEvent {
  final String? query;

  FetchEmployees({this.query});
}

class AddEmployee extends EmployeeEvent {
  final EmployeeModel employee;

  AddEmployee(this.employee);
}

class UpdateEmployee extends EmployeeEvent {
  final int id;
  final EmployeeModel employee;

  UpdateEmployee(this.employee, this.id);
}

class DeleteEmployee extends EmployeeEvent {
  final int employeeId;

  DeleteEmployee(this.employeeId);
}

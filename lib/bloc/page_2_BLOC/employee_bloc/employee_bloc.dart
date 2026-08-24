import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_state.dart';
import 'package:flutter/foundation.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final ApiService apiService;
  String? _currentQuery;

  EmployeeBloc(this.apiService) : super(EmployeeInitial()) {
    on<FetchEmployees>(_fetchEmployees);
    on<AddEmployee>(_createEmployee);
    on<UpdateEmployee>(_updateEmployee);
    on<DeleteEmployee>(_deleteEmployee);
  }

  Future<void> _fetchEmployees(
    FetchEmployees event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(EmployeeLoading());

    if (!await _hasInternet()) {
      emit(EmployeeError('no_internet'));
      return;
    }

    try {
      _currentQuery = event.query;
      final employees = await apiService.getEmployees(search: event.query);
      emit(EmployeeLoaded(employees));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('EmployeeBloc fetch error: $e');
      }
      emit(EmployeeError('failed_to_load_employees'));
    }
  }

  Future<void> _createEmployee(
    AddEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(EmployeeLoading());

    if (!await _hasInternet()) {
      emit(EmployeeError('no_internet'));
      return;
    }

    try {
      await apiService.createEmployee(event.employee);
      emit(EmployeeSuccess('employee_created_successfully'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('EmployeeBloc create error: $e');
      }
      emit(EmployeeError(e.toString()));
    }
  }

  Future<void> _updateEmployee(
    UpdateEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(EmployeeLoading());

    if (!await _hasInternet()) {
      emit(EmployeeError('no_internet'));
      return;
    }

    try {
      await apiService.updateEmployee(id: event.id, employee: event.employee);
      emit(EmployeeSuccess('employee_updated_successfully'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('EmployeeBloc update error: $e');
      }
      emit(EmployeeError(e.toString()));
    }
  }

  Future<void> _deleteEmployee(
    DeleteEmployee event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(EmployeeLoading());

    if (!await _hasInternet()) {
      emit(EmployeeError('no_internet'));
      return;
    }

    try {
      await apiService.deleteEmployee(event.employeeId);
      final employees = await apiService.getEmployees(search: _currentQuery);
      emit(EmployeeLoaded(employees));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('EmployeeBloc delete error: $e');
      }
      emit(EmployeeError(e.toString()));
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}

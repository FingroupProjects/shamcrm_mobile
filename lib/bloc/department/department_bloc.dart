import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/department/department_event.dart';
import 'package:crm_task_manager/bloc/department/department_state.dart';

class DepartmentBloc extends Bloc<DepartmentEvent, DepartmentState> {
  final ApiService apiService;
  bool allDepartmentsFetched = false;

  DepartmentBloc(this.apiService) : super(DepartmentInitial()) {
    on<FetchDepartment>(_fetchDepartment);
  }

  Future<void> _fetchDepartment(FetchDepartment event, Emitter<DepartmentState> emit) async {
    emit(DepartmentLoading());

    if (await _checkInternetConnection()) {
      try {
        final departments = await apiService.getDepartments();
        allDepartmentsFetched = departments.isEmpty;
        emit(DepartmentLoaded(departments));
      } catch (e) {
        print('Ошибка при загрузке отделов!'); // Для отладки
        emit(DepartmentError('Не удалось загрузить список отделов!'));
      }
    } else {
      emit(DepartmentError('Нет подключения к интернету'));
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      return false;
    }
  }
}
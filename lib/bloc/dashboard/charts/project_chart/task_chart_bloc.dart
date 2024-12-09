import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectChartBloc extends Bloc<ProjectChartEvent, ProjectChartState> {
  final ApiService _apiService;

  ProjectChartBloc(this._apiService) : super(ProjectChartInitial()) {
    on<LoadProjectChartData>(_onLoadProjectChartData);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadProjectChartData(
    LoadProjectChartData event,
    Emitter<ProjectChartState> emit,
  ) async {
    print('ProjectChartBloc: Начало загрузки данных');
    try {
      emit(ProjectChartLoading());
      print('ProjectChartBloc: Состояние изменено на Loading');

      // Check for internet connection
      if (await _checkInternetConnection()) {
        final projectChartData = await _apiService.getProjectChartData();
        print('ProjectChartBloc: Данные успешно получены');
        
        emit(ProjectChartLoaded(data: projectChartData));
        print('ProjectChartBloc: Состояние изменено на Loaded');
      } else {
        // emit(ProjectChartError(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
        print('ProjectChartBloc: Состояние изменено на Error (нет интернета)');
      }
    } catch (e) {
      print('ProjectChartBloc: Произошла ошибка: $e');
      emit(ProjectChartError(message: e.toString()));
      print('ProjectChartBloc: Состояние изменено на Error');
    }
  }
}

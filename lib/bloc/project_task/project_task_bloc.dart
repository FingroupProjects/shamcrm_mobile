
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetTaskProjectBloc extends Bloc<GetTaskProjectEvent, GetTaskProjectState> {
  GetTaskProjectBloc() : super(GetTaskProjectInitial() as GetTaskProjectState) {
    on<GetTaskProjectEv>(_getProjects);
    on<GetTaskProjectMoreEv>(_getMoreProjects);
  }

  Future<void> _getProjects(GetTaskProjectEv event, Emitter<GetTaskProjectState> emit) async {
    emit(GetTaskProjectLoading());

    if (await _checkInternetConnection()) {
      try {
        var res = await ApiService().getTaskProject(page: event.page, perPage: event.perPage);
        final currentPage = res.pagination?.currentPage ?? 1;
        final totalPages = res.pagination?.totalPages ?? 1;
        emit(GetTaskProjectSuccess(
          dataProject: res,
          currentPage: currentPage,
          totalPages: totalPages,
          hasReachedMax: currentPage >= totalPages,
        ));
      } catch (e) {
        emit(GetTaskProjectError(message: e.toString()));
      }
    } else {
      emit(GetTaskProjectError(message: 'Нет подключения к интернету'));
    }
  }

  Future<void> _getMoreProjects(GetTaskProjectMoreEv event, Emitter<GetTaskProjectState> emit) async {
    final currentState = state;
    if (currentState is! GetTaskProjectSuccess || currentState.hasReachedMax) {
      return;
    }

    if (!await _checkInternetConnection()) {
      emit(GetTaskProjectError(message: 'Нет подключения к интернету'));
      return;
    }

    try {
      var res = await ApiService().getTaskProject(page: event.page, perPage: event.perPage);
      final newProjects = res.result ?? [];
      
      if (newProjects.isEmpty) {
        return;
      }

      final newCurrentPage = res.pagination?.currentPage ?? event.page;
      final newTotalPages = res.pagination?.totalPages ?? 1;
      
      emit(currentState.merge(newProjects, newCurrentPage, newTotalPages));
    } catch (e) {
      // При ошибке загрузки следующей страницы не меняем состояние
      // Просто не добавляем новые данные
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}

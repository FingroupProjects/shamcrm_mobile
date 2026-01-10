import 'dart:io';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/income_category_list/income_category_list_event.dart';
import 'package:crm_task_manager/bloc/income_category_list/income_category_list_state.dart';

import 'outcome_category_list_event.dart';
import 'outcome_category_list_state.dart';

class GetAllOutcomeCategoryBloc extends Bloc<GetAllOutcomeCategoryEvent, GetAllOutcomeCategoryState> {
  GetAllOutcomeCategoryBloc() : super(GetAllOutcomeCategoryInitial()) {
    on<GetAllOutcomeCategoryEv>(_getOutcomeCategories);
  }

  Future<void> _getOutcomeCategories(GetAllOutcomeCategoryEv event, Emitter<GetAllOutcomeCategoryState> emit) async {
    if (await _checkInternetConnection()) {
      try {
        emit(GetAllOutcomeCategoryLoading());

        var res = await ApiService().getAllOutcomeCategories();

        emit(GetAllOutcomeCategorySuccess(dataOutcomeCategories: res));
      } catch (e) {
        emit(GetAllOutcomeCategoryError(message: e.toString()));
      }
    } else {
      emit(GetAllOutcomeCategoryError(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
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

import 'dart:io';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/income_category_list/income_category_list_event.dart';
import 'package:crm_task_manager/bloc/income_category_list/income_category_list_state.dart';

class GetAllIncomeCategoryBloc extends Bloc<GetAllIncomeCategoryEvent, GetAllIncomeCategoryState> {
  GetAllIncomeCategoryBloc() : super(GetAllIncomeCategoryInitial()) {
    on<GetAllIncomeCategoryEv>(_getIncomeCategories);
  }

  Future<void> _getIncomeCategories(GetAllIncomeCategoryEv event, Emitter<GetAllIncomeCategoryState> emit) async {
    if (await _checkInternetConnection()) {
      try {
        emit(GetAllIncomeCategoryLoading());

        var res = await ApiService().getAllIncomeCategories();

        emit(GetAllIncomeCategorySuccess(dataIncomeCategories: res));
      } catch (e) {
        emit(GetAllIncomeCategoryError(message: e.toString()));
      }
    } else {
      emit(GetAllIncomeCategoryError(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
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

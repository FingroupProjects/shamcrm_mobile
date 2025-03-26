import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryByIdBloc extends Bloc<CategoryByIdEvent, CategoryByIdState> {
  final ApiService apiService;

  CategoryByIdBloc(this.apiService) : super(CategoryByIdInitial()) {
    on<FetchCategoryByIdEvent>(_getCategoryById);
  }

  Future<void> _getCategoryById(FetchCategoryByIdEvent event, Emitter<CategoryByIdState> emit) async {
    emit(CategoryByIdLoading());

    if (await _checkInternetConnection()) {
      try {
        final category = await apiService.getSubCategoryById(event.categoryId);
        emit(CategoryByIdLoaded(category));
      } catch (e) {
        emit(CategoryByIdError('Не удалось загрузить данные категории!'));
      }
    } else {
      emit(CategoryByIdError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
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

import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ApiService apiService;

  CategoryBloc(this.apiService) : super(CategoryInitial()) {
    on<FetchCategories>(_fetchCategories);
    on<CreateCategory>(_createCategory);
  }

Future<void> _fetchCategories(FetchCategories event, Emitter<CategoryState> emit) async {
  emit(CategoryLoading());

  if (await _checkInternetConnection()) {
    try {
      final categories = await apiService.getCategory();

      // Проверяем, пуст ли список категорий
      if (categories.isEmpty) {
        emit(CategoryEmpty());
      } else {
        emit(CategoryLoaded(categories));
      }
    } catch (e) {
      print("Error fetching categories: $e");
      emit(CategoryError('Не удалось загрузить категории!'));
    }
  } else {
    emit(CategoryError('Нет подключения к интернету'));
  }
}

Future<void> _createCategory(CreateCategory event, Emitter<CategoryState> emit) async {
  emit(CategoryCreating());

  if (await _checkInternetConnection()) {
    try {
      final response = await apiService.createCategory(
        name: event.name,
        parentId: event.parentId,
        attributeIds: event.attributeIds,
        image: event.image,
      );

      if (response['success'] == true) {
        // После успешного создания, ничего не эмитим, так как мы заново загрузим список
        // Главное - не эмитить ошибку
      } else {
        final errorMessage = response['message'] ?? 'Неизвестная ошибка';
        emit(CategoryCreateError(errorMessage));
      }
    } catch (e) {
      emit(CategoryCreateError('Не удалось создать категорию: ${e.toString()}'));
    }
  } else {
    emit(CategoryCreateError('Нет подключения к интернету'));
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
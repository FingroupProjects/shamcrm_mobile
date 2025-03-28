import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ApiService apiService;
  List<CategoryData> _categories = []; 

  CategoryBloc(this.apiService) : super(CategoryInitial()) {
    on<FetchCategories>(_fetchCategories);
    on<CreateCategory>(_createCategory);
    on<UpdateCategory>(_updateCategory);
    on<DeleteCategory>(_deleteCategory);
    on<UpdateSubCategory>(_updateSubCategory);
  }

  Future<void> _fetchCategories(FetchCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    
    if (await _checkInternetConnection()) {
      try {
        _categories = await apiService.getCategory(); 
        if (_categories.isEmpty) {
          emit(CategoryEmpty());
        } else {
          emit(CategoryLoaded(_categories));
        }
      } catch (e) {
        emit(CategoryError('Не удалось загрузить категории!'));
      }
    } else {
      emit(CategoryError('Нет подключения к интернету'));
    }
  }

Future<void> _createCategory(CreateCategory event, Emitter<CategoryState> emit) async {
  emit(CategoryLoading());
  
  if (await _checkInternetConnection()) {
    try {
      final response = await apiService.createCategory(
        name: event.name,
        parentId: event.parentId,
        attributeNames: event.attributeNames,
        image: event.image,
      );

      if (response['success'] == true) {
        add(FetchCategories());
        emit(CategorySuccess("Категория успешно создана"));
      } else {
        emit(CategoryCreateError(response['message'] ?? 'Неизвестная ошибка'));
      }
    } catch (e) {
      emit(CategoryCreateError('Не удалось создать категорию: ${e.toString()}'));
    }
  } else {
    emit(CategoryCreateError('Нет подключения к интернету'));
  }
}

Future<void> _updateCategory(UpdateCategory event, Emitter<CategoryState> emit) async {
  emit(CategoryLoading());

  if (await _checkInternetConnection()) {
    try {
      final response = await apiService.updateCategory(
        categoryId: event.categoryId,
        name: event.name,
        image: event.image,
      );

      if (response['success'] == true) {
        add(FetchCategories()); 
        emit(CategorySuccess(response['message'] ?? 'Категория успешно обновлена'));
      } else {
        emit(CategoryError(response['message'] ?? 'Ошибка при обновлении категории'));
      }
    } catch (e) {
      emit(CategoryError('Не удалось обновить категорию: ${e.toString()}'));
    }
  } else {
    emit(CategoryError('Нет подключения к интернету'));
  }
}

Future<void> _updateSubCategory(UpdateSubCategory event, Emitter<CategoryState> emit) async {
  emit(CategoryLoading());

  if (await _checkInternetConnection()) {
    // try {
    //   final response = await apiService.updateSubCategory(
    //     subCategoryId: event.subCategoryId,
    //     name: event.name,
    //     image: event.image,
    //     attributeNames: event.attributeNames
    //   );

    //   if (response['success'] == true) {
    //     add(FetchCategories()); 
    //     emit(CategorySuccess(response['message'] ?? 'Подкатегория успешно обновлена'));
    //   } else {
    //     emit(CategoryError(response['message'] ?? 'Ошибка при обновлении подкатегории'));
    //   }
    // } catch (e) {
    //   emit(CategoryError('Не удалось обновить подкатегорию: ${e.toString()}'));
    // }
  } else {
    emit(CategoryError('Нет подключения к интернету'));
  }
}

  Future<void> _deleteCategory(DeleteCategory event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.deleteCategory(event.catgeoryId);
        if (response['result'] == 'Success') {
          emit(CategoryDeleted('Категория успешно удалена'));
          add(FetchCategories()); 
        } else {
          emit(CategoryError('Ошибка удаления категории'));
        }
      } catch (e) {
        emit(CategoryError('Ошибка удаления категории!'));
      }
    } else {
      emit(CategoryError('Нет подключения к интернету'));
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
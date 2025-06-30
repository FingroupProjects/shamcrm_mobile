import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryById.dart'; // Для SubCategoryResponseASD
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ApiService apiService;
  List<CategoryData> _categories = [];
  String? _currentQuery;
  final Map<int, CategoryDataById> _categoryCache = {}; // Кэш для категорий по ID

  CategoryBloc(this.apiService) : super(CategoryInitial()) {
    on<FetchCategories>(_fetchCategories);
    on<CreateCategory>(_createCategory);
    on<UpdateCategory>(_updateCategory);
    on<DeleteCategory>(_deleteCategory);
    on<UpdateSubCategory>(_updateSubCategory);
    on<SearchCategories>(_searchCategories);
    on<FetchSubCategoryById>(_fetchSubCategoryById); // Новое событие для подкатегорий
  }

  Future<void> _fetchCategories(FetchCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    
    if (await _checkInternetConnection()) {
      try {
        _categories = await apiService.getCategory(search: _currentQuery);
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

  Future<void> _searchCategories(SearchCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    
    _currentQuery = event.query.isEmpty ? null : event.query;
    
    if (await _checkInternetConnection()) {
      try {
        _categories = await apiService.getCategory(search: _currentQuery);
        if (_categories.isEmpty) {
          emit(CategoryEmpty());
        } else {
          emit(CategoryLoaded(_categories));
        }
      } catch (e) {
        emit(CategoryError('Не удалось выполнить поиск категорий!'));
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
          attributes: event.attributes,
          image: event.image,
          displayType: event.displayType,
          hasPriceCharacteristics: event.hasPriceCharacteristics,
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
      try {
        final response = await apiService.updateSubCategory(
          subCategoryId: event.subCategoryId,
          name: event.name,
          image: event.image,
          attributes: event.attributes,
          displayType: event.displayType,
          hasPriceCharacteristics: event.hasPriceCharacteristics,
        );

        if (response['success'] == true) {
          add(FetchCategories());
          emit(CategorySuccess(response['message'] ?? 'subcategory_updated_successfully'));
        } else {
          emit(CategoryError(response['message'] ?? 'error_update_subcategory'));
        }
      } catch (e) {
        emit(CategoryError('failed_to_update_subcategory: ${e.toString()}'));
      }
    } else {
      emit(CategoryError('no_internet_connection'));
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

  Future<void> _fetchSubCategoryById(FetchSubCategoryById event, Emitter<CategoryState> emit) async {
    if (_categoryCache.containsKey(event.categoryId)) {
      emit(SubCategoryByIdLoaded(_categoryCache[event.categoryId]!));
      return;
    }

    emit(CategoryLoading());
    try {
      final category = await apiService.getSubCategoryById(event.categoryId);
      _categoryCache[event.categoryId] = category.categories.first;
      emit(SubCategoryByIdLoaded(category.categories.first));
    } catch (e) {
      emit(CategoryError('Не удалось загрузить подкатегорию!'));
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
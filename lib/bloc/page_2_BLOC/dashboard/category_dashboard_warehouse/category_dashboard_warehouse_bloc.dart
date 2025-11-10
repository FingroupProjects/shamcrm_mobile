import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_state.dart';


class CategoryDashboardWarehouseBloc extends Bloc<CategoryDashboardWarehouseEvent, CategoryDashboardWarehouseState> {
  final ApiService apiService;
  bool allCategoryDashboardWarehouseFetched = false;

  CategoryDashboardWarehouseBloc(this.apiService) : super(CategoryDashboardWarehouseInitial()) {
    on<FetchCategoryDashboardWarehouse>(_fetchCategoryDashboardWarehouse);
  }

  Future<void> _fetchCategoryDashboardWarehouse(FetchCategoryDashboardWarehouse event, Emitter<CategoryDashboardWarehouseState> emit) async {
    emit(CategoryDashboardWarehouseLoading());

    if (await _checkInternetConnection()) {
      try {
        final categoryDashboardWarehouse = await apiService.getCategoryDashboardWarehouse();
        allCategoryDashboardWarehouseFetched = categoryDashboardWarehouse.isEmpty;
        emit(CategoryDashboardWarehouseLoaded(categoryDashboardWarehouse));
      } catch (e) {
        print('Ошибка при загрузке категорий!');  // Для отладки
        emit(CategoryDashboardWarehouseError('Не удалось загрузить список Категорий!'));
      }
    } else {
      emit(CategoryDashboardWarehouseError('Нет подключения к интернету'));
    }
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      return false;
    }
  }
}
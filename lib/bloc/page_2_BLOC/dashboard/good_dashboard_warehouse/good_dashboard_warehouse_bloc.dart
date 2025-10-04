import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_state.dart';

class GoodDashboardWarehouseBloc extends Bloc<GoodDashboardWarehouseEvent, GoodDashboardWarehouseState> {
  final ApiService apiService;
  bool allGoodDashboardWarehouseFetched = false;

  GoodDashboardWarehouseBloc(this.apiService) : super(GoodDashboardWarehouseInitial()) {
    on<FetchGoodDashboardWarehouse>(_fetchGoodDashboardWarehouse);
  }

  Future<void> _fetchGoodDashboardWarehouse(FetchGoodDashboardWarehouse event, Emitter<GoodDashboardWarehouseState> emit) async {
    emit(GoodDashboardWarehouseLoading());

    if (await _checkInternetConnection()) {
      try {
        final goodDashboardWarehouse = await apiService.getGoodDashboardWarehouse();
        allGoodDashboardWarehouseFetched = goodDashboardWarehouse.isEmpty;
        emit(GoodDashboardWarehouseLoaded(goodDashboardWarehouse));
      } catch (e) {
        print('Ошибка при загрузке товаров!');  // Для отладки
        emit(GoodDashboardWarehouseError('Не удалось загрузить список Товаров!'));
      }
    } else {
      emit(GoodDashboardWarehouseError('Нет подключения к интернету'));
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
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/storage_dashboard/storage_dashboard_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/storage_dashboard/storage_dashboard_state.dart';

class StorageDashboardBloc extends Bloc<StorageDashboardEvent, StorageDashboardState> {
  final ApiService apiService;
  bool allStorageFetched = false;

  StorageDashboardBloc(this.apiService) : super(StorageDashboardInitial()) {
    on<FetchStorageDashboard>(_fetchStorageDashboard);
  }

  Future<void> _fetchStorageDashboard(
      FetchStorageDashboard event, Emitter<StorageDashboardState> emit) async {
    emit(StorageDashboardLoading());

    if (await _checkInternetConnection()) {
      try {
        final storageList = await apiService.getStorage();
        allStorageFetched = storageList.isEmpty;
        emit(StorageDashboardLoaded(storageList));
      } catch (e) {
        //print('Ошибка при загрузке складов!'); // For debugging
        emit(StorageDashboardError('Не удалось загрузить список складов!'));
      }
    } else {
      emit(StorageDashboardError('Нет подключения к интернету'));
    }
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}


import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_state.dart';


class StorageBloc extends Bloc<StorageEvent, StorageState> {
  final ApiService apiService;
  bool allStorageFetched = false;

  StorageBloc(this.apiService) : super(StorageInitial()) {
    on<FetchStorage>(_fetchStorage);
  }

  Future<void> _fetchStorage(FetchStorage event, Emitter<StorageState> emit) async {
    emit(StorageLoading());

    if (await _checkInternetConnection()) {
      try {
        final storageList = await apiService.getStorage(); 
        allStorageFetched = storageList.isEmpty;
        emit(StorageLoaded(storageList)); 
      } catch (e) {
        //print('Ошибка при загрузке складов!'); // For debugging
        emit(StorageError('Не удалось загрузить список складов!'));
      }
    } else {
      emit(StorageError('Нет подключения к интернету'));
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
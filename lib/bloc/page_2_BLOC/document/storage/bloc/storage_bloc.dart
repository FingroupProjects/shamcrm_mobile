import 'package:crm_task_manager/api/service/api_service.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'storage_event.dart';
import 'storage_state.dart';

class WareHouseBloc extends Bloc<WareHouseEvent, WareHouseState> {
  final ApiService apiService;

  WareHouseBloc(this.apiService) : super(WareHouseInitial()) {
    on<FetchWareHouse>(_onFetch);
    on<CreateWareHouse>(_onCreate);
    on<UpdateWareHouse>(_onUpdate);
    on<DeleteWareHouse>(_onDelete);
  }

  Future<void> _onFetch(
      FetchWareHouse event, Emitter<WareHouseState> emit) async {
    emit(WareHouseLoading());
    try {
      final storages = await apiService.getWareHouses(
        search: event.query,
      );
      emit(WareHouseLoaded(storages));
    } catch (e) {
      emit(WareHouseError("error_loading_storages"));
    }
  }

  Future<void> _onCreate(
      CreateWareHouse event, Emitter<WareHouseState> emit) async {
    try {
      final result = await apiService.createStorage(event.storage, event.ids);
      if (result) {
        emit(WareHouseSuccess());
      }
    } catch (e) {
      emit(WareHouseError("error_loading_storages"));
    }
  }

  Future<void> _onUpdate(
      UpdateWareHouse event, Emitter<WareHouseState> emit) async {
    try {
      final result = await apiService.updateStorage(storage: event.storage, ids: event.ids, id: event.id);
      emit(WareHouseSuccess());
    } catch (e) {
      emit(WareHouseError("error_loading_storages"));
    }
  }

  Future<void> _onDelete(
      DeleteWareHouse event, Emitter<WareHouseState> emit) async {
    try {
      await apiService.deleteStorage(event.id);
      add(FetchWareHouse());
    } catch (e) {
      emit(WareHouseError("error_loading_storages"));
    }
  }
}

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_event.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Data1CBloc extends Bloc<Data1CEvent, Data1CState> {
  final ApiService apiService; // Замените на ваш класс API-сервиса

  Data1CBloc({required this.apiService}) : super(Data1CInitial()) {
    on<FetchData1C>(_onFetchData1C);
  }

  Future<void> _onFetchData1C(
      FetchData1C event, Emitter<Data1CState> emit) async {
    emit(Data1CLoading());
    try {
      final data1C = await apiService.getData1C();
      emit(Data1CLoaded(data1C));
    } catch (e) {
      emit(Data1CError(e.toString()));
    }
  }
}

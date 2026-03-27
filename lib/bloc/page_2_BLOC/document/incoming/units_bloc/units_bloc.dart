import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_state.dart';

class UnitsBloc extends Bloc<UnitsEvent, UnitsState> {
  final ApiService apiService;
  bool allUnitsFetched = false;

  UnitsBloc(this.apiService) : super(UnitsInitial()) {
    on<FetchUnits>(_fetchUnits);
  }

  Future<void> _fetchUnits(
      FetchUnits event, Emitter<UnitsState> emit) async {
    emit(UnitsLoading());

    if (await _checkInternetConnection()) {
      try {
        final unitsList = await apiService.getAllMeasureUnits();
        allUnitsFetched = unitsList.isEmpty;
        emit(UnitsLoaded(unitsList));
      } catch (e) {
        //print('Ошибка при загрузке единиц измерения!'); // For debugging
        emit(UnitsError('Не удалось загрузить список единиц измерения!'));
      }
    } else {
      emit(UnitsError('Нет подключения к интернету'));
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


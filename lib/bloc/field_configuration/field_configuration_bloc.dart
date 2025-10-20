import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FieldConfigurationBloc extends Bloc<FieldConfigurationEvent, FieldConfigurationState> {
  final ApiService apiService;

  FieldConfigurationBloc(this.apiService) : super(FieldConfigurationInitial()) {
    on<FetchFieldConfiguration>(_onFetchFieldConfiguration);
  }

  Future<void> _onFetchFieldConfiguration(
    FetchFieldConfiguration event,
    Emitter<FieldConfigurationState> emit,
  ) async {
    emit(FieldConfigurationLoading());
    try {
      final response = await apiService.getFieldPositions(
        tableName: event.tableName,
      );
      
      // Фильтруем только активные поля и сортируем по position
      final activeFields = response.result
          .where((field) => field.isActive)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      
      emit(FieldConfigurationLoaded(activeFields));
    } catch (e) {
      emit(FieldConfigurationError(e.toString()));
    }
  }
}
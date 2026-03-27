import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';
import 'measure_units_event.dart';
import 'measure_units_state.dart';

class MeasureUnitsBloc extends Bloc<MeasureUnitsEvent, MeasureUnitsState> {
  final ApiService apiService;
  String? _currentQuery; // Сохраняем текущий поисковый запрос

  MeasureUnitsBloc(this.apiService) : super(MeasureUnitsInitial()) {
    on<FetchMeasureUnits>(_onFetch);
    on<RefreshMeasureUnits>(_onRefresh);
    on<AddMeasureUnitEvent>(_onAddMeasureUnit);
    on<EditMeasureUnitEvent>(_onEditMeasureUnit);
    on<DeleteMeasureUnitEvent>(_onDeleteMeasureUnit);
  }

  Future<void> _onFetch(
    FetchMeasureUnits event,
    Emitter<MeasureUnitsState> emit,
  ) async {
    emit(MeasureUnitsLoading());
    // Сохраняем текущий query
    _currentQuery = event.query;
    await _fetchAndEmit(emit, search: event.query);
  }

  Future<void> _onRefresh(
    RefreshMeasureUnits event,
    Emitter<MeasureUnitsState> emit,
  ) async {
    // keep UI responsive; show loading during refresh
    emit(MeasureUnitsLoading());
    // Сохраняем текущий query
    _currentQuery = event.query;
    await _fetchAndEmit(emit, search: event.query);
  }

  Future<void> _fetchAndEmit(Emitter<MeasureUnitsState> emit, {String? search}) async {
    try {
      final dynamic response = await apiService.getMeasureUnits(search: search);
      // attempt to normalize response into List<MeasureUnit>
      List<MeasureUnitModel> units = [];
      if (response == null) {
        units = [];
      } else if (response is List) {
        // assume list already contains MeasureUnit (or map that MeasureUnit.fromMap handles)
        units = response.cast<MeasureUnitModel>();
      } else if (response is Map && response['result'] != null) {
        units = (response['result'] as List).cast<MeasureUnitModel>();
      } else {
        // fallback if ApiService returns a typed wrapper with `.data` or `.items`
        try {
          final list =
              (response as dynamic).data ?? (response as dynamic).items ?? [];
          units = (list as List).cast<MeasureUnitModel>();
        } catch (_) {
          units = [];
        }
      }

      if (units.isEmpty) {
        emit(MeasureUnitsEmpty());
      } else {
        emit(MeasureUnitsLoaded(units));
      }
    } catch (e) {
      emit(MeasureUnitsError(e.toString()));
    }
  }

  Future<void> _onAddMeasureUnit(
    AddMeasureUnitEvent event,
    Emitter<MeasureUnitsState> emit,
  ) async {
    try {
      emit(MeasureUnitsLoading());
      await apiService.createMeasureUnit(event.measureUnitModel);
      await _fetchAndEmit(emit); // Refresh the list after adding
    } catch (e) {
      emit(MeasureUnitsError(e.toString()));
    }
  }

  Future<void> _onEditMeasureUnit(
    EditMeasureUnitEvent event,
    Emitter<MeasureUnitsState> emit,
  ) async {
    try {
      emit(MeasureUnitsLoading());
      await apiService.updateUnit(
          id: event.id, supplier: event.measureUnitModel);
      await _fetchAndEmit(emit); // Refresh the list after editing
    } catch (e) {
      emit(MeasureUnitsError(e.toString()));
    }
  }

  Future<void> _onDeleteMeasureUnit(
    DeleteMeasureUnitEvent event,
    Emitter<MeasureUnitsState> emit,
  ) async {
    try {
      emit(MeasureUnitsLoading());
      await apiService.deleteMeasureUnit(event.id);
      // Используем сохраненный query при обновлении списка
      await _fetchAndEmit(emit, search: _currentQuery);
    } catch (e) {
      emit(MeasureUnitsError(e.toString()));
    }
  }
}

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_state.dart';
import 'package:crm_task_manager/models/page_2/price_type_model.dart';

class PriceTypeScreenBloc extends Bloc<PriceTypeEvent, PriceTypeState> {
  final ApiService apiService;

  PriceTypeScreenBloc(this.apiService) : super(PriceTypeInitial()) {
    on<FetchPriceType>(_onFetch);
    on<RefreshPriceType>(_onRefresh);
    on<AddPriceType>(_onAddMeasureUnit);
    on<EditPriceTypeEvent>(_onEditMeasureUnit);
    on<DeletePriceType>(_onDeleteMeasureUnit);
  }

  Future<void> _onFetch(
    FetchPriceType event,
    Emitter<PriceTypeState> emit,
  ) async {
    emit(PriceTypeLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    RefreshPriceType event,
    Emitter<PriceTypeState> emit,
  ) async {
    // keep UI responsive; show loading during refresh
    emit(PriceTypeLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<PriceTypeState> emit) async {
    try {
      final dynamic response = await apiService.getPriceTypes();
      // attempt to normalize response into List<MeasureUnit>
      List<PriceTypeModel> units = [];
      if (response == null) {
        units = [];
      } else if (response is List) {
        // assume list already contains MeasureUnit (or map that MeasureUnit.fromMap handles)
        units = response.cast<PriceTypeModel>();
      } else if (response is Map && response['result'] != null) {
        units = (response['result'] as List).cast<PriceTypeModel>();
      } else {
        // fallback if ApiService returns a typed wrapper with `.data` or `.items`
        try {
          final list =
              (response as dynamic).data ?? (response as dynamic).items ?? [];
          units = (list as List).cast<PriceTypeModel>();
        } catch (_) {
          units = [];
        }
      }

      if (units.isEmpty) {
        emit(PriceTypeEmpty());
      } else {
        emit(PriceTypeLoaded(units));
      }
    } catch (e) {
      emit(PriceTypeError(e.toString()));
    }
  }

  Future<void> _onAddMeasureUnit(
    AddPriceType event,
    Emitter<PriceTypeState> emit,
  ) async {
    try {
      emit(PriceTypeLoading());
      await apiService.createPriceType(event.priceType);
      await _fetchAndEmit(emit); // Refresh the list after adding
    } catch (e) {
      emit(PriceTypeError(e.toString()));
    }
  }

  Future<void> _onEditMeasureUnit(
    EditPriceTypeEvent event,
    Emitter<PriceTypeState> emit,
  ) async {
    try {
      emit(PriceTypeLoading());
      await apiService.updatePriceType(id: event.id, supplier: event.priceType);
      await _fetchAndEmit(emit); // Refresh the list after editing
    } catch (e) {
      emit(PriceTypeError(e.toString()));
    }
  }

  Future<void> _onDeleteMeasureUnit(
    DeletePriceType event,
    Emitter<PriceTypeState> emit,
  ) async {
    try {
      emit(PriceTypeLoading());
      await apiService.deleteMeasureUnit(event.id);
      await _fetchAndEmit(emit); // Refresh the list after deletion
    } catch (e) {
      emit(PriceTypeError(e.toString()));
    }
  }
}

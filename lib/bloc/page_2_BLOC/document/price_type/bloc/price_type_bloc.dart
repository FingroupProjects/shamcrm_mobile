import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_state.dart';
import 'package:crm_task_manager/models/page_2/price_type_model.dart';
import 'package:flutter/cupertino.dart';

class PriceTypeScreenBloc extends Bloc<PriceTypeEvent, PriceTypeState> {
  final ApiService apiService;
  String? _currentQuery; // Сохраняем текущий поисковый запрос

  PriceTypeScreenBloc(this.apiService) : super(PriceTypeInitial()) {
    on<FetchPriceType>(_onFetch);
    on<RefreshPriceType>(_onRefresh);
    on<AddPriceType>(_onAddPriceType);
    on<EditPriceTypeEvent>(_onEditPriceType);
    on<DeletePriceType>(_onDeletePriceType);
  }

  Future<void> _onFetch(
      FetchPriceType event,
      Emitter<PriceTypeState> emit,
      ) async {
    emit(PriceTypeLoading());
    // Сохраняем текущий query
    _currentQuery = event.query;
    await _fetchAndEmit(emit, search: event.query);
  }

  Future<void> _onRefresh(
      RefreshPriceType event,
      Emitter<PriceTypeState> emit,
      ) async {
    // keep UI responsive; show loading during refresh
    emit(PriceTypeLoading());
    // Сохраняем текущий query
    _currentQuery = event.query;
    await _fetchAndEmit(emit, search: event.query);
  }

  Future<void> _fetchAndEmit(Emitter<PriceTypeState> emit, {String? search}) async {
    try {
      final dynamic response = await apiService.getPriceTypes(search: search);
      // attempt to normalize response into List<PriceType>
      List<PriceTypeModel> units = [];
      if (response == null) {
        units = [];
      } else if (response is List) {
        // assume list already contains PriceType (or map that PriceType.fromMap handles)
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
          debugPrint("Failed to parse price types from response: $response");
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

  Future<void> _onAddPriceType(
      AddPriceType event,
      Emitter<PriceTypeState> emit,
      ) async {
    try {
      emit(PriceTypeLoading());
      await apiService.createPriceType(event.priceType);

      // Emit success state
      emit(PriceTypeSuccess("price_type_added_successfully"));

      // Small delay to ensure the BlocListener catches the success state
      await Future.delayed(const Duration(milliseconds: 150));

      // Then refresh the list with saved query
      await _fetchAndEmit(emit, search: _currentQuery);
    } catch (e) {
      debugPrint("Error adding price type: $e");
      emit(PriceTypeError(e.toString()));
    }
  }

  Future<void> _onEditPriceType(
      EditPriceTypeEvent event,
      Emitter<PriceTypeState> emit,
      ) async {
    try {
      emit(PriceTypeLoading());
      await apiService.updatePriceType(id: event.id, priceType: event.priceType);

      // Emit success state
      emit(PriceTypeSuccess("price_type_updated_successfully"));

      // Small delay to ensure the BlocListener catches the success state
      await Future.delayed(const Duration(milliseconds: 150));

      // Then refresh the list with saved query
      await _fetchAndEmit(emit, search: _currentQuery);
    } catch (e) {
      emit(PriceTypeError(e.toString()));
    }
  }

  Future<void> _onDeletePriceType(
      DeletePriceType event,
      Emitter<PriceTypeState> emit,
      ) async {
    try {
      emit(PriceTypeLoading());
      await apiService.deletePriceType(event.id);

      // Emit success state
      emit(PriceTypeSuccess("price_type_deleted_successfully"));

      // Small delay to ensure the BlocListener catches the success state
      await Future.delayed(const Duration(milliseconds: 150));

      // Then refresh the list with saved query
      await _fetchAndEmit(emit, search: _currentQuery);
    } catch (e) {
      emit(PriceTypeError(e.toString()));
    }
  }
}
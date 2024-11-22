import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class DealStatsBloc extends Bloc<DealStatsEvent, DealStatsState> {
  final ApiService apiService;

  DealStatsBloc(this.apiService) : super(DealStatsInitial()) {
    on<LoadDealStatsData>(_onLoadDealStatsData);
  }

  Future<void> _onLoadDealStatsData(
    LoadDealStatsData event,
    Emitter<DealStatsState> emit,
  ) async {
    try {
      emit(DealStatsLoading());
      final dealStatsData = await apiService.getDealStatsData();
      emit(DealStatsLoaded(dealStatsData: dealStatsData));
    } catch (e) {
      emit(DealStatsError(message: e.toString()));
    }
  }
}

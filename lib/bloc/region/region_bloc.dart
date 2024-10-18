import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'region_event.dart';
import 'region_state.dart';

class RegionBloc extends Bloc<RegionEvent, RegionState> {
  final ApiService apiService;

  RegionBloc(this.apiService) : super(RegionInitial()) {
    on<FetchRegions>((event, emit) async {
      emit(RegionLoading());
      try {
        final regions = await apiService.getRegion();
        emit(RegionLoaded(regions));
      } catch (e) {
        emit(RegionError('Ошибка при загрузке регионов'));
      }
    });
  }
}

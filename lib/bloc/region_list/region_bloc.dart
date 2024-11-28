import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:meta/meta.dart';

part 'region_event.dart';
part 'region_state.dart';

class GetAllRegionBloc extends Bloc<GetAllRegionEvent, GetAllRegionState> {
  GetAllRegionBloc() : super(GetAllRegionInitial()) {
    on<GetAllRegionEv>(_getRegions);
  }

  Future<void> _getRegions(GetAllRegionEv event, Emitter<GetAllRegionState> emit) async {

    try {
      emit(GetAllRegionLoading());

      var res = await ApiService().getAllRegion();

      emit(GetAllRegionSuccess(dataRegion: res));
    } catch(e) {
      emit(GetAllRegionError(message: e.toString()));
    }

  }
}

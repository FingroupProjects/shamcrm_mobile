// BLoC
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_event.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_lists_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetAllDealNameBloc extends Bloc<GetAllDealNameEvent, GetAllDealNameState> {
  GetAllDealNameBloc() : super(GetAllDealNameInitial()) {
    on<GetAllDealNameEv>(_getDealNames);
  }

  Future<void> _getDealNames(
    GetAllDealNameEv event,
    Emitter<GetAllDealNameState> emit,
  ) async {
    try {
      emit(GetAllDealNameLoading());
      final res = await ApiService().getAllDealNames();
      emit(GetAllDealNameSuccess(dataDealName: res));
    } catch (e) {
      emit(GetAllDealNameError(message: e.toString()));
    }
  }
}
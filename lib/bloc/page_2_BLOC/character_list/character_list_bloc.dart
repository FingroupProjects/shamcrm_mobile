import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/character_list/character_list_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/character_list/character_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetAllCharacterListBloc extends Bloc<GetAllCharacterListEvent, GetAllCharacterListState> {
  GetAllCharacterListBloc() : super(GetAllCharacterListInitial()) {
    on<GetAllCharacterListEv>(_getCharacterLists);
  }

  Future<void> _getCharacterLists(
    GetAllCharacterListEv event,
    Emitter<GetAllCharacterListState> emit,
  ) async {
    try {
      emit(GetAllCharacterListLoading());
      final res = await ApiService().getAllCharacteristics();
      emit(GetAllCharacterListSuccess(dataCharacterList: res));
    } catch (e) {
      emit(GetAllCharacterListError(message: e.toString()));
    }
  }
}
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:meta/meta.dart';

part 'get_all_author_event.dart';
part 'get_all_author_state.dart';

class GetAllAuthorBloc extends Bloc<GetAllAuthorEvent, GetAllAuthorState> {
  final ApiService apiService;

  GetAllAuthorBloc({required this.apiService}) : super(GetAllAuthorInitial()) {
    on<GetAllAuthorEv>(_getAuthors);
  }

  Future<void> _getAuthors(
      GetAllAuthorEv event, Emitter<GetAllAuthorState> emit) async {
    try {
      emit(GetAllAuthorLoading());
      var res = await apiService.getAllAuthor();
      emit(GetAllAuthorSuccess(dataAuthor: res));
    } catch (e) {
      emit(GetAllAuthorError(message: e.toString()));
    }
  }


}


import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:equatable/equatable.dart';

part 'chats_event.dart';
part 'chats_state.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final ApiService apiService;

  ChatsBloc(this.apiService) : super(ChatsInitial()) {
    on<FetchChats>((event, emit) async {
      emit(ChatsLoading());
      try {
        final chats = await apiService.getAllChats();
        emit(ChatsLoaded(chats));
      } catch (e) {
        emit(ChatsError(e.toString()));
      }
    });

  
  }
}



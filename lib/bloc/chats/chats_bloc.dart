import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/pagination_dto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'chats_event.dart';
part 'chats_state.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final ApiService apiService;
  String endPoint = '';

  PaginationDTO<Chats>? chatsPagination;

  ChatsBloc(this.apiService) : super(ChatsInitial()) {
    on<FetchChats>(_fetchChatsEvent);
    on<RefreshChats>(_refetchChatsEvent);
    on<GetNextPageChats>(_getNextPageChatsEvent);
    on<UpdateChatsFromSocket>(_updateChatsFromSocketFetch);
  }

  Future<void> _fetchChatsEvent(
      FetchChats event, Emitter<ChatsState> emit) async {
    endPoint = event.endPoint;
    emit(ChatsInitial());
    try {
      chatsPagination = await apiService.getAllChats(event.endPoint);
      emit(ChatsLoaded(chatsPagination!));
    } catch (e) {
      emit(ChatsError(e.toString()));
    }
  }

  Future<void> _refetchChatsEvent(
      RefreshChats event, Emitter<ChatsState> emit) async {
    emit(ChatsInitial());
    try {
      chatsPagination = await apiService.getAllChats(endPoint);
      emit(ChatsLoaded(chatsPagination!));
    } catch (e) {
      emit(ChatsError(e.toString()));
    }
  }

  Future<void> _getNextPageChatsEvent(
      GetNextPageChats event, Emitter<ChatsState> emit) async {
    if (state is ChatsLoaded) {
      final state = this.state as ChatsLoaded;
      if (state.chatsPagination.currentPage !=
          state.chatsPagination.totalPage) {
        emit(ChatsLoading());
        try {
          chatsPagination = await apiService.getAllChats(
              endPoint, state.chatsPagination.currentPage + 1);
          emit(ChatsLoaded(chatsPagination!));
        } catch (e) {
          emit(ChatsError(e.toString()));
        }
      }
    }
  }

  Future<void> _updateChatsFromSocketFetch(
      UpdateChatsFromSocket event, Emitter<ChatsState> emit) async {
    try {
      chatsPagination = await apiService.getAllChats(endPoint);
      emit(ChatsInitial());
      emit(ChatsLoaded(chatsPagination!));
    } catch (e) {
      emit(ChatsError(e.toString()));
    }
  }
}

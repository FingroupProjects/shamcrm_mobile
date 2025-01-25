import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/pagination_dto.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
    on<DeleteChat>(_deleteChat);
    on<ClearChats>(_clearChatsEvent);
  }

  // Check for internet connection before making any API call
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  // Fetch chats with the internet connection check
  Future<void> _fetchChatsEvent(
      FetchChats event, Emitter<ChatsState> emit) async {
    endPoint = event.endPoint;
    emit(ChatsLoading());

    if (await _checkInternetConnection()) {
      try {
        chatsPagination = await apiService.getAllChats(event.endPoint, 1, event.query);
        emit(ChatsLoaded(chatsPagination!));
      } catch (e) {
        emit(ChatsError(e.toString()));
      }
    } else {
      emit(ChatsError('Нет подключения к интернету'));
    }
  }

  // Refetch chats with the internet connection check
  Future<void> _refetchChatsEvent(
      RefreshChats event, Emitter<ChatsState> emit) async {
    emit(ChatsInitial());

    if (await _checkInternetConnection()) {
      try {
        chatsPagination = await apiService.getAllChats(endPoint);
        emit(ChatsLoaded(chatsPagination!));
      } catch (e) {
        emit(ChatsError(e.toString()));
      }
    } else {
      emit(ChatsError('Нет подключения к интернету'));
    }
  }

  // Get next page chats with the internet connection check
  Future<void> _getNextPageChatsEvent(
      GetNextPageChats event, Emitter<ChatsState> emit) async {
    if (state is ChatsLoaded) {
      final state = this.state as ChatsLoaded;
      if (state.chatsPagination.currentPage != state.chatsPagination.totalPage) {
        emit(ChatsLoading());

        if (await _checkInternetConnection()) {
          try {
            chatsPagination = await apiService.getAllChats(
                endPoint, state.chatsPagination.currentPage + 1);
            emit(ChatsLoaded(chatsPagination!));
          } catch (e) {
            emit(ChatsError(e.toString()));
          }
        } else {
          emit(ChatsError('Нет подключения к интернету'));
        }
      }
    }
  }

  // Update chats from socket with the internet connection check
  Future<void> _updateChatsFromSocketFetch(
      UpdateChatsFromSocket event, Emitter<ChatsState> emit) async {
    if (await _checkInternetConnection()) {
      try {
        chatsPagination = await apiService.getAllChats(endPoint);
        emit(ChatsInitial());
        emit(ChatsLoaded(chatsPagination!));
      } catch (e) {
        emit(ChatsError(e.toString()));
      }
    } else {
      emit(ChatsError('Нет подключения к интернету'));
    }
  }

  // Delete a chat with the internet connection check
  Future<void> _deleteChat(DeleteChat event, Emitter<ChatsState> emit) async {
    emit(ChatsLoading());

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.deleteChat(event.chatId);
        if (response['result'] == true) {
          emit(ChatsDeleted(event.localizations.translate('chat_deleted_successfully')));
        } else {
          emit(ChatsError(event.localizations.translate('you_dont_delete_this_group')));
        }
      } catch (e) {
        emit(ChatsError(event.localizations.translate('error_delete_chat')));
      }
    } else {
      emit(ChatsError(event.localizations.translate('no_internet_connection')));
    }
  }

  // Clear the chats event
  Future<void> _clearChatsEvent(ClearChats event, Emitter<ChatsState> emit) async {
    emit(ChatsInitial());
    chatsPagination = null;
  }
}

part of 'chats_bloc.dart';

sealed class ChatsEvent extends Equatable {
  const ChatsEvent();

  @override
  List<Object?> get props => [];
}


class FetchChats extends ChatsEvent {
  final String endPoint;
  final String? query; 

  const FetchChats({required this.endPoint, this.query});

  @override
  List<Object?> get props => [endPoint, query];
}


class ClearChats extends ChatsEvent {
  const ClearChats();
}


class GetNextPageChats extends ChatsEvent {
  const GetNextPageChats();
}

class RefreshChats extends ChatsEvent {
  const RefreshChats();
}

class UpdateChatsFromSocket extends ChatsEvent {
  const UpdateChatsFromSocket();
}

class DeleteChat extends ChatsEvent {
    final int chatId;

  const DeleteChat(this.chatId);
}


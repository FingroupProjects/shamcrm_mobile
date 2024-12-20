part of 'chats_bloc.dart';

sealed class ChatsEvent extends Equatable {
  const ChatsEvent();
  
  @override
  List<Object> get props => [];
}

class FetchChats extends ChatsEvent {
  final String endPoint;
  const FetchChats({required this.endPoint});
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

class SearchChats extends ChatsEvent {
  final String query;
  final String endPoint; 
  
  const SearchChats(this.query, this.endPoint);  
}

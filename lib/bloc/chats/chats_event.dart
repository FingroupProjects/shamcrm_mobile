part of 'chats_bloc.dart';

abstract class ChatsEvent extends Equatable {
  const ChatsEvent();

  @override
  List<Object> get props => [];
}

class FetchChats extends ChatsEvent {
  final String endPoint;
  final String? query;

  const FetchChats({required this.endPoint, this.query});

  @override
  List<Object> get props => [endPoint, if (query != null) query!];
}

class RefreshChats extends ChatsEvent {}

class GetNextPageChats extends ChatsEvent {}

class UpdateChatsFromSocket extends ChatsEvent {}

class DeleteChat extends ChatsEvent {
  final int chatId;
  final AppLocalizations localizations;

  const DeleteChat(this.chatId, this.localizations);

  @override
  List<Object> get props => [chatId, localizations];
}

class ClearChats extends ChatsEvent {}
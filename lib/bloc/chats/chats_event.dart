part of 'chats_bloc.dart';

abstract class ChatsEvent extends Equatable {
  const ChatsEvent();

  @override
  List<Object> get props => [];
}

class FetchChats extends ChatsEvent {
  final String endPoint;
  final String? query;
  final int? salesFunnelId;
  final Map<String, dynamic>? filters;

  const FetchChats({
    required this.endPoint,
    this.query,
    this.salesFunnelId,
    this.filters,
  });

  @override
  List<Object> get props => [endPoint, query ?? '', salesFunnelId ?? 0, filters ?? {}];
}

class RefreshChats extends ChatsEvent {}

class GetNextPageChats extends ChatsEvent {}

class UpdateChatsFromSocket extends ChatsEvent {
  final Chats chat;

  const UpdateChatsFromSocket({required this.chat});

  @override
  List<Object> get props => [chat];
}

class DeleteChat extends ChatsEvent {
  final int chatId;
  final AppLocalizations localizations;

  const DeleteChat(this.chatId, this.localizations);

  @override
  List<Object> get props => [chatId, localizations];
}

class ClearChats extends ChatsEvent {}

class ResetUnreadCount extends ChatsEvent {
  final int chatId;

  const ResetUnreadCount(this.chatId);

  @override
  List<Object> get props => [chatId];
}
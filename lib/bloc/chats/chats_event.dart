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
  final Map<String, dynamic>? filters; // Новый параметр

  const FetchChats({
    required this.endPoint,
    this.query,
    this.salesFunnelId,
    this.filters,
  });

  @override
  List<Object> get props => [
        endPoint,
        if (query != null) query!,
        if (salesFunnelId != null) salesFunnelId!,
        if (filters != null) filters!,
      ];
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
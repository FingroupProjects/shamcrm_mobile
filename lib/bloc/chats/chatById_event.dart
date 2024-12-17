abstract class ChatByIdEvent {}

class FetchChatByIdEvent extends ChatByIdEvent {
  final int chatId;
  FetchChatByIdEvent({required this.chatId});
}

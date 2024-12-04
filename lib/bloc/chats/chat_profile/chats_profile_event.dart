import 'package:equatable/equatable.dart';

abstract class ChatProfileEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchChatProfile extends ChatProfileEvent {
  final int chatId;

  FetchChatProfile(this.chatId);

  @override
  List<Object> get props => [chatId];
}

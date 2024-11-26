import 'package:equatable/equatable.dart';

abstract class ChatProfileEvent extends Equatable {
  const ChatProfileEvent();

  @override
  List<Object> get props => [];
}

class FetchChatProfileEvent extends ChatProfileEvent {
  final int chatId;
  
  const FetchChatProfileEvent({required this.chatId});

  @override
  List<Object> get props => [chatId];
}
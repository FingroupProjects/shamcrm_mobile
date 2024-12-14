
import 'package:crm_task_manager/models/chats_model.dart';

abstract class ChatByIdState {}

class ChatByIdInitial extends ChatByIdState {}

class ChatByIdLoading extends ChatByIdState {}

class ChatByIdLoaded extends ChatByIdState {
  final Chats chat;
  ChatByIdLoaded(this.chat);
}

class ChatByIdError extends ChatByIdState {
  final String message;
  ChatByIdError(this.message);
}

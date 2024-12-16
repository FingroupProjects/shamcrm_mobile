

import 'package:crm_task_manager/models/chatGetId_model.dart';

abstract class ChatByIdState {}

class ChatByIdInitial extends ChatByIdState {}

class ChatByIdLoading extends ChatByIdState {}

class ChatByIdLoaded extends ChatByIdState {
  final ChatsGetId chat;
  ChatByIdLoaded(this.chat);
}

class ChatByIdError extends ChatByIdState {
  final String message;
  ChatByIdError(this.message);
}

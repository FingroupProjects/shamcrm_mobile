

import 'package:crm_task_manager/models/chatById_model.dart';

abstract class ChatByIdState {}

class ChatByIdInitial extends ChatByIdState {}

class ChatByIdLoading extends ChatByIdState {}

class ChatByIdLoaded extends ChatByIdState {
  final ChatById chat;
  ChatByIdLoaded(this.chat);
}

class ChatByIdError extends ChatByIdState {
  final String message;
  ChatByIdError(this.message);
}
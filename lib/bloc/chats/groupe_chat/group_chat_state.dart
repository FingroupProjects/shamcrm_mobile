abstract class GroupChatState {}

class GroupChatInitial extends GroupChatState {}

class GroupChatLoading extends GroupChatState {}

class GroupChatSuccess extends GroupChatState {
  final String message;

  GroupChatSuccess(this.message);
}

class GroupChatError extends GroupChatState {
  final String message;

  GroupChatError(this.message);
}

class GroupChatDeleted extends GroupChatState {
  final String message;

  GroupChatDeleted(this.message);
}

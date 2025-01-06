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

class AddUserToGroupLoading extends GroupChatState {}

class AddUserToGroupSuccess extends GroupChatState {
  final String message;

  AddUserToGroupSuccess(this.message);
}

class AddUserToGroupError extends GroupChatState {
  final String message;

  AddUserToGroupError(this.message);
}


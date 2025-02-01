part of 'messaging_cubit.dart';

sealed class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object> get props => [];
}

final class MessagingInitial extends MessagingState {}

final class MessagesLoadingState extends MessagingState {}

final class MessagesLoadedState extends MessagingState {
  final List<Message> messages;
  const MessagesLoadedState({required this.messages});
}

final class MessagesErrorState extends MessagingState {
  final String error;
  const MessagesErrorState({required this.error});
}

final class EditingMessageState extends MessagingState {
  final Message editingMessage;
  final List<Message> messages;
  final Message? pinnedMessage;

  const EditingMessageState({
    required this.editingMessage,
    required this.messages,
    this.pinnedMessage,
  });

  @override
  List<Object> get props => [editingMessage, messages, if (pinnedMessage != null) pinnedMessage!];
}

final class ReplyingToMessageState extends MessagingState {
  final Message replyingMessage;
  final List<Message> messages;
  final Message? pinnedMessage; 

  const ReplyingToMessageState({
    required this.replyingMessage,
    required this.messages,
    this.pinnedMessage, 
  });

  @override
  List<Object> get props => [replyingMessage, messages, if (pinnedMessage != null) pinnedMessage!];
}

final class PinnedMessageState extends MessagingState {
  final Message pinnedMessage;
  final List<Message> messages;

  const PinnedMessageState({
    required this.pinnedMessage,
    required this.messages,
  });

  @override
  List<Object> get props => [pinnedMessage, messages];
}
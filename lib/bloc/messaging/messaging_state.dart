part of 'messaging_cubit.dart';

sealed class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object?> get props => [];
}

final class MessagingInitial extends MessagingState {}

final class MessagesLoadingState extends MessagingState {}

final class MessagesLoadedState extends MessagingState {
  final List<Message> messages;

  const MessagesLoadedState({required this.messages});

  @override
  List<Object?> get props => [messages];
}

final class MessagesErrorState extends MessagingState {
  final String error;

  const MessagesErrorState({required this.error});

  @override
  List<Object?> get props => [error];
}

final class EditingMessageState extends MessagingState {
  final Message editingMessage;
  final List<Message> messages;
  final List<Message> pinnedMessages;

  const EditingMessageState({
    required this.editingMessage,
    required this.messages,
    required this.pinnedMessages,
  });

  @override
  List<Object?> get props => [editingMessage, messages, pinnedMessages];
}

final class ReplyingToMessageState extends MessagingState {
  final Message replyingMessage;
  final List<Message> messages;
  final List<Message> pinnedMessages;

  const ReplyingToMessageState({
    required this.replyingMessage,
    required this.messages,
    required this.pinnedMessages,
  });

  @override
  List<Object?> get props => [replyingMessage, messages, pinnedMessages];
}

final class PinnedMessagesState extends MessagingState {
  final List<Message> pinnedMessages;
  final List<Message> messages;

  const PinnedMessagesState({
    required this.pinnedMessages,
    required this.messages,
  });

  @override
  List<Object?> get props => [pinnedMessages, messages];
}

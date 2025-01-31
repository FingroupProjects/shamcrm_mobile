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

final class ReplyingToMessageState extends MessagingState {
  final Message replyingMessage;
  final List<Message> messages; // Добавлено поле для сообщений

  const ReplyingToMessageState({
    required this.replyingMessage,
    required this.messages,
  });

  @override
  List<Object> get props => [replyingMessage, messages];
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
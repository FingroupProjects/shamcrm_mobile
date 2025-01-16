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

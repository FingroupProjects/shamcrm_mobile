part of 'chats_bloc.dart';

sealed class ChatsState extends Equatable {
  const ChatsState();

  @override
  List<Object> get props => [];
}

class ChatsInitial extends ChatsState {}

class ChatsLoading extends ChatsState {}

class ChatsLoaded extends ChatsState {
  final PaginationDTO<Chats> chatsPagination;
  const ChatsLoaded(this.chatsPagination);

  @override
  List<Object> get props => [chatsPagination];
}

class ChatsError extends ChatsState {
  final String message;

  const ChatsError(this.message);

  @override
  List<Object> get props => [message];
}

class ChatsDeleted extends ChatsState {
  final String message;

  ChatsDeleted(this.message);
}
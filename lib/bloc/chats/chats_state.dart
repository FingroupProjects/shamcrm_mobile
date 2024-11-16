part of 'chats_bloc.dart';

sealed class ChatsState extends Equatable {
  const ChatsState();
  
  @override
  List<Object> get props => [];
}

class ChatsInitial extends ChatsState {}

class ChatsLoading extends ChatsState {}

class ChatsLoaded extends ChatsState{
  final List<Chats> chats;

  const ChatsLoaded(this.chats);

  @override  
  List<Object> get props => [chats];
}

class ChatsError extends ChatsState {
  final String message;


  const ChatsError(this.message);

  @override  
  List<Object> get props => [message];

  
}


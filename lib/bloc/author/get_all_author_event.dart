part of 'get_all_author_bloc.dart';

@immutable
sealed class GetAllAuthorEvent {}

class GetAllAuthorEv extends GetAllAuthorEvent {}
class GetAnotherAuthorEv extends GetAllAuthorEvent {}
class GetAuthorsWithoutCorporateChatEv extends GetAllAuthorEvent {}

class GetAuthorsNotInChatEv extends GetAllAuthorEvent {
  final String chatId;

  GetAuthorsNotInChatEv(this.chatId);
}
part of 'get_all_client_bloc.dart';

@immutable
sealed class GetAllClientEvent {}

class GetAllClientEv extends GetAllClientEvent {}
class GetAnotherClientEv extends GetAllClientEvent {}
class GetUsersWithoutCorporateChatEv extends GetAllClientEvent {}

class GetUsersNotInChatEv extends GetAllClientEvent {
  final String chatId;

  GetUsersNotInChatEv(this.chatId);
}
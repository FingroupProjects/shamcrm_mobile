part of 'create_client_bloc.dart';

@immutable
sealed class CreateClientEvent {}
class CreateClientEv extends CreateClientEvent {
  final String userId;

  CreateClientEv({required this.userId});
}


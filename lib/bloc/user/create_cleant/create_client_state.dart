part of 'create_client_bloc.dart';

@immutable
sealed class CreateClientState {}

final class CreateClientInitial extends CreateClientState {}
final class CreateClientLoading extends CreateClientState {}
final class CreateClientError extends CreateClientState {
  final String message;

  CreateClientError({required this.message});
}

final class CreateClientSuccess extends CreateClientState {
  final int chatId; // Новый параметр для chatId

  CreateClientSuccess({required this.chatId});
}

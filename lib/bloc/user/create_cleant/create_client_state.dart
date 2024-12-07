part of 'create_client_bloc.dart';

@immutable
sealed class CreateClientState {}

final class CreateClientInitial extends CreateClientState {}
final class CreateClientLoading extends CreateClientState {}
final class CreateClientError extends CreateClientState {
  String message;
  CreateClientError({required this.message});
}
final class CreateClientSuccess extends CreateClientState {}

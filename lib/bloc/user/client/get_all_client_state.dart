part of 'get_all_client_bloc.dart';

@immutable
sealed class GetAllClientState {}

final class GetAllClientInitial extends GetAllClientState {}
final class GetAllClientLoading extends GetAllClientState {}
final class GetAllClientError extends GetAllClientState {
  final String message;

  GetAllClientError({required this.message});
}
final class GetAllClientSuccess extends GetAllClientState {
  final UsersDataResponse dataUser;

  GetAllClientSuccess({required this.dataUser});
}


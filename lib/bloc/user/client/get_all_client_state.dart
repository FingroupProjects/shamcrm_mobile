part of 'get_all_client_bloc.dart';

@immutable
sealed class GetAllClientState {}

final class GetAllClientInitial extends GetAllClientState {}
final class GetAllClientLoading extends GetAllClientState {

}
final class GetAllClientError extends GetAllClientState {
  String message;

  GetAllClientError({required this.message});

}
final class GetAllClientSuccess extends GetAllClientState {
  UsersDataResponse dataUser;

  GetAllClientSuccess({required this.dataUser});
}

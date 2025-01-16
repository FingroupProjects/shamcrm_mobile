part of 'manager_bloc.dart';

@immutable
sealed class GetAllManagerState {}

final class GetAllManagerInitial extends GetAllManagerState {}
final class GetAllManagerLoading extends GetAllManagerState {

}
final class GetAllManagerError extends GetAllManagerState {
  String message;

  GetAllManagerError({required this.message});

}
final class GetAllManagerSuccess extends GetAllManagerState {
  ManagersDataResponse dataManager;

  GetAllManagerSuccess({required this.dataManager});
}

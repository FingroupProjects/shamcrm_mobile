part of 'lead_multi_bloc.dart';

@immutable
sealed class GetAllLeadState {}

final class GetAllLeadInitial extends GetAllLeadState {}
final class GetAllLeadLoading extends GetAllLeadState {

}
final class GetAllLeadError extends GetAllLeadState {
  String message;

  GetAllLeadError({required this.message});

}
final class GetAllLeadSuccess extends GetAllLeadState {
  LeadsMultiDataResponse dataLead;

  GetAllLeadSuccess({required this.dataLead});
}

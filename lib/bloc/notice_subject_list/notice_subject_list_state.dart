import 'package:crm_task_manager/models/notice_subject_model.dart';

sealed class GetAllSubjectState {}
final class GetAllSubjectInitial extends GetAllSubjectState {}
final class GetAllSubjectLoading extends GetAllSubjectState {}
final class GetAllSubjectError extends GetAllSubjectState {
  String message;
  GetAllSubjectError({required this.message});
}
final class GetAllSubjectSuccess extends GetAllSubjectState {
  SubjectDataResponse dataSubject;
  GetAllSubjectSuccess({required this.dataSubject});
}
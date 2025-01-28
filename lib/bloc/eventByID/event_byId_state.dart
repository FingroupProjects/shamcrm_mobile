import 'package:crm_task_manager/models/event_by_Id_model.dart';

abstract class NoticeState {}

class NoticeInitial extends NoticeState {}

class NoticeLoading extends NoticeState {}

class NoticeLoaded extends NoticeState {
  final Notice notice;
  NoticeLoaded(this.notice);
}

class NoticeError extends NoticeState {
  final String message;
  NoticeError(this.message);
}
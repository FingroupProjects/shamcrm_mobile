import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class EventEvent {}

class FetchEvents extends EventEvent {
  final bool refresh;
  FetchEvents({this.refresh = false});
}

class FetchMoreEvents extends EventEvent {
  FetchMoreEvents(int currentPage);
}

class CreateNotice extends EventEvent {
  final String title;
  final String body;
  final int leadId;
  final DateTime date;
  final int sendNotification;
  final List<int> users;
  final AppLocalizations localizations;

  CreateNotice({
    required this.title,
    required this.body,
    required this.leadId,
    required this.date,
    required this.sendNotification,
    required this.users,
    required this.localizations,
  });
}

class UpdateNotice extends EventEvent {
  final int noticeId;
  final String title;
  final String body;
  final int leadId;
  final DateTime date;
  final int sendNotification;
  final List<int> users;
  final AppLocalizations localizations;

  UpdateNotice({
    required this.noticeId,
    required this.title,
    required this.body,
    required this.leadId,
    required this.date,
    required this.sendNotification,
    required this.users,
    required this.localizations,
  });
}

class DeleteNotice extends EventEvent {
  final int noticeId;
  final AppLocalizations localizations;

  DeleteNotice(this.noticeId, this.localizations);
}
class FinishNotice extends EventEvent {
  final int noticeId;
  final AppLocalizations localizations;

  FinishNotice(this.noticeId, this.localizations);
}
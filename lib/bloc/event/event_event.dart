import 'package:crm_task_manager/models/event/event_by_Id_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class EventEvent {}

class FetchEvents extends EventEvent {
  final bool refresh;
  final String? query;
  final List<int>? managerIds;
  /// past | today | tomorrow | upcoming. null — берём последний открытый интервал.
  final String? dateType;
  final DateTime? fromDate; 
  final DateTime? toDate; 
  final DateTime? noticefromDate; 
  final DateTime? noticetoDate; 
  final int? salesFunnelId;
  final bool forceRefresh;

  FetchEvents({
    this.refresh = false,
    this.query,
    this.managerIds,
    this.dateType,
    this.fromDate,
    this.toDate,
    this.noticefromDate,
    this.noticetoDate,
    this.salesFunnelId,
    this.forceRefresh = false,
  });
}

class FetchEventsWithFilters extends EventEvent {
  final List<int>? managerIds;
  final String? dateType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final DateTime? noticefromDate;
  final DateTime? noticetoDate;
  final int? salesFunnelId;

  FetchEventsWithFilters({
    this.managerIds,
    this.dateType,
    this.fromDate,
    this.toDate,
    this.noticefromDate,
    this.noticetoDate,
    this.salesFunnelId,
  });
}


class FetchMoreEvents extends EventEvent {
  final int currentPage;
  final String? query;
  final List<int>? managerIds;
  final String? dateType;

  FetchMoreEvents(
    this.currentPage, {
    this.query,
    this.managerIds,
    this.dateType,
  });
}
class CreateNotice extends EventEvent {
  final String? title;
  final String body;
  final int leadId;
  final DateTime? date;
  final String? timeFrom;
  final String? timeTo;
  final int sendNotification;
  final int sendSms;
  final List<int> users;
  final List<String>? filePaths; // Новое поле для файлов
  final AppLocalizations localizations;

  CreateNotice({
    required this.title,
    required this.body,
    required this.leadId,
    this.date,
    this.timeFrom,
    this.timeTo,
    required this.sendNotification,
    required this.sendSms,
    required this.users,
    this.filePaths, // Добавляем в конструктор
    required this.localizations,
  });
}

class UpdateNotice extends EventEvent {
  final int noticeId;
  final String? title;
  final String body;
  final int leadId;
  final DateTime? date;
  final String? timeFrom;
  final String? timeTo;
  final int sendNotification;
  final int sendSms;
  final List<int> users;
  final AppLocalizations localizations;
  final List<String>? filePaths; // Новое поле для новых файлов
  final List<NoticeFiles> existingFiles; // Существующие файлы

  UpdateNotice({
    required this.noticeId,
     this.title,
    required this.body,
    required this.leadId,
   this.date,
    this.timeFrom,
    this.timeTo,
    required this.sendNotification,
    required this.sendSms,
    required this.users,
    required this.localizations,
    this.filePaths, // Добавляем
    required this.existingFiles, // Добавляем
  });
}

class DeleteNotice extends EventEvent {
  final int noticeId;
  final AppLocalizations localizations;

  DeleteNotice(this.noticeId, this.localizations);
}
class FinishNotice extends EventEvent {
  final int noticeId;
  final String conclusion;
  final AppLocalizations localizations;

  FinishNotice(this.noticeId, this.conclusion, this.localizations);
}

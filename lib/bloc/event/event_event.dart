import 'package:crm_task_manager/models/event_by_Id_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class EventEvent {}

class FetchEvents extends EventEvent {
  final bool refresh;
  final String? query;
  final List<int>? managerIds; 
  final int? statusIds; 
  final DateTime? fromDate; 
  final DateTime? toDate; 
  final DateTime? noticefromDate; 
  final DateTime? noticetoDate; 
  final int? salesFunnelId; // Новый параметр

  FetchEvents({
    this.refresh = false,
    this.query,
    this.managerIds,
    this.statusIds,
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

  FetchMoreEvents(this.currentPage, {this.query, this.managerIds});
}
class CreateNotice extends EventEvent {
  final String? title;
  final String body;
  final int leadId;
  final DateTime? date;
  final int sendNotification;
  final List<int> users;
  final List<String>? filePaths; // Новое поле для файлов
  final AppLocalizations localizations;

  CreateNotice({
    required this.title,
    required this.body,
    required this.leadId,
    this.date,
    required this.sendNotification,
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
  final int sendNotification;
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
    required this.sendNotification,
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
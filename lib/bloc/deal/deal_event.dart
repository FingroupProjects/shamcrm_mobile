import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/file_helper.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class DealEvent {}

 class FetchDealStatuses extends DealEvent {
  final int? salesFunnelId; // Добавляем параметр

  FetchDealStatuses({this.salesFunnelId});
}

  class FetchDeals extends DealEvent {
    final int statusId;
    final String? query;
    final List<int>? managerIds;
    final List<int>? leadIds;
    final int? statusIds;
    final DateTime? fromDate;
    final DateTime? toDate;
    final int? daysWithoutActivity;
    final bool? hasTasks;
    final int? salesFunnelId;
    final List<Map<String, dynamic>>? directoryValues; // Добавляем directory_values
    final List<String>? names; // Новое поле
    final Map<String, List<String>>? customFieldFilters; // Новое поле

    FetchDeals(
      this.statusId, {
      this.query,
      this.managerIds,
      this.leadIds,
      this.statusIds,
      this.fromDate,
      this.toDate,
      this.daysWithoutActivity,
      this.hasTasks,
      this.directoryValues,
      this.salesFunnelId,
      this.names,
      this.customFieldFilters,

    });
  }

  class FetchDealStatus extends DealEvent {
    final int dealStatusId;
    FetchDealStatus(this.dealStatusId);
  }

  class FetchMoreDeals extends DealEvent {
    final int statusId;
    final int currentPage;

    FetchMoreDeals(this.statusId, this.currentPage);
  }
class CreateDealStatus extends DealEvent {
  final String title;
  final int? day;
  final String color;
  final String? notificationMessage;
  final bool showOnMainPage;
  final bool isSuccess;
  final bool isFailure;
  final AppLocalizations localizations;
  final List<int>? userIds;
  final List<int>? changeStatusUserIds; // ✅ НОВОЕ

  CreateDealStatus({
    required this.title,
    this.day,
    required this.color,
    this.notificationMessage,
    required this.showOnMainPage,
    required this.isSuccess,
    required this.isFailure,
    required this.localizations,
    this.userIds,
    this.changeStatusUserIds, // ✅ НОВОЕ
  });
}

class CreateDeal extends DealEvent {
  final String name;
  final int dealStatusId;
  final int? managerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sum;
  final String? description;
  final int? dealtypeId;
  final int? leadId;
  final List<Map<String, dynamic>>? customFields;
  final List<Map<String, int>>? directoryValues;
  final List<FileHelper>? files; // Новое поле для файлов
  final List<int>? userIds; // ✅ НОВОЕ
  final AppLocalizations localizations;

  CreateDeal({
    required this.name,
    required this.dealStatusId,
    this.managerId,
    this.startDate,
    this.endDate,
    required this.sum,
    this.description,
    this.dealtypeId,
    this.leadId,
    this.customFields,
    this.directoryValues,
    this.userIds, // ✅ НОВОЕ
    this.files, // Добавляем в конструктор
    required this.localizations,
  });
}
class UpdateDeal extends DealEvent {
  final int dealId;
  final String name;
  final int dealStatusId;
  final int? managerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? sum;
  final String? description;
  final int? dealtypeId;
  final int? leadId;
  final List<Map<String, dynamic>>? customFields; // Изменён тип
  final List<Map<String, int>>? directoryValues;
  final AppLocalizations localizations;
  final List<int>? dealStatusIds; // ✅ НОВОЕ: массив ID статусов
  final List<FileHelper>? files; // Новые файлы (id == 0)
  final List<int>? existingFiles; // ID существующих файлов (id != 0)
  final List<int>? userIds; // ✅ НОВОЕ: массив ID пользователей


  UpdateDeal({
    required this.dealId,
    required this.name,
    required this.dealStatusId,
    this.managerId,
    this.startDate,
    this.endDate,
    this.sum,
    this.description,
    this.dealtypeId,
    this.leadId,
    this.customFields,
    this.directoryValues,
    required this.localizations,
    this.files,
    this.dealStatusIds, // ✅ НОВОЕ
    this.existingFiles, // ID существующих файлов
    this.userIds, // ✅ НОВОЕ
  });
}

class DeleteDeal extends DealEvent {
  final int dealId;
   final AppLocalizations localizations; 

  DeleteDeal(
    this.dealId,
     this.localizations,
    );
}

class DeleteDealStatuses extends DealEvent {
  final int dealStatusId;
   final AppLocalizations localizations; 

  DeleteDealStatuses(
    this.dealStatusId,
    this.localizations,
    );
}
// Event для изменения статуса лида
class UpdateDealStatusEdit extends DealEvent {
  final int dealStatusId;
  final String title;
  final int day;
  final bool isSuccess;
  final bool isFailure;
  final String notificationMessage;
  final bool showOnMainPage;
  final AppLocalizations localizations;
  final List<int>? userIds;
  final List<int>? changeStatusUserIds; // ✅ НОВОЕ

  UpdateDealStatusEdit(
    this.dealStatusId,
    this.title,
    this.day,
    this.isSuccess,
    this.isFailure,
    this.notificationMessage,
    this.showOnMainPage,
    this.localizations,
    this.userIds,
    this.changeStatusUserIds, // ✅ НОВОЕ
  );
}
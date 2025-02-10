import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class DealEvent {}

class FetchDealStatuses extends DealEvent {}

class FetchDeals extends DealEvent {
  final int statusId;
  final String? query;
  final List<int>? managerIds; 
  final int? statusIds; 
  final DateTime? fromDate; 
  final DateTime? toDate; 

  FetchDeals(
    this.statusId, {
    this.query,
    this.managerIds,
    this.statusIds,
    this.fromDate,
    this.toDate,
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
   final AppLocalizations localizations; 

  CreateDealStatus({
    required this.title,
    this.day,
    required this.color,
    required this.localizations
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
  final List<Map<String, String>>? customFields;
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
  final String sum;
  final String? description;
  final int? dealtypeId;
  final int? leadId;
  final List<Map<String, String>>? customFields;
   final AppLocalizations localizations; 

  UpdateDeal({
    required this.dealId,
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
    required this.localizations,
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
  final AppLocalizations localizations;

  UpdateDealStatusEdit(
    this.dealStatusId,
    this.title,
    this.day,
    this.isSuccess,
    this.isFailure,
    this.localizations,
  );
}

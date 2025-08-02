import 'package:crm_task_manager/models/leadById_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class LeadEvent {}

class FetchLeadStatuses extends LeadEvent {}

class FetchLeads extends LeadEvent {
  final int statusId;
  final String? query;
  final List<int>? managerIds;
  final List<int>? regionsIds;
  final List<int>? sourcesIds;
  final int? statusIds;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool? hasSuccessDeals;
  final bool? hasInProgressDeals;
  final bool? hasFailureDeals;
  final bool? hasNotices;
  final bool? hasContact;
  final bool? hasChat;
  final bool? hasNoReplies;
  final bool? hasUnreadMessages;
  final bool? hasDeal;
  final int? daysWithoutActivity;
  final List<Map<String, dynamic>>? directoryValues;
  final int? salesFunnelId;
  final bool ignoreCache; // Новый параметр

  FetchLeads(
    this.statusId, {
    this.query,
    this.managerIds,
    this.regionsIds,
    this.sourcesIds,
    this.statusIds,
    this.fromDate,
    this.toDate,
    this.hasSuccessDeals,
    this.hasInProgressDeals,
    this.hasFailureDeals,
    this.hasNotices,
    this.hasContact,
    this.hasChat,
    this.hasNoReplies,
    this.hasUnreadMessages,
    this.hasDeal,
    this.daysWithoutActivity,
    this.directoryValues,
    this.salesFunnelId,
    this.ignoreCache = false, // По умолчанию кэш используется
  });
}

class FetchLeadStatus extends LeadEvent {
  final int leadStatusId;
  FetchLeadStatus(this.leadStatusId);
}

class FetchMoreLeads extends LeadEvent {
  final int statusId;
  final int currentPage;

  FetchMoreLeads(this.statusId, this.currentPage);
}

class UpdateLeadCounts extends LeadEvent {
  final int statusId;
  final int count;

  UpdateLeadCounts(this.statusId, this.count);
}

class FetchAllLeads extends LeadEvent {}

class CreateLeadStatus extends LeadEvent {
  final String title;
  final String color;
  final AppLocalizations localizations;
  final bool? isSuccess;
  final bool? isFailure;

  CreateLeadStatus({
    required this.title,
    required this.color,
    required this.localizations,
    this.isSuccess,
    this.isFailure,
  });
}

class CreateLead extends LeadEvent {
  final String name;
  final int leadStatusId;
  final String phone;
  final int? regionId;
  final int? managerId;
  final int? sourceId;
  final String? instaLogin;
  final String? facebookLogin;
  final String? tgNick;
  final DateTime? birthday;
  final String? email;
  final String? description;
  final String? waPhone;
  final List<Map<String, dynamic>>? customFields; // Изменяем тип
  final List<Map<String, int>>? directoryValues;
  final List<String>? filePaths;
  final AppLocalizations localizations;
  final bool isSystemManager;

  CreateLead({
    required this.name,
    required this.leadStatusId,
    required this.phone,
    this.regionId,
    this.managerId,
    this.sourceId,
    this.instaLogin,
    this.facebookLogin,
    this.tgNick,
    this.birthday,
    this.email,
    this.description,
    this.waPhone,
    this.customFields,
    this.directoryValues,
    this.filePaths,
    this.isSystemManager = false,
    required this.localizations,
  });
}
class UpdateLead extends LeadEvent {
  final int leadId;
  final String name;
  final int leadStatusId;
  final String phone;
  final int? regionId;
  final int? sourseId;
  final int? managerId;
  final String? instaLogin;
  final String? facebookLogin;
  final String? tgNick;
  final DateTime? birthday;
  final String? email;
  final String? description;
  final String? waPhone;
  final List<Map<String, dynamic>>? customFields; // Изменён тип
  final List<Map<String, int>>? directoryValues;
  final List<String>? filePaths;
  final bool isSystemManager;
  final AppLocalizations localizations;
  final List<LeadFiles> existingFiles;
  final String? priceTypeId; // Новое поле

  UpdateLead({
    required this.leadId,
    required this.name,
    required this.leadStatusId,
    required this.phone,
    this.regionId,
    this.sourseId,
    this.managerId,
    this.instaLogin,
    this.facebookLogin,
    this.tgNick,
    this.birthday,
    this.email,
    this.description,
    this.waPhone,
    this.customFields,
    this.directoryValues,
    this.filePaths,
    required this.localizations,
    this.isSystemManager = false,
    required this.existingFiles,
    this.priceTypeId,
  });
}


class DeleteLead extends LeadEvent {
  final int leadId;
  final AppLocalizations localizations;

  DeleteLead(
    this.leadId,
    this.localizations,
  );
}

class DeleteLeadStatuses extends LeadEvent {
  final int leadStatusId;
  final AppLocalizations localizations;

  DeleteLeadStatuses(
    this.leadStatusId,
    this.localizations,
  );
}

class UpdateLeadStatusEdit extends LeadEvent {
  final int leadStatusId;
  final String title;
  final bool isSuccess;
  final bool isFailure;
  final AppLocalizations localizations;

  UpdateLeadStatusEdit(
    this.leadStatusId,
    this.title,
    this.isSuccess,
    this.isFailure,
    this.localizations,
  );
}

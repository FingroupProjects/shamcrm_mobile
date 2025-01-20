abstract class LeadEvent {}

class FetchLeadStatuses extends LeadEvent {}

class FetchLeads extends LeadEvent {
  final int statusId;
  final String? query;
  final List<int>? managerIds; // Изменено: массив менеджеров

  FetchLeads(
    this.statusId, {
    this.query,
    this.managerIds,
  });
}


class FetchMoreLeads extends LeadEvent {
  final int statusId;
  final int currentPage;

  FetchMoreLeads(this.statusId, this.currentPage);
}

// Новое событие для обновления количества лидов
class UpdateLeadCounts extends LeadEvent {
  final int statusId;
  final int count;

  UpdateLeadCounts(this.statusId, this.count);
}

class FetchAllLeads extends LeadEvent {}

class CreateLeadStatus extends LeadEvent {
  final String title;
  final String color;

  CreateLeadStatus({
    required this.title,
    required this.color,
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
  final List<Map<String, String>>? customFields;

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
  final List<Map<String, String>>? customFields;

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
  });
}

class DeleteLead extends LeadEvent {
  final int leadId;

  DeleteLead(this.leadId);
}

class DeleteLeadStatuses extends LeadEvent {
  final int leadStatusId;

  DeleteLeadStatuses(this.leadStatusId);
}

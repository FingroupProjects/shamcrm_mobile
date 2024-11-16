abstract class LeadEvent {}

class FetchLeadStatuses extends LeadEvent {}

class FetchLeads extends LeadEvent {
  final int statusId;
  final String? query; // Добавьте параметр для поиска

  FetchLeads(this.statusId, {this.query});
}

class FetchMoreLeads extends LeadEvent {
  final int statusId;
  final int currentPage;

  FetchMoreLeads(this.statusId, this.currentPage);
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
  final String? instaLogin;
  final String? facebookLogin;
  final String? tgNick;
  final DateTime? birthday;
  final String? description;
  final int? organizationId;
  final String? waPhone;

  CreateLead({
    required this.name,
    required this.leadStatusId,
    required this.phone,
    this.regionId,
    this.managerId,
    this.instaLogin,
    this.facebookLogin,
    this.tgNick,
    this.birthday,
    this.description,
    this.organizationId,
    this.waPhone,
  });
}
class UpdateLead extends LeadEvent {
  final int leadId;
  final String name;
  final int leadStatusId;
  final String phone;
  final int? regionId;
  final int? managerId;
  final String? instaLogin;
  final String? facebookLogin;
  final String? tgNick;
  final DateTime? birthday;
  final String? description;
  final int? organizationId;
  final String? waPhone;

  UpdateLead({
    required this.leadId,
    required this.name,
    required this.leadStatusId,
    required this.phone,
    this.regionId,
    this.managerId,
    this.instaLogin,
    this.facebookLogin,
    this.tgNick,
    this.birthday,
    this.description,
    this.organizationId,
    this.waPhone,
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
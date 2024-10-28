abstract class LeadEvent {}

class FetchLeadStatuses extends LeadEvent {}

class FetchLeads extends LeadEvent {
  final int statusId;

  FetchLeads(this.statusId);
}

class FetchMoreLeads extends LeadEvent {
  final int statusId;
  final int currentPage;

  FetchMoreLeads(this.statusId, this.currentPage);
}

class CreateLead extends LeadEvent {
  final String name;
  final int leadStatusId;
  final String phone;
  final int? regionId;
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
    this.instaLogin,
    this.facebookLogin,
    this.tgNick,
    this.birthday,
    this.description,
    this.organizationId,
    this.waPhone,
  });
}

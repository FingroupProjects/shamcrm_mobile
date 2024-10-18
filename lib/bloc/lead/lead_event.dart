abstract class LeadEvent {}

class FetchLeadStatuses extends LeadEvent {}

class FetchLeads extends LeadEvent {}

class CreateLead extends LeadEvent {
  final String name;
  final int leadStatusId;
  final String phone;
  final int? regionId; // добавлено
  final String? instaLogin; // добавлено
  final String? facebookLogin; // добавлено
  final String? tgNick; // добавлено
  final DateTime? birthday; // добавлено
  final String? description; // добавлено
  final int? organizationId; // добавлено
  final String? waPhone; // добавлено

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

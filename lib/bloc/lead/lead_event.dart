abstract class LeadEvent {}

class FetchLeadStatuses extends LeadEvent {}

class FetchLeads extends LeadEvent {}

class CreateLead extends LeadEvent {
  final String name;
  final int leadStatusId;
  final String phone;

  CreateLead({required this.name, required this.leadStatusId, required this.phone});
}

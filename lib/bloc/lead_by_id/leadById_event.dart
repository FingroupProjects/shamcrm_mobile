abstract class LeadByIdEvent {}

class FetchLeadByIdEvent extends LeadByIdEvent {
  final int leadId;
  FetchLeadByIdEvent({required this.leadId});
}

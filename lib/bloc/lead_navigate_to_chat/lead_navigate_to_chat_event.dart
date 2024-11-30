abstract class LeadToChatEvent {}

class FetchLeadToChat extends LeadToChatEvent {
  final int leadId;

  FetchLeadToChat(this.leadId);
}

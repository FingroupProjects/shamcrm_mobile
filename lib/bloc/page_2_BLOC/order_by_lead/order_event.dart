abstract class OrderByLeadEvent {}

class FetchOrdersByLead extends OrderByLeadEvent {
  final int leadId;
  final int page;
  final int perPage;

  FetchOrdersByLead({
    required this.leadId,
    this.page = 1,
    this.perPage = 20,
  });
}
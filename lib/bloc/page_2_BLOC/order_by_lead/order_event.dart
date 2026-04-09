abstract class OrderByLeadEvent {}

class FetchOrdersByLead extends OrderByLeadEvent {
  final int entityId;
  final String relationType;
  final int page;
  final int perPage;

  FetchOrdersByLead({
    required this.entityId,
    this.relationType = 'lead',
    this.page = 1,
    this.perPage = 20,
  });
}

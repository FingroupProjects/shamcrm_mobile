abstract class DealByIdEvent {}

class FetchDealByIdEvent extends DealByIdEvent {
  final int dealId;
  FetchDealByIdEvent({required this.dealId});
}

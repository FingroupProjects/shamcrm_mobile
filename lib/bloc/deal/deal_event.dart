abstract class DealEvent {}

class FetchDealStatuses extends DealEvent {}

class FetchDeals extends DealEvent {
  final int statusId;

  FetchDeals(this.statusId);
}

class FetchMoreDeals extends DealEvent {
  final int statusId;
  final int currentPage;

  FetchMoreDeals(this.statusId, this.currentPage);
}

class CreateDealStatus extends DealEvent {
  final String title;
  final String color;

  CreateDealStatus({
    required this.title,
    required this.color,
  });
}
class CreateDeal extends DealEvent {
  final String name;
  final int dealStatusId;
  final int? managerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sum;
  final String? description;
  final int? organizationId;
  final int? dealtypeId;
  final int? leadId;         
  final int? currencyId;     
  final List<Map<String, String>>? customFields;

  CreateDeal({
    required this.name,
    required this.dealStatusId,
    this.managerId,
    this.startDate,
    this.endDate,
    required this.sum,
    this.description,
    this.organizationId,
    this.dealtypeId,
    this.leadId,             
    this.currencyId,         
    this.customFields,
  });
}




class UpdateDeal extends DealEvent {
  final int dealId;
  final String name;
  final int dealStatusId;
  final int? managerId;
  final String? description;
  final int? organizationId;

  UpdateDeal({
    required this.dealId,
    required this.name,
    required this.dealStatusId,
    this.managerId,
    this.description,
    this.organizationId,
  });
}

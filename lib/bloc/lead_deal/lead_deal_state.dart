import 'package:crm_task_manager/models/lead_deal_model.dart';

abstract class LeadDealsState {}

class LeadDealsInitial extends LeadDealsState {}

class LeadDealsLoading extends LeadDealsState {}

class LeadDealsLoaded extends LeadDealsState {
  final List<LeadDeal> deals;
  final int currentPage;

  LeadDealsLoaded(this.deals, {this.currentPage = 1});

  LeadDealsLoaded merge(List<LeadDeal> newLeadDeals) {
    return LeadDealsLoaded([...deals, ...newLeadDeals], currentPage: currentPage + 1);
  }
}

class LeadDealsError extends LeadDealsState {
  final String message;

  LeadDealsError(this.message);
}

class LeadDealsSuccess extends LeadDealsState {
  final String message;

  LeadDealsSuccess(this.message);
}

class LeadDealsDeleted extends LeadDealsState {
  final String message;

  LeadDealsDeleted(this.message);
}

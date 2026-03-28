

import 'package:crm_task_manager/models/page_2/lead_order_model.dart';

abstract class LeadOrderState {}

class LeadOrderInitial extends LeadOrderState {}

class LeadOrderLoading extends LeadOrderState {}

class LeadOrderLoaded extends LeadOrderState {
  final List<LeadOrderData> leadOrders;

  LeadOrderLoaded({required this.leadOrders});
}

class LeadOrderError extends LeadOrderState {
  final String message;

  LeadOrderError(this.message);
}
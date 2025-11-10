import 'package:crm_task_manager/models/page_2/order_card.dart';

abstract class OrderByLeadState {}

class OrderByLeadInitial extends OrderByLeadState {}

class OrderByLeadLoading extends OrderByLeadState {}

class OrderByLeadLoaded extends OrderByLeadState {
  final List<Order> orders;
  final Pagination pagination;

  OrderByLeadLoaded({
    required this.orders,
    required this.pagination,
  });
}

class OrderByLeadError extends OrderByLeadState {
  final String message;

  OrderByLeadError(this.message);
}
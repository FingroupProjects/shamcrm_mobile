import 'package:crm_task_manager/models/page_2/order_history_model.dart';
import 'package:equatable/equatable.dart';

abstract class OrderHistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<OrderHistory> orderHistory;

  OrderHistoryLoaded(this.orderHistory);

  @override
  List<Object?> get props => [orderHistory];
}

class OrderHistoryError extends OrderHistoryState {
  final String message;

  OrderHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
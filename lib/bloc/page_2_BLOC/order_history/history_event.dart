import 'package:equatable/equatable.dart';

abstract class OrderHistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchOrderHistory extends OrderHistoryEvent {
  final int orderId;

  FetchOrderHistory(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
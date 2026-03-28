import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:equatable/equatable.dart';

abstract class SalesFunnelEvent extends Equatable {
  const SalesFunnelEvent();

  @override
  List<Object> get props => [];
}

class FetchSalesFunnels extends SalesFunnelEvent {}

class SelectSalesFunnel extends SalesFunnelEvent {
  final SalesFunnel funnel;

  const SelectSalesFunnel(this.funnel);

  @override
  List<Object> get props => [funnel];
}
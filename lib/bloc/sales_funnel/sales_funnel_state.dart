import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:equatable/equatable.dart';

abstract class SalesFunnelState extends Equatable {
  const SalesFunnelState();

  @override
  List<Object> get props => [];
}

class SalesFunnelInitial extends SalesFunnelState {}

class SalesFunnelLoading extends SalesFunnelState {}

class SalesFunnelLoaded extends SalesFunnelState {
  final List<SalesFunnel> funnels;
  final SalesFunnel? selectedFunnel;

  const SalesFunnelLoaded({required this.funnels, this.selectedFunnel});

  @override
  List<Object> get props => [funnels, selectedFunnel ?? []];
}

class SalesFunnelError extends SalesFunnelState {
  final String message;

  const SalesFunnelError(this.message);

  @override
  List<Object> get props => [message];
}
import 'package:crm_task_manager/models/sales_plan/sales_plan_filter.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:equatable/equatable.dart';

abstract class SalesPlanEvent extends Equatable {
  const SalesPlanEvent();

  @override
  List<Object?> get props => [];
}

class FetchSalesPlans extends SalesPlanEvent {
  final SalesPlanQueryFilter filter;

  const FetchSalesPlans({this.filter = const SalesPlanQueryFilter()});

  @override
  List<Object?> get props => [filter];
}

class FetchMoreSalesPlans extends SalesPlanEvent {
  const FetchMoreSalesPlans();
}

class RefreshSalesPlans extends SalesPlanEvent {
  const RefreshSalesPlans();
}

class CreateSalesPlanEvent extends SalesPlanEvent {
  final SalesPlanCreateRequest request;

  const CreateSalesPlanEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class UpdateSalesPlanEvent extends SalesPlanEvent {
  final int id;
  final SalesPlanCreateRequest request;

  const UpdateSalesPlanEvent({required this.id, required this.request});

  @override
  List<Object?> get props => [id, request];
}

class DeleteSalesPlanEvent extends SalesPlanEvent {
  final int id;

  const DeleteSalesPlanEvent(this.id);

  @override
  List<Object?> get props => [id];
}

import 'package:crm_task_manager/models/sales_plan/sales_plan_filter.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:equatable/equatable.dart';

abstract class SalesPlanState extends Equatable {
  const SalesPlanState();

  @override
  List<Object?> get props => [];
}

class SalesPlanInitial extends SalesPlanState {}

class SalesPlanLoading extends SalesPlanState {
  final bool isFirstFetch;

  const SalesPlanLoading({this.isFirstFetch = true});

  @override
  List<Object?> get props => [isFirstFetch];
}

class SalesPlanLoaded extends SalesPlanState {
  final List<SalesPlan> plans;
  final int total;
  final int currentPage;
  final bool hasMore;
  final SalesPlanQueryFilter filter;
  final bool isLoadingMore;

  const SalesPlanLoaded({
    required this.plans,
    required this.total,
    required this.currentPage,
    required this.hasMore,
    required this.filter,
    this.isLoadingMore = false,
  });

  SalesPlanLoaded copyWith({
    List<SalesPlan>? plans,
    int? total,
    int? currentPage,
    bool? hasMore,
    SalesPlanQueryFilter? filter,
    bool? isLoadingMore,
  }) {
    return SalesPlanLoaded(
      plans: plans ?? this.plans,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [plans, total, currentPage, hasMore, filter, isLoadingMore];
}

class SalesPlanError extends SalesPlanState {
  final String message;

  const SalesPlanError(this.message);

  @override
  List<Object?> get props => [message];
}

class SalesPlanActionSuccess extends SalesPlanState {
  final String message;
  final List<SalesPlan> plans;
  final int total;
  final SalesPlanQueryFilter filter;

  const SalesPlanActionSuccess({
    required this.message,
    required this.plans,
    required this.total,
    required this.filter,
  });

  @override
  List<Object?> get props => [message, plans, total, filter];
}

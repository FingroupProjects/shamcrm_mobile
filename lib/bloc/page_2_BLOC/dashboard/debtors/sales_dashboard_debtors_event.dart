part of 'sales_dashboard_debtors_bloc.dart';

sealed class SalesDashboardDebtorsEvent extends Equatable {
  const SalesDashboardDebtorsEvent();
}

class LoadDebtorsReport extends SalesDashboardDebtorsEvent {
  final Map<String, dynamic>? filter;
  final String? search;
  final int page;
  final int perPage;

  const LoadDebtorsReport({
    this.filter,
    this.search,
    this.page = 1,
    this.perPage = 20,
  });

  @override
  List<Object?> get props => [filter, search, page, perPage];
}

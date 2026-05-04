part of 'sales_dashboard_creditors_bloc.dart';

sealed class SalesDashboardCreditorsEvent extends Equatable {
  const SalesDashboardCreditorsEvent();
}

class LoadCreditorsReport extends SalesDashboardCreditorsEvent {
  final Map<String, dynamic>? filter;
  final String? search;
  final int page;
  final int perPage;

  const LoadCreditorsReport({
    this.filter,
    this.search,
    this.page = 1,
    this.perPage = 20,
  });

  @override
  List<Object?> get props => [filter, search, page, perPage];
}

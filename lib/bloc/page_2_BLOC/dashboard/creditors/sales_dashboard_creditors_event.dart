part of 'sales_dashboard_creditors_bloc.dart';

sealed class SalesDashboardCreditorsEvent extends Equatable {
  const SalesDashboardCreditorsEvent();
}

class LoadCreditorsReport extends SalesDashboardCreditorsEvent {
  

  const LoadCreditorsReport();

  @override
  List<Object?> get props => [];
}

part of 'sales_dashboard_debtors_bloc.dart';

sealed class SalesDashboardDebtorsEvent extends Equatable {
  const SalesDashboardDebtorsEvent();
}

class LoadDebtorsReport extends SalesDashboardDebtorsEvent {
  

  const LoadDebtorsReport();

  @override
  List<Object?> get props => [];
}

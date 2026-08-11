import 'package:equatable/equatable.dart';

abstract class SalesPlanDashboardEvent extends Equatable {
  const SalesPlanDashboardEvent();

  @override
  List<Object?> get props => [];
}

class FetchSalesPlanDashboard extends SalesPlanDashboardEvent {
  const FetchSalesPlanDashboard();
}

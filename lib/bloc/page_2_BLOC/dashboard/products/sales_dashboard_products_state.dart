part of 'sales_dashboard_products_bloc.dart';

sealed class SalesDashboardProductsState extends Equatable {
  const SalesDashboardProductsState();
}

final class SalesDashboardProductsInitial extends SalesDashboardProductsState {
  @override
  List<Object> get props => [];
}

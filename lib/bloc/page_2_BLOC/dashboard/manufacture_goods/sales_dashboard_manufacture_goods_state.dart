part of 'sales_dashboard_manufacture_goods_bloc.dart';

sealed class SalesDashboardManufactureGoodsState extends Equatable {
  const SalesDashboardManufactureGoodsState();
}

final class SalesDashboardManufactureGoodsInitial
    extends SalesDashboardManufactureGoodsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardManufactureGoodsLoading
    extends SalesDashboardManufactureGoodsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardManufactureGoodsLoaded
    extends SalesDashboardManufactureGoodsState {
  final ManufactureReportResponse result;

  const SalesDashboardManufactureGoodsLoaded({
    required this.result,
  });

  @override
  List<Object> get props => [result];
}

final class SalesDashboardManufactureGoodsError
    extends SalesDashboardManufactureGoodsState {
  final String message;

  const SalesDashboardManufactureGoodsError({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

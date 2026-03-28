part of 'sales_dashboard_manufacture_materials_bloc.dart';

sealed class SalesDashboardManufactureMaterialsState extends Equatable {
  const SalesDashboardManufactureMaterialsState();
}

final class SalesDashboardManufactureMaterialsInitial
    extends SalesDashboardManufactureMaterialsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardManufactureMaterialsLoading
    extends SalesDashboardManufactureMaterialsState {
  @override
  List<Object> get props => [];
}

final class SalesDashboardManufactureMaterialsLoaded
    extends SalesDashboardManufactureMaterialsState {
  final ManufactureMaterialsReportResponse result;

  const SalesDashboardManufactureMaterialsLoaded({
    required this.result,
  });

  @override
  List<Object> get props => [result];
}

final class SalesDashboardManufactureMaterialsError
    extends SalesDashboardManufactureMaterialsState {
  final String message;

  const SalesDashboardManufactureMaterialsError({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

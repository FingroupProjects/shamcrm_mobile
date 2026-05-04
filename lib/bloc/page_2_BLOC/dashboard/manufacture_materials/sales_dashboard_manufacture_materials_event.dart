part of 'sales_dashboard_manufacture_materials_bloc.dart';

sealed class SalesDashboardManufactureMaterialsEvent extends Equatable {
  const SalesDashboardManufactureMaterialsEvent();
}

class LoadManufactureMaterialsReport
    extends SalesDashboardManufactureMaterialsEvent {
  final int page;
  final int perPage;
  final Map<String, dynamic>? filter;
  final String? search;

  const LoadManufactureMaterialsReport({
    this.page = 1,
    this.perPage = 20,
    this.filter,
    this.search,
  });

  @override
  List<Object?> get props => [page, perPage, filter, search];
}

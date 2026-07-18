import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/manufacture_report_model.dart';

part 'sales_dashboard_manufacture_materials_event.dart';
part 'sales_dashboard_manufacture_materials_state.dart';

class SalesDashboardManufactureMaterialsBloc extends Bloc<
    SalesDashboardManufactureMaterialsEvent,
    SalesDashboardManufactureMaterialsState> {
  final ApiService apiService = ApiService();

  SalesDashboardManufactureMaterialsBloc()
      : super(SalesDashboardManufactureMaterialsInitial()) {
    on<LoadManufactureMaterialsReport>((event, emit) async {
      try {
        emit(SalesDashboardManufactureMaterialsLoading());
        final response = await apiService.getManufactureMaterialsReport(
          page: event.page,
          perPage: event.perPage,
          filters: event.filter,
          search: event.search,
        );
        emit(SalesDashboardManufactureMaterialsLoaded(result: response));
      } catch (e) {
        emit(
          SalesDashboardManufactureMaterialsError(
            message: friendlyError(e).replaceAll('Exception: ', ''),
          ),
        );
      }
    });
  }
}

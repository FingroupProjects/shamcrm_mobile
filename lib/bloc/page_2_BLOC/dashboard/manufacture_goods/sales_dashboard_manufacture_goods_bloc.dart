import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/manufacture_report_model.dart';

part 'sales_dashboard_manufacture_goods_event.dart';
part 'sales_dashboard_manufacture_goods_state.dart';

class SalesDashboardManufactureGoodsBloc extends Bloc<
    SalesDashboardManufactureGoodsEvent, SalesDashboardManufactureGoodsState> {
  final ApiService apiService = ApiService();

  SalesDashboardManufactureGoodsBloc()
      : super(SalesDashboardManufactureGoodsInitial()) {
    on<LoadManufactureGoodsReport>((event, emit) async {
      try {
        emit(SalesDashboardManufactureGoodsLoading());
        final response = await apiService.getManufactureGoodsReport(
          page: event.page,
          perPage: event.perPage,
          filters: event.filter,
          search: event.search,
        );
        emit(SalesDashboardManufactureGoodsLoaded(result: response));
      } catch (e) {
        emit(
          SalesDashboardManufactureGoodsError(
            message: friendlyError(e).replaceAll('Exception: ', ''),
          ),
        );
      }
    });
  }
}

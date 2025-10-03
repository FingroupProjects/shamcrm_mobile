import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/dashboard_goods_report.dart';

part 'sales_dashboard_goods_event.dart';
part 'sales_dashboard_goods_state.dart';

class SalesDashboardGoodsBloc extends Bloc<SalesDashboardGoodsEvent, SalesDashboardGoodsState> {
  final apiService = ApiService();

  SalesDashboardGoodsBloc() : super(SalesDashboardProductsInitial()) {
    on<LoadGoodsReport>((event, emit) async {
      // try {
        emit(SalesDashboardGoodsLoading());
        final response = await apiService.getSalesDashboardGoodsReport(
          page: event.page,
          perPage: event.perPage,
        );
        emit(SalesDashboardGoodsLoaded(
          goods: response.data,
          pagination: response.pagination,
        ));
      // } catch (e) {
      //   emit(SalesDashboardGoodsError(
      //     message: e.toString().replaceAll('Exception: ', ''),
      //   ));
      // }
    });
  }
}

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/models/page_2/dashboard/top_selling_card_model.dart';
import 'package:equatable/equatable.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/dashboard_goods_report.dart';

part 'sales_dashboard_top_selling_goods_event.dart';

part 'sales_dashboard_top_selling_goods_state.dart';

class SalesDashboardTopSellingGoodsBloc extends Bloc<SalesDashboardTopSellingGoodsEvent, SalesDashboardTopSellingGoodsState> {
  final apiService = ApiService();

  SalesDashboardTopSellingGoodsBloc() : super(SalesDashboardTopSellingProductsInitial()) {
    on<LoadTopSellingGoodsReport>((event, emit) async {
      // try {
      emit(SalesDashboardTopSellingGoodsLoading());
      final response = await apiService.getTopSellingCardsList();
      emit(SalesDashboardTopSellingGoodsLoaded(
        topSellingGoods: response,
      ));
      // } catch (e) {
      //   emit(SalesDashboardGoodsError(
      //     message: e.toString().replaceAll('Exception: ', ''),
      //   ));
      // }
    });
  }
}

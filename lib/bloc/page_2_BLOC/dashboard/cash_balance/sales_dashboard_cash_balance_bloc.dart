import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/cash_balance_model.dart';

part 'sales_dashboard_cash_balance_event.dart';
part 'sales_dashboard_cash_balance_state.dart';

class SalesDashboardCashBalanceBloc extends Bloc<SalesDashboardCashBalanceEvent, SalesDashboardCashBalanceState> {
  final apiService = ApiService();

  SalesDashboardCashBalanceBloc() : super(SalesDashboardProductsInitial()) {
    on<LoadCashBalanceReport>((event, emit) async {
      // try {
        emit(SalesDashboardCashBalanceLoading());
        final response = await apiService.getSalesDashboardCashBalance(
          page: event.page,
          perPage: event.perPage,
        );
        emit(SalesDashboardCashBalanceLoaded(data: response));
      // } catch (e) {
      //   emit(SalesDashboardGoodsError(
      //     message: e.toString().replaceAll('Exception: ', ''),
      //   ));
      // }
    });
  }
}

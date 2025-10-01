import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../api/service/api_service.dart';
import '../../../models/page_2/dashboard/cash_balance_model.dart';
import '../../../models/page_2/dashboard/debtors_model.dart';
import '../../../models/page_2/dashboard/creditors_model.dart';
import '../../../models/page_2/dashboard/illiquids_model.dart';

part 'sales_dashboard_event.dart';

part 'sales_dashboard_state.dart';

class SalesDashboardBloc extends Bloc<SalesDashboardEvent, SalesDashboardState> {
  final apiService = ApiService();

  SalesDashboardBloc() : super(SalesDashboardInitial()) {
    on<LoadInitialData>((event, emit) async {
        final results = await Future.wait([
          apiService.getDebtorsList(),
          apiService.getIlliquidGoods(),
          apiService.getCashBalance(),
          apiService.getCreditorsList(),
        ]);

        final debtorsResponse = results[0] as DebtorsResponse;
        final illiquidGoodsResponse = results[1] as IlliquidGoodsResponse;
        final cashBalanceResponse = results[2] as CashBalanceResponse;
        final creditorsResponse = results[3] as CreditorsResponse;

        emit(SalesDashboardLoaded(
          debtorsResponse: debtorsResponse,
          illiquidGoodsResponse: illiquidGoodsResponse,
          cashBalanceResponse: cashBalanceResponse,
          creditorsResponse: creditorsResponse,
        ));
    });

    add(LoadInitialData());
  }
}

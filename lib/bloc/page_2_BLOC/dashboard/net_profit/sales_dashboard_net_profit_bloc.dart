import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/net_profit_content_model.dart';

part 'sales_dashboard_net_profit_event.dart';
part 'sales_dashboard_net_profit_state.dart';

class SalesDashboardNetProfitBloc extends Bloc<SalesDashboardNetProfitEvent, SalesDashboardNetProfitState> {
  final apiService = ApiService();

  SalesDashboardNetProfitBloc() : super(SalesDashboardNetProfitInitial()) {
    on<LoadNetProfitReport>((event, emit) async {
      // try {
        emit(SalesDashboardNetProfitLoading());

        debugPrint("Fetching net profit report: filter=${event.filter}, search=${event.search}");

        final response = await apiService.getNetProfitByFilter(
          event.filter,
          event.search,
        );
        
        emit(SalesDashboardNetProfitLoaded(data: response));
      // } catch (e) {
      //   emit(SalesDashboardNetProfitError(
      //     message: e.toString().replaceAll('Exception: ', ''),
      //   ));
      // }
    });
  }
}

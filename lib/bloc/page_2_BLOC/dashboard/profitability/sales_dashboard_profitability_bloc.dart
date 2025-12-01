import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/profitability_content_model.dart';

part 'sales_dashboard_profitability_event.dart';
part 'sales_dashboard_profitability_state.dart';

class SalesDashboardProfitabilityBloc extends Bloc<SalesDashboardProfitabilityEvent, SalesDashboardProfitabilityState> {
  final apiService = ApiService();

  SalesDashboardProfitabilityBloc() : super(SalesDashboardProfitabilityInitial()) {
    on<LoadProfitabilityReport>((event, emit) async {
      // try {
        emit(SalesDashboardProfitabilityLoading());

        debugPrint("Fetching profitability report: filter=${event.filter}, search=${event.search}");

        final response = await apiService.getProfitabilityByFilter(
          event.filter,
          event.search,
        );
        
        emit(SalesDashboardProfitabilityLoaded(data: response));
      // } catch (e) {
      //   emit(SalesDashboardProfitabilityError(
      //     message: e.toString().replaceAll('Exception: ', ''),
      //   ));
      // }
    });
  }
}

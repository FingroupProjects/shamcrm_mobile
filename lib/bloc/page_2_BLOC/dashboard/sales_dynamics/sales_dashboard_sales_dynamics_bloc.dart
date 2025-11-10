import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/sales_model.dart';

part 'sales_dashboard_sales_dynamics_event.dart';
part 'sales_dashboard_sales_dynamics_state.dart';

class SalesDashboardSalesDynamicsBloc extends Bloc<SalesDashboardSalesDynamicsEvent, SalesDashboardSalesDynamicsState> {
  final apiService = ApiService();

  SalesDashboardSalesDynamicsBloc() : super(SalesDashboardSalesDynamicsInitial()) {
    on<LoadSalesDynamicsReport>((event, emit) async {
      // try {
        emit(SalesDashboardSalesDynamicsLoading());

        debugPrint("Fetching sales dynamics report: filter=${event.filter}, search=${event.search}");

        final response = await apiService.getSalesDynamicsByFilter(
          event.filter,
          event.search,
        );
        
        emit(SalesDashboardSalesDynamicsLoaded(data: response));
      // } catch (e) {
      //   emit(SalesDashboardSalesDynamicsError(
      //     message: e.toString().replaceAll('Exception: ', ''),
      //   ));
      // }
    });
  }
}

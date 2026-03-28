import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/order_quantity_content.dart';

part 'sales_dashboard_order_quantity_event.dart';
part 'sales_dashboard_order_quantity_state.dart';

class SalesDashboardOrderQuantityBloc extends Bloc<SalesDashboardOrderQuantityEvent, SalesDashboardOrderQuantityState> {
  final apiService = ApiService();

  SalesDashboardOrderQuantityBloc() : super(SalesDashboardOrderQuantityInitial()) {
    on<LoadOrderQuantityReport>((event, emit) async {
      try {
        emit(SalesDashboardOrderQuantityLoading());

        debugPrint("Fetching order quantity report: filter=${event.filter}, search=${event.search}");

        final response = await apiService.getOrderByFilter(
          event.filter,
          event.search,
        );
        
        emit(SalesDashboardOrderQuantityLoaded(data: response));
      } catch (e) {
        emit(SalesDashboardOrderQuantityError(
          message: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    });
  }
}

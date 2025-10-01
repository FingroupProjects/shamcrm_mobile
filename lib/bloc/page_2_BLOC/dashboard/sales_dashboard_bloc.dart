import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../api/service/api_service.dart';
import '../../../models/page_2/dashboard/dashboard_top.dart';

part 'sales_dashboard_event.dart';
part 'sales_dashboard_state.dart';

class SalesDashboardBloc extends Bloc<SalesDashboardEvent, SalesDashboardState> {

  final apiService = ApiService();

  SalesDashboardBloc() : super(SalesDashboardInitial()) {
    on<LoadInitialData>((event, emit) async {

        emit(SalesDashboardLoading());

        final results = await Future.wait([
          apiService.getSalesDashboardTopPart(),
        ]);

        final salesDashboardTopResponse = results[0] as DashboardTopPart;

        emit(SalesDashboardLoaded(
          salesDashboardTopPart: salesDashboardTopResponse,
        ));
    });

    add(LoadInitialData());
  }
}

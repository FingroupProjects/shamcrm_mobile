import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_dashboard_event.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_dashboard_state.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_dashboard_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesPlanDashboardBloc
    extends Bloc<SalesPlanDashboardEvent, SalesPlanDashboardState> {
  final ApiService apiService;

  SalesPlanDashboardBloc(this.apiService) : super(SalesPlanDashboardInitial()) {
    on<FetchSalesPlanDashboard>(_onFetch);
  }

  Future<void> _onFetch(
    FetchSalesPlanDashboard event,
    Emitter<SalesPlanDashboardState> emit,
  ) async {
    emit(SalesPlanDashboardLoading());
    try {
      final rows = await apiService.getSalesPlansDashboard();
      final items = rows.map(SalesPlanDashboardItem.fromJson).toList();
      emit(SalesPlanDashboardLoaded(items));
    } catch (e) {
      emit(SalesPlanDashboardError(e.toString()));
    }
  }
}

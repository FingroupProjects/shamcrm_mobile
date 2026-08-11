import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_leaderboard_event.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_leaderboard_state.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_leaderboard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesPlanLeaderboardBloc
    extends Bloc<SalesPlanLeaderboardEvent, SalesPlanLeaderboardState> {
  final ApiService apiService;

  SalesPlanLeaderboardBloc(this.apiService)
      : super(SalesPlanLeaderboardInitial()) {
    on<FetchSalesPlanLeaderboard>(_onFetch);
  }

  Future<void> _onFetch(
    FetchSalesPlanLeaderboard event,
    Emitter<SalesPlanLeaderboardState> emit,
  ) async {
    emit(SalesPlanLeaderboardLoading());
    try {
      final rows = await apiService.getSalesPlansLeaderboard(
        periodType: event.periodType,
      );
      final items = rows.map(SalesPlanLeaderboardItem.fromJson).toList()
        ..sort((a, b) => b.percent.compareTo(a.percent));
      emit(SalesPlanLeaderboardLoaded(items));
    } catch (e) {
      emit(SalesPlanLeaderboardError(e.toString()));
    }
  }
}

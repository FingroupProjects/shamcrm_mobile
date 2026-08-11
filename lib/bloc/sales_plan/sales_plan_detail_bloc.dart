import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_detail_event.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_detail_state.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_leaderboard.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesPlanDetailBloc
    extends Bloc<SalesPlanDetailEvent, SalesPlanDetailState> {
  final ApiService apiService;

  SalesPlanDetailBloc(this.apiService) : super(SalesPlanDetailInitial()) {
    on<FetchSalesPlanDetail>(_onFetchDetail);
    on<FetchSalesPlanDailyArchive>(_onFetchArchive);
  }

  Future<void> _onFetchDetail(
    FetchSalesPlanDetail event,
    Emitter<SalesPlanDetailState> emit,
  ) async {
    emit(SalesPlanDetailLoading());
    try {
      final response = await apiService.getSalesPlanById(event.id);
      final plan = SalesPlan.fromJson(extractSalesPlanItem(response));

      List<SalesPlanLeaderboardItem> hierarchy = [];
      if (plan.children.isEmpty) {
        try {
          final rows = await apiService.getSalesPlansLeaderboard(
            periodType: plan.periodType.apiValue,
          );
          hierarchy = rows
              .map(SalesPlanLeaderboardItem.fromJson)
              .where((e) => e.planId == plan.id)
              .toList();
        } catch (_) {}
      }

      emit(SalesPlanDetailLoaded(
        plan: plan,
        hierarchyFromLeaderboard: hierarchy,
      ));

      if (plan.isDailyRecurring) {
        add(FetchSalesPlanDailyArchive(
          planId: plan.id,
          nameHint: plan.name,
          userIds: plan.users.map((u) => u.id).toList(),
        ));
      }
    } catch (e) {
      emit(SalesPlanDetailError(e.toString()));
    }
  }

  Future<void> _onFetchArchive(
    FetchSalesPlanDailyArchive event,
    Emitter<SalesPlanDetailState> emit,
  ) async {
    final current = state;
    if (current is! SalesPlanDetailLoaded) return;
    emit(current.copyWith(archiveLoading: true));
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 14));
      final to = now.add(const Duration(days: 1));
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final response = await apiService.getSalesPlans(
        periodFrom: fmt(from),
        periodTo: fmt(to),
        perPage: 50,
        sort: 'period_start',
        direction: 'desc',
        userId: event.userIds.isNotEmpty ? event.userIds.first : null,
      );
      final parsed = SalesPlanListResponse.fromJson(response);
      final archive = parsed.data.where((p) {
        final sameObject = p.objectType == current.plan.objectType &&
            p.aggregation == current.plan.aggregation &&
            p.periodType == SalesPlanPeriodType.day;
        final nameClose = event.nameHint == null ||
            event.nameHint!.isEmpty ||
            p.name.contains(event.nameHint!.split('—').first.trim()) ||
            p.name == event.nameHint;
        return sameObject && nameClose;
      }).toList()
        ..sort((a, b) {
          final as = a.periodStart ?? DateTime(1970);
          final bs = b.periodStart ?? DateTime(1970);
          return bs.compareTo(as);
        });

      emit(current.copyWith(dailyArchive: archive, archiveLoading: false));
    } catch (_) {
      emit(current.copyWith(archiveLoading: false));
    }
  }
}

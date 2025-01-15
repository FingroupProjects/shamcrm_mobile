import 'package:crm_task_manager/models/dashboard_charts_models_manager/deal_stats_model.dart';


abstract class DealStatsStateManager {}

class DealStatsInitialManager extends DealStatsStateManager {}

class DealStatsLoadingManager extends DealStatsStateManager {}

class DealStatsLoadedManager extends DealStatsStateManager {
  final DealStatsResponseManager dealStatsData;

  DealStatsLoadedManager({required this.dealStatsData});
}

class DealStatsErrorManager extends DealStatsStateManager {
  final String message;

  DealStatsErrorManager({required this.message});
}

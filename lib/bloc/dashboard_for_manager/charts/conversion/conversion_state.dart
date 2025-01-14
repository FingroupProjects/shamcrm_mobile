
import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_conversion_model.dart';

abstract class DashboardConversionStateManager {}

class DashboardConversionInitialManager extends DashboardConversionStateManager {}

class DashboardConversionLoadingManager extends DashboardConversionStateManager {}

class DashboardConversionLoadedManager extends DashboardConversionStateManager {
  final LeadConversionManager leadConversionData;

  DashboardConversionLoadedManager({required this.leadConversionData});
}

class DashboardConversionErrorManager extends DashboardConversionStateManager {
  final String message;

  DashboardConversionErrorManager({required this.message});
}

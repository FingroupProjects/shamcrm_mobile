// States
import 'package:crm_task_manager/models/dashboard_charts_models_manager/process_speed%20_model.dart';

abstract class ProcessSpeedStateManager {}

class ProcessSpeedInitialManager extends ProcessSpeedStateManager {}

class ProcessSpeedLoadingManager extends ProcessSpeedStateManager {}

class ProcessSpeedLoadedManager extends ProcessSpeedStateManager {
  final ProcessSpeedManager processSpeedData;

  ProcessSpeedLoadedManager({required this.processSpeedData});
}

class ProcessSpeedErrorManager extends ProcessSpeedStateManager {
  final String message;

  ProcessSpeedErrorManager({required this.message});
}

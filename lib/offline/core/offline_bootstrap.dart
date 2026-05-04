import 'package:crm_task_manager/offline/core/offline_runtime.dart';

class OfflineBootstrap {
  const OfflineBootstrap._();

  static Future<void> initialize() async {
    await OfflineRuntime.initialize();
  }
}

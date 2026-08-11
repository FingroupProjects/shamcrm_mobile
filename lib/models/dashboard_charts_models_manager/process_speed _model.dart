import 'package:crm_task_manager/utils/safe_converters.dart';

class ProcessSpeedManager {
  final double speed;

  ProcessSpeedManager({
    required this.speed,
  });

  factory ProcessSpeedManager.fromJson(Map<String, dynamic> json) {
    return ProcessSpeedManager(
      speed: SafeConverters.toDouble(json['result']),
    );
  }
}

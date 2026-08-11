import 'package:crm_task_manager/utils/safe_converters.dart';

class ProcessSpeed {
  final double speed;

  ProcessSpeed({
    required this.speed,
  });

  factory ProcessSpeed.fromJson(Map<String, dynamic> json) {
    return ProcessSpeed(
      speed: SafeConverters.toDouble(json['result']),
    );
  }
}

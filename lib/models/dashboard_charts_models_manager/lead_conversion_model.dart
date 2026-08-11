import 'package:crm_task_manager/utils/safe_converters.dart';

class LeadConversionManager {
  final List<double> monthlyData;

  LeadConversionManager({
    required this.monthlyData,
  });

  factory LeadConversionManager.fromJson(Map<String, dynamic> json) {
    return LeadConversionManager(
      monthlyData: SafeConverters.toList(json['result'])
          .map(SafeConverters.toDouble)
          .toList(),
    );
  }
}

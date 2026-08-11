import 'package:crm_task_manager/utils/safe_converters.dart';

class LeadConversion {
  final List<double> monthlyData;

  LeadConversion({
    required this.monthlyData,
  });

  factory LeadConversion.fromJson(Map<String, dynamic> json) {
    return LeadConversion(
      monthlyData: SafeConverters.toList(json['result'])
          .map(SafeConverters.toDouble)
          .toList(),
    );
  }
}

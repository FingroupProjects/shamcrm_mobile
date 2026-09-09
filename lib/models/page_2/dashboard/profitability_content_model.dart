import 'package:crm_task_manager/utils/safe_converters.dart';

// Class to represent the entire response
class ProfitabilityResponse {
  final ProfitabilityResult result;
  final dynamic errors; // Using dynamic since errors can be null or any type

  ProfitabilityResponse({
    required this.result,
    this.errors,
  });

  factory ProfitabilityResponse.fromJson(Map<String, dynamic> json) {
    return ProfitabilityResponse(
      result: ProfitabilityResult.fromJson(SafeConverters.toMap(json['result'])),
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result.toJson(),
      'errors': errors,
    };
  }
}

// Class to represent the result object
class ProfitabilityResult {
  final int year;
  final List<MonthData> months;

  ProfitabilityResult({
    required this.year,
    required this.months,
  });

  factory ProfitabilityResult.fromJson(Map<String, dynamic> json) {
    return ProfitabilityResult(
      year: SafeConverters.toInt(json['year']),
      months: SafeConverters.toModelList(
        json['months'],
        MonthData.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'months': months.map((month) => month.toJson()).toList(),
    };
  }
}

// Class to represent each month object
class MonthData {
  final int month;
  final String monthName;
  final num profitabilityPercentage; // Changed to double to handle numeric values

  MonthData({
    required this.month,
    required this.monthName,
    required this.profitabilityPercentage,
  });

  factory MonthData.fromJson(Map<String, dynamic> json) {
    return MonthData(
      month: SafeConverters.toInt(json['month']),
      monthName: SafeConverters.toSafeString(json['month_name']),
      profitabilityPercentage:
          SafeConverters.toDouble(json['profitability_percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'month_name': monthName,
      'profitability_percentage': profitabilityPercentage.toString(), // Convert back to string for JSON
    };
  }
}

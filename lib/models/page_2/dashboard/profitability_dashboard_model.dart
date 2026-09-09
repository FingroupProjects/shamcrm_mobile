import 'package:crm_task_manager/utils/safe_converters.dart';

// Enum for profitability period types
enum ProfitabilityTimePeriod {
  last_year,
  year,
}

// Data class to hold period and profitability dashboard data
class AllProfitabilityData {
  final ProfitabilityTimePeriod period;
  final ProfitabilityDashboard data;

  AllProfitabilityData({
    required this.period,
    required this.data,
  });
}

// ProfitabilityDashboard and related classes
class ProfitabilityDashboard {
  final ProfitabilityResult result;
  final dynamic errors;

  ProfitabilityDashboard({
    required this.result,
    this.errors,
  });

  factory ProfitabilityDashboard.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return ProfitabilityDashboard(
      result: ProfitabilityResult.fromJson(SafeConverters.toMap(map['result'])),
      errors: map['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result.toJson(),
      'errors': errors,
    };
  }
}

class ProfitabilityResult {
  final int year;
  final List<ProfitabilityMonth> months;

  ProfitabilityResult({
    required this.year,
    required this.months,
  });

  factory ProfitabilityResult.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return ProfitabilityResult(
      year: SafeConverters.toInt(map['year']),
      months: SafeConverters.toModelList(
        map['months'],
        ProfitabilityMonth.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'months': months.map((e) => e.toJson()).toList(),
    };
  }
}

class ProfitabilityMonth {
  final int month;
  final String monthName;
  final dynamic profitabilityPercentage; // Can be String or int based on JSON

  ProfitabilityMonth({
    required this.month,
    required this.monthName,
    required this.profitabilityPercentage,
  });

  factory ProfitabilityMonth.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return ProfitabilityMonth(
      month: SafeConverters.toInt(map['month']),
      monthName: SafeConverters.toSafeString(map['month_name']),
      profitabilityPercentage: map['profitability_percentage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'month_name': monthName,
      'profitability_percentage': profitabilityPercentage,
    };
  }
}

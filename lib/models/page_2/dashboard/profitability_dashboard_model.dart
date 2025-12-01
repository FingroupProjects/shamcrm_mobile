import 'dart:convert';

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

  factory ProfitabilityDashboard.fromJson(Map<String, dynamic> json) {
    return ProfitabilityDashboard(
      result: ProfitabilityResult.fromJson(json['result']),
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

class ProfitabilityResult {
  final int year;
  final List<ProfitabilityMonth> months;

  ProfitabilityResult({
    required this.year,
    required this.months,
  });

  factory ProfitabilityResult.fromJson(Map<String, dynamic> json) {
    return ProfitabilityResult(
      year: json['year'],
      months: (json['months'] as List)
          .map((e) => ProfitabilityMonth.fromJson(e))
          .toList(),
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

  factory ProfitabilityMonth.fromJson(Map<String, dynamic> json) {
    return ProfitabilityMonth(
      month: json['month'],
      monthName: json['month_name'],
      profitabilityPercentage: json['profitability_percentage'],
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

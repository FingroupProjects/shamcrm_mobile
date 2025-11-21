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
      year: json['year'],
      months: (json['months'] as List)
          .map((month) => MonthData.fromJson(month))
          .toList(),
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
  final double profitabilityPercentage; // Changed to double to handle numeric values

  MonthData({
    required this.month,
    required this.monthName,
    required this.profitabilityPercentage,
  });

  factory MonthData.fromJson(Map<String, dynamic> json) {
    // Handle profitability_percentage, which can be String or num
    double profitabilityPercentage = 0.0;
    if (json['profitability_percentage'] is String) {
      profitabilityPercentage =
          double.tryParse(json['profitability_percentage']) ?? 0.0;
    } else if (json['profitability_percentage'] is num) {
      profitabilityPercentage = (json['profitability_percentage'] as num).toDouble();
    }

    return MonthData(
      month: json['month'],
      monthName: json['month_name'],
      profitabilityPercentage: profitabilityPercentage,
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
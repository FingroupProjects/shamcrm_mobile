// Class to represent the entire response
class SalesResponse {
  final SalesResult result;
  final dynamic errors; // Using dynamic since errors can be null or any type

  SalesResponse({
    required this.result,
    this.errors,
  });

  factory SalesResponse.fromJson(Map<String, dynamic> json) {
    return SalesResponse(
      result: SalesResult.fromJson(json['result']),
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
class SalesResult {
  final int year;
  final List<MonthData> months;
  final Summary summary;

  SalesResult({
    required this.year,
    required this.months,
    required this.summary,
  });

  factory SalesResult.fromJson(Map<String, dynamic> json) {
    return SalesResult(
      year: json['year'],
      months: (json['months'] as List)
          .map((month) => MonthData.fromJson(month))
          .toList(),
      summary: Summary.fromJson(json['summary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'months': months.map((month) => month.toJson()).toList(),
      'summary': summary.toJson(),
    };
  }
}

// Class to represent each month object
class MonthData {
  final int month;
  final String monthName;
  final int salesCount;
  final int totalQuantity;
  final String totalAmount; // Keeping as String to preserve decimal format

  MonthData({
    required this.month,
    required this.monthName,
    required this.salesCount,
    required this.totalQuantity,
    required this.totalAmount,
  });

  factory MonthData.fromJson(Map<String, dynamic> json) {
    return MonthData(
      month: json['month'],
      monthName: json['month_name'],
      salesCount: json['sales_count'],
      totalQuantity: json['total_quantity'],
      totalAmount: json['total_amount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'month_name': monthName,
      'sales_count': salesCount,
      'total_quantity': totalQuantity,
      'total_amount': totalAmount,
    };
  }
}

// Class to represent the summary object
class Summary {
  final int totalSalesCount;
  final int totalQuantity;
  final String totalAmount; // Keeping as String to preserve decimal format

  Summary({
    required this.totalSalesCount,
    required this.totalQuantity,
    required this.totalAmount,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalSalesCount: json['total_sales_count'],
      totalQuantity: json['total_quantity'],
      totalAmount: json['total_amount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sales_count': totalSalesCount,
      'total_quantity': totalQuantity,
      'total_amount': totalAmount,
    };
  }
}
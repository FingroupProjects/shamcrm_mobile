// Class to represent the entire response
class NetProfitResponse {
  final NetProfitResult result;
  final dynamic errors; // Using dynamic since errors can be null or any type

  NetProfitResponse({
    required this.result,
    this.errors,
  });

  factory NetProfitResponse.fromJson(Map<String, dynamic> json) {
    return NetProfitResponse(
      result: NetProfitResult.fromJson(json['result']),
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
class NetProfitResult {
  final int year;
  final List<MonthData> months;
  final num totalNetProfit; // Keeping as int to preserve decimal format

  NetProfitResult({
    required this.year,
    required this.months,
    required this.totalNetProfit,
  });

  factory NetProfitResult.fromJson(Map<String, dynamic> json) {
    return NetProfitResult(
      year: json['year'],
      months: (json['months'] as List)
          .map((month) => MonthData.fromJson(month))
          .toList(),
      totalNetProfit: json['total_net_profit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'months': months.map((month) => month.toJson()).toList(),
      'total_net_profit': totalNetProfit,
    };
  }
}

// Class to represent each month object
class MonthData {
  final int month;
  final String monthName;
  final String netProfit; // Keeping as String to preserve decimal format

  MonthData({
    required this.month,
    required this.monthName,
    required this.netProfit,
  });

  factory MonthData.fromJson(Map<String, dynamic> json) {
    String totalAmount = "0.00";

    if (json['net_profit'] is String) {
      totalAmount = json['net_profit'];
    } else if (json['net_profit'] is num) {
      totalAmount = (json['net_profit'] as num).toString();
    }

    return MonthData(
      month: json['month'],
      monthName: json['month_name'],
      netProfit: totalAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'month_name': monthName,
      'net_profit': netProfit,
    };
  }
}
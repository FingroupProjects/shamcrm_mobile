import 'package:crm_task_manager/utils/safe_converters.dart';

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
      result: NetProfitResult.fromJson(SafeConverters.toMap(json['result'])),
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
  final num totalNetProfit; // Keep numeric type to preserve decimals

  NetProfitResult({
    required this.year,
    required this.months,
    required this.totalNetProfit,
  });

  factory NetProfitResult.fromJson(Map<String, dynamic> json) {
    return NetProfitResult(
      year: SafeConverters.toInt(json['year']),
      months: SafeConverters.toList(json['months'])
          .map((month) => MonthData.fromJson(SafeConverters.toMap(month)))
          .toList(),
      totalNetProfit: SafeConverters.toNum(json['total_net_profit']),
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
    final netProfitRaw = json['net_profit'];
    final netProfit = netProfitRaw is String
        ? SafeConverters.toSafeString(netProfitRaw)
        : SafeConverters.toSafeString(netProfitRaw, defaultValue: '0.00');

    return MonthData(
      month: SafeConverters.toInt(json['month']),
      monthName: SafeConverters.toSafeString(json['month_name']),
      netProfit: netProfit,
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

import 'dart:convert';

// Enum for net profit period types
enum NetProfitPeriod {
  last_year,
  year,
}

// Data class to hold period and net profit dashboard data
class AllNetProfitData {
  final NetProfitPeriod period;
  final NetProfitDashboard data;

  AllNetProfitData({
    required this.period,
    required this.data,
  });
}

// NetProfitDashboard and related classes
class NetProfitDashboard {
  final NetProfitResult result;
  final dynamic errors;

  NetProfitDashboard({
    required this.result,
    this.errors,
  });

  factory NetProfitDashboard.fromJson(Map<String, dynamic> json) {
    return NetProfitDashboard(
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

class NetProfitResult {
  final int year;
  final List<NetProfitMonth> months;
  final num totalNetProfit;

  NetProfitResult({
    required this.year,
    required this.months,
    required this.totalNetProfit,
  });

  factory NetProfitResult.fromJson(Map<String, dynamic> json) {
    return NetProfitResult(
      year: json['year'],
      months: (json['months'] as List)
          .map((e) => NetProfitMonth.fromJson(e))
          .toList(),
      totalNetProfit: json['total_net_profit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'months': months.map((e) => e.toJson()).toList(),
      'total_net_profit': totalNetProfit,
    };
  }
}

class NetProfitMonth {
  final int month;
  final String monthName;
  final String netProfit;

  NetProfitMonth({
    required this.month,
    required this.monthName,
    required this.netProfit,
  });

  factory NetProfitMonth.fromJson(Map<String, dynamic> json) {

    String netProfit = '0';

    if (json['net_profit'] is String) {
      netProfit = json['net_profit'];
    } else if (json['net_profit'] is num) {
      netProfit = (json['net_profit'] as num).toString();
    }

    return NetProfitMonth(
      month: json['month'],
      monthName: json['month_name'],
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
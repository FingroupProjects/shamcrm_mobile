import 'dart:convert';

import 'package:crm_task_manager/utils/safe_converters.dart';

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
      year: SafeConverters.toInt(json['year']),
      months: SafeConverters.toModelList(
        json['months'],
        NetProfitMonth.fromJson,
      ),
      totalNetProfit: SafeConverters.toNum(json['total_net_profit']),
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
    return NetProfitMonth(
      month: SafeConverters.toInt(json['month']),
      monthName: SafeConverters.toSafeString(json['month_name']),
      netProfit: SafeConverters.toSafeString(json['net_profit'], defaultValue: '0'),
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

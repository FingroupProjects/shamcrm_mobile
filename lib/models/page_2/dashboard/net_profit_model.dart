class NetProfitResponse {
  final Result result;
  final dynamic errors;

  NetProfitResponse({
    required this.result,
    this.errors,
  });

  factory NetProfitResponse.fromJson(Map<String, dynamic> json) {
    return NetProfitResponse(
      result: Result.fromJson(json['result']),
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

class Result {
  final int year;
  final List<Month> months;
  final num totalNetProfit;

  Result({
    required this.year,
    required this.months,
    required this.totalNetProfit,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      year: json['year'],
      months: (json['months'] as List)
          .map((month) => Month.fromJson(month))
          .toList(),
      totalNetProfit: 80,
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

class Month {
  final int month;
  final String monthName;
  final num netProfit;

  Month({
    required this.month,
    required this.monthName,
    required this.netProfit,
  });

  factory Month.fromJson(Map<String, dynamic> json) {
    return Month(
      month: json['month'],
      monthName: json['month_name'],
      netProfit: num.parse(json['net_profit'].toString()),
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
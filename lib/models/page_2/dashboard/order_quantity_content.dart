import 'package:crm_task_manager/utils/safe_converters.dart';

class ChartDataContent {
  final int id;
  final String name;
  final num amount;

  ChartDataContent({
    required this.id,
    required this.name,
    required this.amount,
  });

  factory ChartDataContent.fromJson(Map<String, dynamic> json) {
    return ChartDataContent(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      amount: SafeConverters.toNum(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
    };
  }
}

class Result {
  final List<ChartDataContent> chartData;

  Result({
    required this.chartData,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      chartData: SafeConverters.toList(json['chart_data'])
          .map((item) => ChartDataContent.fromJson(SafeConverters.toMap(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chart_data': chartData.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderQuantityContent {
  final Result result;
  final dynamic errors;

  OrderQuantityContent({
    required this.result,
    this.errors,
  });

  factory OrderQuantityContent.fromJson(Map<String, dynamic> json) {
    return OrderQuantityContent(
      result: Result.fromJson(SafeConverters.toMap(json['result'])),
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

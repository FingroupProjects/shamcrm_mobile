class ChartDataContent {
  final int id;
  final String name;
  final int amount;

  ChartDataContent({
    required this.id,
    required this.name,
    required this.amount,
  });

  factory ChartDataContent.fromJson(Map<String, dynamic> json) {
    return ChartDataContent(
      id: json['id'] as int,
      name: json['name'] as String,
      amount: json['amount'] as int,
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
      chartData: (json['chart_data'] as List)
          .map((item) => ChartDataContent.fromJson(item as Map<String, dynamic>))
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
      result: Result.fromJson(json['result'] as Map<String, dynamic>),
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

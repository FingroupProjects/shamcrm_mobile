class OrderDashboardResponse {
  final ChartResult result;
  final dynamic errors;

  OrderDashboardResponse({required this.result, required this.errors});

  factory OrderDashboardResponse.fromJson(Map<String, dynamic> json) {
    return OrderDashboardResponse(
      result: ChartResult.fromJson(json['result'] as Map<String, dynamic>),
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

class ChartResult {
  final List<OrderChartData> chartData;

  ChartResult({required this.chartData});

  factory ChartResult.fromJson(Map<String, dynamic> json) {
    return ChartResult(
      chartData:
          (json['chart_data'] as List<dynamic>).map((item) => OrderChartData.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chart_data': chartData.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderChartData {
  final String name;
  final List<DataPoint> data;

  OrderChartData({required this.name, required this.data});

  factory OrderChartData.fromJson(Map<String, dynamic> json) {
    return OrderChartData(
      name: json['name'] as String,
      data: (json['data'] as List<dynamic>).map((item) => DataPoint.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class DataPoint {
  final int id;
  final String label;
  final int amount;

  DataPoint({required this.id, required this.label, required this.amount});

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      id: json['id'] as int,
      label: json['label'] as String,
      amount: json['amount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'amount': amount,
    };
  }
}

enum OrderTimePeriod { week, month, year }

class AllOrdersData {
  final OrderTimePeriod period;
  final ChartResult data;

  AllOrdersData({required this.data, this.period = OrderTimePeriod.week});
}

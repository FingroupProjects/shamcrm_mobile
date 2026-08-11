import 'package:crm_task_manager/utils/safe_converters.dart';

class OrderDashboardResponse {
  final ChartResult result;
  final dynamic errors;

  OrderDashboardResponse({required this.result, required this.errors});

  factory OrderDashboardResponse.fromJson(Map<String, dynamic> json) {
    return OrderDashboardResponse(
      result: ChartResult.fromJson(SafeConverters.toMap(json['result'])),
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
      chartData: SafeConverters.toList(json['chart_data'])
          .map((item) => OrderChartData.fromJson(SafeConverters.toMap(item)))
          .toList(),
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
      name: SafeConverters.toSafeString(json['name']),
      data: SafeConverters.toList(json['data'])
          .map((item) => DataPoint.fromJson(SafeConverters.toMap(item)))
          .toList(),
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
  final num amount;

  DataPoint({required this.id, required this.label, required this.amount});

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      id: SafeConverters.toInt(json['id']),
      label: SafeConverters.toSafeString(json['label']),
      amount: SafeConverters.toNum(json['amount']),
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

import 'package:crm_task_manager/utils/safe_converters.dart';

class DashboardExpenseResponse {
  final ExpenseResult result;
  final dynamic errors;

  DashboardExpenseResponse({
    required this.result,
    this.errors,
  });

  factory DashboardExpenseResponse.fromJson(Map<String, dynamic> json) {
    return DashboardExpenseResponse(
      result: ExpenseResult.fromJson(SafeConverters.toMap(json['result'])),
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

class ExpenseResult {
  final num totalExpenses;
  final List<ExpenseItem> expenseStructure;
  final List<ExpenseItem> topExpenses;
  final Period period;

  ExpenseResult({
    required this.totalExpenses,
    required this.expenseStructure,
    required this.topExpenses,
    required this.period,
  });

  factory ExpenseResult.fromJson(Map<String, dynamic> json) {
    return ExpenseResult(
      totalExpenses: SafeConverters.toNum(json['total_expenses']),
      expenseStructure: SafeConverters.toList(json['expense_structure'])
          .map((e) => ExpenseItem.fromJson(SafeConverters.toMap(e)))
          .toList(),
      topExpenses: SafeConverters.toList(json['top_expenses'])
          .map((e) => ExpenseItem.fromJson(SafeConverters.toMap(e)))
          .toList(),
      period: Period.fromJson(SafeConverters.toMap(json['period'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_expenses': totalExpenses,
      'expense_structure': expenseStructure.map((e) => e.toJson()).toList(),
      'top_expenses': topExpenses.map((e) => e.toJson()).toList(),
      'period': period.toJson(),
    };
  }
}

class ExpenseItem {
  final String articleName;
  final String articleType;
  final num sum;
  final String formattedSum;
  final num percentage;

  ExpenseItem({
    required this.articleName,
    required this.articleType,
    required this.sum,
    required this.formattedSum,
    required this.percentage,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      articleName: SafeConverters.toSafeString(json['article_name']),
      articleType: SafeConverters.toSafeString(json['article_type']),
      sum: SafeConverters.toNum(json['sum']),
      formattedSum: SafeConverters.toSafeString(json['formatted_sum']),
      percentage: SafeConverters.toNum(json['percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'article_name': articleName,
      'article_type': articleType,
      'sum': sum,
      'formatted_sum': formattedSum,
      'percentage': percentage,
    };
  }
}

class Period {
  final String from;
  final String to;

  Period({
    required this.from,
    required this.to,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      from: SafeConverters.toSafeString(json['from']),
      to: SafeConverters.toSafeString(json['to']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }
}

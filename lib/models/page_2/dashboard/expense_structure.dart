import 'package:crm_task_manager/utils/safe_converters.dart';

// Enum for period types
enum ExpensePeriodEnum {
  today,
  week,
  month,
  quarter,
  year,
}

// Data class to hold period and expense dashboard data
class AllExpensesData {
  final ExpensePeriodEnum period;
  final ExpenseDashboard data;

  AllExpensesData({
    required this.period,
    required this.data,
  });
}

// ExpenseDashboard and related classes
class ExpenseDashboard {
  final ExpenseResult result;
  final dynamic errors;

  ExpenseDashboard({
    required this.result,
    this.errors,
  });

  factory ExpenseDashboard.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return ExpenseDashboard(
      result: ExpenseResult.fromJson(SafeConverters.toMap(map['result'])),
      errors: map['errors'],
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
  final ExpensePeriod period;

  ExpenseResult({
    required this.totalExpenses,
    required this.expenseStructure,
    required this.topExpenses,
    required this.period,
  });

  factory ExpenseResult.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return ExpenseResult(
      totalExpenses: SafeConverters.toNum(map['total_expenses']),
      expenseStructure: SafeConverters.toModelList(
        map['expense_structure'],
        ExpenseItem.fromJson,
      ),
      topExpenses: SafeConverters.toModelList(
        map['top_expenses'],
        ExpenseItem.fromJson,
      ),
      period: ExpensePeriod.fromJson(SafeConverters.toMap(map['period'])),
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

  factory ExpenseItem.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return ExpenseItem(
      articleName: SafeConverters.toSafeString(map['article_name']),
      articleType: SafeConverters.toSafeString(map['article_type']),
      sum: SafeConverters.toNum(map['sum']),
      formattedSum: SafeConverters.toSafeString(map['formatted_sum']),
      percentage: SafeConverters.toNum(map['percentage']),
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

class ExpensePeriod {
  final String from;
  final String to;

  ExpensePeriod({
    required this.from,
    required this.to,
  });

  factory ExpensePeriod.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return ExpensePeriod(
      from: SafeConverters.toSafeString(map['from']),
      to: SafeConverters.toSafeString(map['to']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }
}
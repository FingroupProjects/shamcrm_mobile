import 'dart:convert';

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

  factory ExpenseDashboard.fromJson(Map<String, dynamic> json) {
    return ExpenseDashboard(
      result: ExpenseResult.fromJson(json['result']),
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
  final ExpensePeriod period;

  ExpenseResult({
    required this.totalExpenses,
    required this.expenseStructure,
    required this.topExpenses,
    required this.period,
  });

  factory ExpenseResult.fromJson(Map<String, dynamic> json) {
    return ExpenseResult(
      totalExpenses: json['total_expenses'],
      expenseStructure: (json['expense_structure'] as List)
          .map((e) => ExpenseItem.fromJson(e))
          .toList(),
      topExpenses: (json['top_expenses'] as List)
          .map((e) => ExpenseItem.fromJson(e))
          .toList(),
      period: ExpensePeriod.fromJson(json['period']),
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
      articleName: json['article_name'],
      articleType: json['article_type'],
      sum: json['sum'],
      formattedSum: json['formatted_sum'],
      percentage: json['percentage'],
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

  factory ExpensePeriod.fromJson(Map<String, dynamic> json) {
    return ExpensePeriod(
      from: json['from'],
      to: json['to'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }
}
class DashboardExpenseResponse {
  final ExpenseResult result;
  final dynamic errors;

  DashboardExpenseResponse({
    required this.result,
    this.errors,
  });

  factory DashboardExpenseResponse.fromJson(Map<String, dynamic> json) {
    return DashboardExpenseResponse(
      result: ExpenseResult.fromJson(json['result'] as Map<String, dynamic>),
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
  final int totalExpenses;
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
      totalExpenses: json['total_expenses'] as int,
      expenseStructure: (json['expense_structure'] as List<dynamic>)
          .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      topExpenses: (json['top_expenses'] as List<dynamic>)
          .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      period: Period.fromJson(json['period'] as Map<String, dynamic>),
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
  final int sum;
  final String formattedSum;
  final int percentage;

  ExpenseItem({
    required this.articleName,
    required this.articleType,
    required this.sum,
    required this.formattedSum,
    required this.percentage,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      articleName: json['article_name'] as String,
      articleType: json['article_type'] as String,
      sum: json['sum'] as int,
      formattedSum: json['formatted_sum'] as String,
      percentage: json['percentage'] as int,
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
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }
}
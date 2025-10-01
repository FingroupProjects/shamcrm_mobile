class ExpenseDashboard {
  final double totalExpenses;
  final double previousExpenses;
  final double expensesChange;
  final bool expensesChangePositive;
  final List<dynamic> expenseStructure;
  final List<dynamic> topExpenses;
  final String comparisonPeriod;
  final Period period;
  final dynamic errors;

  ExpenseDashboard({
    required this.totalExpenses,
    required this.previousExpenses,
    required this.expensesChange,
    required this.expensesChangePositive,
    required this.expenseStructure,
    required this.topExpenses,
    required this.comparisonPeriod,
    required this.period,
    required this.errors,
  });

  factory ExpenseDashboard.fromJson(Map<String, dynamic> json) {
    return ExpenseDashboard(
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      previousExpenses: (json['previous_expenses'] as num).toDouble(),
      expensesChange: (json['expenses_change'] as num).toDouble(),
      expensesChangePositive: json['expenses_change_positive'] as bool,
      expenseStructure: json['expense_structure'] as List<dynamic>,
      topExpenses: json['top_expenses'] as List<dynamic>,
      comparisonPeriod: json['comparison_period'] as String,
      period: Period.fromJson(json['period']),
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_expenses': totalExpenses,
      'previous_expenses': previousExpenses,
      'expenses_change': expensesChange,
      'expenses_change_positive': expensesChangePositive,
      'expense_structure': expenseStructure,
      'top_expenses': topExpenses,
      'comparison_period': comparisonPeriod,
      'period': period.toJson(),
      'errors': errors,
    };
  }
}

// Period class
class Period {
  final PeriodRange current;
  final PeriodRange previous;

  Period({
    required this.current,
    required this.previous,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      current: PeriodRange.fromJson(json['current']),
      previous: PeriodRange.fromJson(json['previous']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current.toJson(),
      'previous': previous.toJson(),
    };
  }
}

// PeriodRange class
class PeriodRange {
  final String? from;
  final String? to;

  PeriodRange({
    this.from,
    this.to,
  });

  factory PeriodRange.fromJson(Map<String, dynamic> json) {
    return PeriodRange(
      from: json['from'] as String?,
      to: json['to'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }
}
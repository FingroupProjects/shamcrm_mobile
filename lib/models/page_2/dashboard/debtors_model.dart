import 'package:equatable/equatable.dart';

class DebtorsResponse extends Equatable {
  final DebtorsResult? result;
  final String? errors; // Changed to String?

  const DebtorsResponse({
    this.result,
    this.errors,
  });

  factory DebtorsResponse.fromJson(Map<String, dynamic> json) {
    return DebtorsResponse(
      result: json['result'] != null ? DebtorsResult.fromJson(json['result'] as Map<String, dynamic>) : null,
      errors: json['errors'] as String?, // Updated to String?
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result?.toJson(),
      'errors': errors,
    };
  }

  @override
  List<Object?> get props => [result, errors];
}

class DebtorsResult extends Equatable {
  final int totalDebt;
  final List<Debtor> debtors;
  final Period period;
  final double percentageChange;
  final bool isPositiveChange;

  const DebtorsResult({
    required this.totalDebt,
    required this.debtors,
    required this.period,
    required this.percentageChange,
    required this.isPositiveChange,
  });

  factory DebtorsResult.fromJson(Map<String, dynamic> json) {
    return DebtorsResult(
      totalDebt: json['total_debt'] as int,
      debtors: (json['debtors'] as List<dynamic>).map((e) => Debtor.fromJson(e as Map<String, dynamic>)).toList(),
      period: Period.fromJson(json['period'] as Map<String, dynamic>),
      percentageChange: (json['percentage_change'] as num).toDouble(), // Handle int or double
      isPositiveChange: json['is_positive_change'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_debt': totalDebt,
      'debtors': debtors.map((e) => e.toJson()).toList(),
      'period': period.toJson(),
      'percentage_change': percentageChange,
      'is_positive_change': isPositiveChange,
    };
  }

  @override
  List<Object> get props => [totalDebt, debtors, period, percentageChange, isPositiveChange];
}

class Debtor extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final int debtAmount;

  const Debtor({
    required this.id,
    required this.name,
    this.phone,
    required this.debtAmount,
  });

  factory Debtor.fromJson(Map<String, dynamic> json) {
    return Debtor(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      debtAmount: json['debt_amount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'debt_amount': debtAmount,
    };
  }

  @override
  List<Object?> get props => [id, name, phone, debtAmount];
}

class Period extends Equatable {
  final DateRange current;
  final DateRange previous;

  const Period({
    required this.current,
    required this.previous,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      current: DateRange.fromJson(json['current'] as Map<String, dynamic>),
      previous: DateRange.fromJson(json['previous'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current.toJson(),
      'previous': previous.toJson(),
    };
  }

  @override
  List<Object> get props => [current, previous];
}

class DateRange extends Equatable {
  final String? from;  // Changed to nullable
  final String? to;    // Changed to nullable

  const DateRange({
    this.from,  // No longer required
    this.to,    // No longer required
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      from: json['from'] as String?,  // Cast to String?
      to: json['to'] as String?,      // Cast to String?
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }

  @override
  List<Object?> get props => [from, to];  // Changed to Object? to handle nulls
}
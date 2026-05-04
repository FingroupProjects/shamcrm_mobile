import 'package:equatable/equatable.dart';

class CreditorsResponse extends Equatable {
  final CreditorsResult? result;
  final String? errors; // Changed to String?

  const CreditorsResponse({
    this.result,
    this.errors,
  });

  factory CreditorsResponse.fromJson(Map<String, dynamic> json) {
    return CreditorsResponse(
      result: json['result'] != null
          ? CreditorsResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
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

class CreditorsResult extends Equatable {
  final num totalDebt;
  final List<Creditor> creditors;
  final Period period;
  final num percentageChange;
  final bool isPositiveChange;
  final CreditorsPagination? pagination;

  const CreditorsResult({
    required this.totalDebt,
    required this.creditors,
    required this.period,
    required this.percentageChange,
    required this.isPositiveChange,
    this.pagination,
  });

  factory CreditorsResult.fromJson(Map<String, dynamic> json) {
    return CreditorsResult(
      totalDebt: json['total_debt'] as num,
      creditors: ((json['creditors'] as List<dynamic>?) ?? [])
          .map((e) => Creditor.fromJson(e as Map<String, dynamic>))
          .toList(),
      period: Period.fromJson(json['period'] as Map<String, dynamic>),
      percentageChange:
          (json['percentage_change'] as num).toDouble(), // Handle int or double
      isPositiveChange: json['is_positive_change'] as bool,
      pagination: json['pagination'] != null
          ? CreditorsPagination.fromJson(
              json['pagination'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_debt': totalDebt,
      'creditors': creditors.map((e) => e.toJson()).toList(),
      'period': period.toJson(),
      'percentage_change': percentageChange,
      'is_positive_change': isPositiveChange,
      'pagination': pagination?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        totalDebt,
        creditors,
        period,
        percentageChange,
        isPositiveChange,
        pagination,
      ];
}

class Creditor extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final num debtAmount;

  const Creditor({
    required this.id,
    required this.name,
    this.phone,
    required this.debtAmount,
  });

  factory Creditor.fromJson(Map<String, dynamic> json) {
    return Creditor(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      debtAmount: json['debt_amount'] as num,
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
  final String? from; // Changed to nullable
  final String? to; // Changed to nullable

  const DateRange({
    this.from, // No longer required
    this.to, // No longer required
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      from: json['from'] as String?, // Cast to String?
      to: json['to'] as String?, // Cast to String?
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }

  @override
  List<Object?> get props => [from, to]; // Changed to Object? to handle nulls
}

class CreditorsPagination extends Equatable {
  final int currentPage;
  final int totalPages;
  final int total;
  final int perPage;

  const CreditorsPagination({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.perPage,
  });

  factory CreditorsPagination.fromJson(Map<String, dynamic> json) {
    return CreditorsPagination(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      perPage: (json['per_page'] as num?)?.toInt() ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'total_pages': totalPages,
      'total': total,
      'per_page': perPage,
    };
  }

  @override
  List<Object> get props => [currentPage, totalPages, total, perPage];
}

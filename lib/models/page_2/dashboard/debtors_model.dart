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
      result: json['result'] != null
          ? DebtorsResult.fromJson(json['result'] as Map<String, dynamic>)
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

class DebtorsResult extends Equatable {
  final num totalDebt;
  final List<DebtByCurrency> totalDebtByCurrency;
  final List<Debtor> debtors;
  final Period period;
  final num percentageChange;
  final bool isPositiveChange;
  final DebtorsPagination? pagination;

  const DebtorsResult({
    required this.totalDebt,
    required this.totalDebtByCurrency,
    required this.debtors,
    required this.period,
    required this.percentageChange,
    required this.isPositiveChange,
    this.pagination,
  });

  factory DebtorsResult.fromJson(Map<String, dynamic> json) {
    return DebtorsResult(
      totalDebt: json['total_debt'] as num,
      totalDebtByCurrency:
          ((json['total_debt_by_currency'] as List<dynamic>?) ?? [])
              .map((e) => DebtByCurrency.fromJson(e as Map<String, dynamic>))
              .toList(),
      debtors: ((json['debtors'] as List<dynamic>?) ?? [])
          .map((e) => Debtor.fromJson(e as Map<String, dynamic>))
          .toList(),
      period: Period.fromJson(json['period'] as Map<String, dynamic>),
      percentageChange:
          (json['percentage_change'] as num).toDouble(), // Handle int or double
      isPositiveChange: json['is_positive_change'] as bool,
      pagination: json['pagination'] != null
          ? DebtorsPagination.fromJson(
              json['pagination'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_debt': totalDebt,
      'total_debt_by_currency':
          totalDebtByCurrency.map((e) => e.toJson()).toList(),
      'debtors': debtors.map((e) => e.toJson()).toList(),
      'period': period.toJson(),
      'percentage_change': percentageChange,
      'is_positive_change': isPositiveChange,
      'pagination': pagination?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        totalDebt,
        totalDebtByCurrency,
        debtors,
        period,
        percentageChange,
        isPositiveChange,
        pagination,
      ];
}

class DebtByCurrency extends Equatable {
  final int? currencyId;
  final String currency;
  final num totalDebt;

  const DebtByCurrency({
    required this.currencyId,
    required this.currency,
    required this.totalDebt,
  });

  factory DebtByCurrency.fromJson(Map<String, dynamic> json) {
    return DebtByCurrency(
      currencyId: (json['currency_id'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? '',
      totalDebt: json['total_debt'] as num? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency_id': currencyId,
      'currency': currency,
      'total_debt': totalDebt,
    };
  }

  @override
  List<Object?> get props => [currencyId, currency, totalDebt];
}

class Debtor extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final num debtAmount;

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

class DebtorsPagination extends Equatable {
  final int currentPage;
  final int totalPages;
  final int total;
  final int perPage;

  const DebtorsPagination({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.perPage,
  });

  factory DebtorsPagination.fromJson(Map<String, dynamic> json) {
    return DebtorsPagination(
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

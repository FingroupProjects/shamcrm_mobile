import 'package:crm_task_manager/utils/safe_converters.dart';
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
      result: SafeConverters.toMapOrNull(json['result']) != null
          ? CreditorsResult.fromJson(SafeConverters.toMap(json['result']))
          : null,
      errors: SafeConverters.toStringOrNull(json['errors']),
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
  final List<DebtByCurrency> totalDebtByCurrency;
  final List<Creditor> creditors;
  final Period period;
  final num percentageChange;
  final bool isPositiveChange;
  final CreditorsPagination? pagination;

  const CreditorsResult({
    required this.totalDebt,
    required this.totalDebtByCurrency,
    required this.creditors,
    required this.period,
    required this.percentageChange,
    required this.isPositiveChange,
    this.pagination,
  });

  factory CreditorsResult.fromJson(Map<String, dynamic> json) {
    return CreditorsResult(
      totalDebt: SafeConverters.toNum(json['total_debt']),
      totalDebtByCurrency: SafeConverters.toList(json['total_debt_by_currency'])
          .map((e) => DebtByCurrency.fromJson(SafeConverters.toMap(e)))
          .toList(),
      creditors: SafeConverters.toList(json['creditors'])
          .map((e) => Creditor.fromJson(SafeConverters.toMap(e)))
          .toList(),
      period: Period.fromJson(SafeConverters.toMap(json['period'])),
      percentageChange: SafeConverters.toDouble(json['percentage_change']),
      isPositiveChange: SafeConverters.toBool(json['is_positive_change']),
      pagination: SafeConverters.toMapOrNull(json['pagination']) != null
          ? CreditorsPagination.fromJson(SafeConverters.toMap(json['pagination']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_debt': totalDebt,
      'total_debt_by_currency':
          totalDebtByCurrency.map((e) => e.toJson()).toList(),
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
        totalDebtByCurrency,
        creditors,
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
      currencyId: SafeConverters.toIntOrNull(json['currency_id']),
      currency: SafeConverters.toSafeString(json['currency']),
      totalDebt: SafeConverters.toNum(json['total_debt']),
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      phone: SafeConverters.toStringOrNull(json['phone']),
      debtAmount: SafeConverters.toNum(json['debt_amount']),
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
      current: DateRange.fromJson(SafeConverters.toMap(json['current'])),
      previous: DateRange.fromJson(SafeConverters.toMap(json['previous'])),
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
      from: SafeConverters.toStringOrNull(json['from']),
      to: SafeConverters.toStringOrNull(json['to']),
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
      currentPage: SafeConverters.toInt(json['current_page'], defaultValue: 1),
      totalPages: SafeConverters.toInt(json['total_pages'], defaultValue: 1),
      total: SafeConverters.toInt(json['total']),
      perPage: SafeConverters.toInt(json['per_page'], defaultValue: 20),
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

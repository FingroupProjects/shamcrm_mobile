import 'package:crm_task_manager/utils/safe_converters.dart';
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
      result: SafeConverters.toMapOrNull(json['result']) != null
          ? DebtorsResult.fromJson(SafeConverters.toMap(json['result']))
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

class DebtorsResult extends Equatable {
  final num totalDebt;
  final List<Debtor> debtors;
  final Period period;
  final num percentageChange;
  final bool isPositiveChange;
  final DebtorsPagination? pagination;

  const DebtorsResult({
    required this.totalDebt,
    required this.debtors,
    required this.period,
    required this.percentageChange,
    required this.isPositiveChange,
    this.pagination,
  });

  factory DebtorsResult.fromJson(Map<String, dynamic> json) {
    return DebtorsResult(
      totalDebt: SafeConverters.toNum(json['total_debt']),
      debtors: SafeConverters.toList(json['debtors'])
          .map((e) => Debtor.fromJson(SafeConverters.toMap(e)))
          .toList(),
      period: Period.fromJson(SafeConverters.toMap(json['period'])),
      percentageChange: SafeConverters.toDouble(json['percentage_change']),
      isPositiveChange: SafeConverters.toBool(json['is_positive_change']),
      pagination: SafeConverters.toMapOrNull(json['pagination']) != null
          ? DebtorsPagination.fromJson(SafeConverters.toMap(json['pagination']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_debt': totalDebt,
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
        debtors,
        period,
        percentageChange,
        isPositiveChange,
        pagination,
      ];
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

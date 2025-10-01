import 'package:equatable/equatable.dart';

class CreditorsResponse extends Equatable {
  final CreditorsResult? result;
  final List<String>? errors;

  const CreditorsResponse({
    this.result,
    this.errors,
  });

  factory CreditorsResponse.fromJson(Map<String, dynamic> json) {
    return CreditorsResponse(
      result: json['result'] != null ? CreditorsResult.fromJson(json['result'] as Map<String, dynamic>) : null,
      errors: json['errors'] as List<String>?,
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
  final int totalDebt;
  final List<Creditor> creditors;
  final Period period;
  final double percentageChange;
  final bool isPositiveChange;
  final AppliedFilters appliedFilters;

  const CreditorsResult({
    required this.totalDebt,
    required this.creditors,
    required this.period,
    required this.percentageChange,
    required this.isPositiveChange,
    required this.appliedFilters,
  });

  factory CreditorsResult.fromJson(Map<String, dynamic> json) {
    return CreditorsResult(
      totalDebt: json['total_debt'] as int,
      creditors: (json['creditors'] as List<dynamic>).map((e) => Creditor.fromJson(e as Map<String, dynamic>)).toList(),
      period: Period.fromJson(json['period'] as Map<String, dynamic>),
      percentageChange: json['percentage_change'] as double,
      isPositiveChange: json['is_positive_change'] as bool,
      appliedFilters: AppliedFilters.fromJson(json['applied_filters'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_debt': totalDebt,
      'creditors': creditors.map((e) => e.toJson()).toList(),
      'period': period.toJson(),
      'percentage_change': percentageChange,
      'is_positive_change': isPositiveChange,
      'applied_filters': appliedFilters.toJson(),
    };
  }

  @override
  List<Object> get props => [totalDebt, creditors, period, percentageChange, isPositiveChange, appliedFilters];
}
class Creditor extends Equatable {
  final int id;
  final String name;
  final String? phone; // Changed to nullable
  final int debtAmount;

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
  final String from;
  final String to;

  const DateRange({
    required this.from,
    required this.to,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
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

  @override
  List<Object> get props => [from, to];
}

class AppliedFilters extends Equatable {
  final int? cashRegisterId;
  final int? supplierId;
  final int? clientId;
  final int? leadId;
  final String? operationType;
  final String? search;

  const AppliedFilters({
    this.cashRegisterId,
    this.supplierId,
    this.clientId,
    this.leadId,
    this.operationType,
    this.search,
  });

  factory AppliedFilters.fromJson(Map<String, dynamic> json) {
    return AppliedFilters(
      cashRegisterId: json['cash_register_id'] as int?,
      supplierId: json['supplier_id'] as int?,
      clientId: json['client_id'] as int?,
      leadId: json['lead_id'] as int?,
      operationType: json['operation_type'] as String?,
      search: json['search'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cash_register_id': cashRegisterId,
      'supplier_id': supplierId,
      'client_id': clientId,
      'lead_id': leadId,
      'operation_type': operationType,
      'search': search,
    };
  }

  @override
  List<Object?> get props => [cashRegisterId, supplierId, clientId, leadId, operationType, search];
}

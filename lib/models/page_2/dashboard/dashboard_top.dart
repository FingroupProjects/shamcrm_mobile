import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/models/supplier_list_model.dart';

class DashboardTopPart {
  final Result? result;
  final String? errors;

  DashboardTopPart({this.result, this.errors});

  factory DashboardTopPart.fromJson(Map<String, dynamic> json) {
    return DashboardTopPart(
      result: json['result'] != null ? Result.fromJson(json['result']) : null,
      errors: json['errors'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result?.toJson(),
      'errors': errors,
    };
  }
}

class Result {
  final CashBalance? cashBalance;
  final OurDebts? ourDebts;
  final DebtsToUs? debtsToUs;
  final List<dynamic> filters; // Changed to List<dynamic> to match JSON

  Result({
    this.cashBalance,
    this.ourDebts,
    this.debtsToUs,
    required this.filters, // Non-nullable since JSON always provides it
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      cashBalance: json['cash_balance'] != null
          ? CashBalance.fromJson(json['cash_balance'])
          : null,
      ourDebts: json['our_debts'] != null
          ? OurDebts.fromJson(json['our_debts'])
          : null,
      debtsToUs: json['debts_to_us'] != null
          ? DebtsToUs.fromJson(json['debts_to_us'])
          : null,
      filters: json['filters'] as List<dynamic>? ?? [], // Safe cast, default to empty list
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cash_balance': cashBalance?.toJson(),
      'our_debts': ourDebts?.toJson(),
      'debts_to_us': debtsToUs?.toJson(),
      'filters': filters,
    };
  }
}

class CashBalance {
  final num totalBalance; // Changed to double for precision
  final num previousBalance;
  final num percentageChange;
  final bool isPositiveChange;
  final String? currency; // Nullable since not always present
  final List<CashRegisterData> cashRegisters;
  final List<IncomingDocument> movements;
  final String comparisonPeriod;
  final Period? period;

  CashBalance({
    required this.totalBalance,
    required this.previousBalance,
    required this.percentageChange,
    required this.isPositiveChange,
    this.currency,
    required this.cashRegisters,
    required this.movements,
    required this.comparisonPeriod,
    this.period,
  });

  factory CashBalance.fromJson(Map<String, dynamic> json) {
    return CashBalance(
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      previousBalance: (json['previous_balance'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['percentage_change'] as num?)?.toDouble() ?? 0.0,
      isPositiveChange: json['is_positive_change'] as bool? ?? false,
      currency: json['currency'] as String?,
      cashRegisters: (json['cash_registers'] as List<dynamic>?)
          ?.map((v) => CashRegisterData.fromJson(v as Map<String, dynamic>))
          .toList() ??
          [],
      movements: (json['movements'] as List<dynamic>?)
          ?.map((v) => IncomingDocument.fromJson(v as Map<String, dynamic>))
          .toList() ??
          [],
      comparisonPeriod: json['comparison_period'] as String? ?? '',
      period: json['period'] != null ? Period.fromJson(json['period']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_balance': totalBalance,
      'previous_balance': previousBalance,
      'percentage_change': percentageChange,
      'is_positive_change': isPositiveChange,
      'currency': currency,
      'cash_registers': cashRegisters.map((v) => v.toJson()).toList(),
      'movements': movements.map((v) => v.toJson()).toList(),
      'comparison_period': comparisonPeriod,
      'period': period?.toJson(),
    };
  }
}

class Period {
  final Current? current;
  final Current? previous;

  Period({this.current, this.previous});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      current: json['current'] != null ? Current.fromJson(json['current']) : null,
      previous:
      json['previous'] != null ? Current.fromJson(json['previous']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current?.toJson(),
      'previous': previous?.toJson(),
    };
  }
}

class Current {
  final String? from;
  final String? to;

  Current({this.from, this.to});

  factory Current.fromJson(Map<String, dynamic> json) {
    return Current(
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

class OurDebts {
  final num currentDebts;
  final num previousDebts;
  final num percentageChange;
  final bool isPositiveChange;
  final String? currency;
  final List<SupplierData> suppliersList;
  final String comparisonPeriod;
  final Period? period;

  OurDebts({
    required this.currentDebts,
    required this.previousDebts,
    required this.percentageChange,
    required this.isPositiveChange,
    this.currency,
    required this.suppliersList,
    required this.comparisonPeriod,
    this.period,
  });

  factory OurDebts.fromJson(Map<String, dynamic> json) {
    return OurDebts(
      currentDebts: (json['current_debts'] as num?)?.toDouble() ?? 0.0,
      previousDebts: (json['previous_debts'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['percentage_change'] as num?)?.toDouble() ?? 0.0,
      isPositiveChange: json['is_positive_change'] as bool? ?? false,
      currency: json['currency'] as String?,
      suppliersList: (json['suppliers_list'] as List<dynamic>?)
          ?.map((v) => SupplierData.fromJson(v as Map<String, dynamic>))
          .toList() ??
          [],
      comparisonPeriod: json['comparison_period'] as String? ?? '',
      period: json['period'] != null ? Period.fromJson(json['period']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_debts': currentDebts,
      'previous_debts': previousDebts,
      'percentage_change': percentageChange,
      'is_positive_change': isPositiveChange,
      'currency': currency,
      'suppliers_list': suppliersList.map((v) => v.toJson()).toList(),
      'comparison_period': comparisonPeriod,
      'period': period?.toJson(),
    };
  }
}

class DebtsToUs {
  final num totalDebtsToUs;
  final num previousDebtsToUs;
  final num percentageChange;
  final bool isPositiveChange;
  final String? currency;
  final List<Debtors> debtorsList;
  final String comparisonPeriod;
  final Period? period;

  DebtsToUs({
    required this.totalDebtsToUs,
    required this.previousDebtsToUs,
    required this.percentageChange,
    required this.isPositiveChange,
    this.currency,
    required this.debtorsList,
    required this.comparisonPeriod,
    this.period,
  });

  factory DebtsToUs.fromJson(Map<String, dynamic> json) {
    return DebtsToUs(
      totalDebtsToUs: (json['total_debts_to_us'] as num?)?.toDouble() ?? 0.0,
      previousDebtsToUs:
      (json['previous_debts_to_us'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['percentage_change'] as num?)?.toDouble() ?? 0.0,
      isPositiveChange: json['is_positive_change'] as bool? ?? false,
      currency: json['currency'] as String?,
      debtorsList: (json['debtors_list'] as List<dynamic>?)
          ?.map((v) => Debtors.fromJson(v as Map<String, dynamic>))
          .toList() ??
          [],
      comparisonPeriod: json['comparison_period'] as String? ?? '',
      period: json['period'] != null ? Period.fromJson(json['period']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_debts_to_us': totalDebtsToUs,
      'previous_debts_to_us': previousDebtsToUs,
      'percentage_change': percentageChange,
      'is_positive_change': isPositiveChange,
      'currency': currency,
      'debtors_list': debtorsList.map((v) => v.toJson()).toList(),
      'comparison_period': comparisonPeriod,
      'period': period?.toJson(),
    };
  }
}

// Placeholder Filters class in case API changes to return a Map
class Filters {
  final String? period;
  final String? dateFrom;
  final String? dateTo;

  Filters({this.period, this.dateFrom, this.dateTo});

  factory Filters.fromJson(Map<String, dynamic> json) {
    return Filters(
      period: json['period'] as String?,
      dateFrom: json['date_from'] as String?,
      dateTo: json['date_to'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'date_from': dateFrom,
      'date_to': dateTo,
    };
  }
}

class Debtors {
  int? id;
  String? name;
  String? type;
  String? phone;
  num? debtAmount;

  Debtors({this.id, this.name, this.type, this.phone, this.debtAmount});

  Debtors.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    type = json['type'];
    phone = json['phone'];
    debtAmount = json['debt_amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['type'] = this.type;
    data['phone'] = this.phone;
    data['debt_amount'] = this.debtAmount;
    return data;
  }
}

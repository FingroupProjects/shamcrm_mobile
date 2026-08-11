import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/models/supplier_list_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

class DashboardTopPart {
  final Result? result;
  final String? errors;

  DashboardTopPart({this.result, this.errors});

  factory DashboardTopPart.fromJson(Map<String, dynamic> json) {
    return DashboardTopPart(
      result: SafeConverters.toMapOrNull(json['result']) != null
          ? Result.fromJson(SafeConverters.toMap(json['result']))
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
      cashBalance: SafeConverters.toMapOrNull(json['cash_balance']) != null
          ? CashBalance.fromJson(SafeConverters.toMap(json['cash_balance']))
          : null,
      ourDebts: SafeConverters.toMapOrNull(json['our_debts']) != null
          ? OurDebts.fromJson(SafeConverters.toMap(json['our_debts']))
          : null,
      debtsToUs: SafeConverters.toMapOrNull(json['debts_to_us']) != null
          ? DebtsToUs.fromJson(SafeConverters.toMap(json['debts_to_us']))
          : null,
      filters: SafeConverters.toList(json['filters']),
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
      totalBalance: SafeConverters.toNum(json['total_balance']),
      previousBalance: SafeConverters.toNum(json['previous_balance']),
      percentageChange: SafeConverters.toNum(json['percentage_change']),
      isPositiveChange: SafeConverters.toBool(json['is_positive_change']),
      currency: SafeConverters.toStringOrNull(json['currency']),
      cashRegisters: SafeConverters.toList(json['cash_registers'])
          .map((v) => CashRegisterData.fromJson(SafeConverters.toMap(v)))
          .toList(),
      movements: SafeConverters.toList(json['movements'])
          .map((v) => IncomingDocument.fromJson(SafeConverters.toMap(v)))
          .toList(),
      comparisonPeriod: SafeConverters.toSafeString(json['comparison_period']),
      period: SafeConverters.toMapOrNull(json['period']) != null
          ? Period.fromJson(SafeConverters.toMap(json['period']))
          : null,
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
      current: SafeConverters.toMapOrNull(json['current']) != null
          ? Current.fromJson(SafeConverters.toMap(json['current']))
          : null,
      previous: SafeConverters.toMapOrNull(json['previous']) != null
          ? Current.fromJson(SafeConverters.toMap(json['previous']))
          : null,
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
      currentDebts: SafeConverters.toNum(json['current_debts']),
      previousDebts: SafeConverters.toNum(json['previous_debts']),
      percentageChange: SafeConverters.toNum(json['percentage_change']),
      isPositiveChange: SafeConverters.toBool(json['is_positive_change']),
      currency: SafeConverters.toStringOrNull(json['currency']),
      suppliersList: SafeConverters.toList(json['suppliers_list'])
          .map((v) => SupplierData.fromJson(SafeConverters.toMap(v)))
          .toList(),
      comparisonPeriod: SafeConverters.toSafeString(json['comparison_period']),
      period: SafeConverters.toMapOrNull(json['period']) != null
          ? Period.fromJson(SafeConverters.toMap(json['period']))
          : null,
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
      totalDebtsToUs: SafeConverters.toNum(json['total_debts_to_us']),
      previousDebtsToUs: SafeConverters.toNum(json['previous_debts_to_us']),
      percentageChange: SafeConverters.toNum(json['percentage_change']),
      isPositiveChange: SafeConverters.toBool(json['is_positive_change']),
      currency: SafeConverters.toStringOrNull(json['currency']),
      debtorsList: SafeConverters.toList(json['debtors_list'])
          .map((v) => Debtors.fromJson(SafeConverters.toMap(v)))
          .toList(),
      comparisonPeriod: SafeConverters.toSafeString(json['comparison_period']),
      period: SafeConverters.toMapOrNull(json['period']) != null
          ? Period.fromJson(SafeConverters.toMap(json['period']))
          : null,
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
      period: SafeConverters.toStringOrNull(json['period']),
      dateFrom: SafeConverters.toStringOrNull(json['date_from']),
      dateTo: SafeConverters.toStringOrNull(json['date_to']),
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
    id = SafeConverters.toIntOrNull(json['id']);
    name = SafeConverters.toStringOrNull(json['name']);
    type = SafeConverters.toStringOrNull(json['type']);
    phone = SafeConverters.toStringOrNull(json['phone']);
    debtAmount = SafeConverters.toNumOrNull(json['debt_amount']);
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

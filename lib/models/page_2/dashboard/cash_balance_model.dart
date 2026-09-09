import 'package:crm_task_manager/utils/safe_converters.dart';

class CashBalanceResponse {
  Result? result;
  String? errors;

  CashBalanceResponse({this.result, this.errors});

  CashBalanceResponse.fromJson(Map<String, dynamic> json) {
    result = SafeConverters.toMapOrNull(json['result']) != null ? Result.fromJson(SafeConverters.toMap(json['result'])) : null;
    errors = SafeConverters.toStringOrNull(json['errors']);
  }

  Map<String, dynamic> toJson() => {
        if (result != null) 'result': result!.toJson(),
        'errors': errors,
      };
}

class Result {
  CashBalanceSummary? cashBalanceSummary;
  CheckingAccounts? checkingAccounts;

  Result({this.cashBalanceSummary, this.checkingAccounts});

  Result.fromJson(Map<String, dynamic> json) {
    cashBalanceSummary = SafeConverters.toMapOrNull(json['cash_balance_summary']) != null ? CashBalanceSummary.fromJson(SafeConverters.toMap(json['cash_balance_summary'])) : null;
    checkingAccounts = SafeConverters.toMapOrNull(json['checking_accounts']) != null ? CheckingAccounts.fromJson(SafeConverters.toMap(json['checking_accounts'])) : null;
  }

  Map<String, dynamic> toJson() => {
        if (cashBalanceSummary != null)
          'cash_balance_summary': cashBalanceSummary!.toJson(),
        if (checkingAccounts != null)
          'checking_accounts': checkingAccounts!.toJson(),
      };
}

class CashBalanceSummary {
  num? totalBalance;
  num? previousBalance;
  num? percentageChange;
  bool? isPositiveChange;
  List<CashRegisters>? cashRegisters;
  List<Movements>? movements;
  String? comparisonPeriod;
  Period? period;

  CashBalanceSummary({
    this.totalBalance,
    this.previousBalance,
    this.percentageChange,
    this.isPositiveChange,
    this.cashRegisters,
    this.movements,
    this.comparisonPeriod,
    this.period,
  });

  CashBalanceSummary.fromJson(Map<String, dynamic> json) {
    totalBalance = SafeConverters.toNumOrNull(json['total_balance']);
    previousBalance = SafeConverters.toNumOrNull(json['previous_balance']);
    percentageChange = SafeConverters.toNumOrNull(json['percentage_change']);
    isPositiveChange = SafeConverters.toBoolOrNull(json['is_positive_change']);
    if (json['cash_registers'] != null) {
      cashRegisters = SafeConverters.toModelList(json['cash_registers'], CashRegisters.fromJson);
    }
    if (json['movements'] != null) {
      movements = SafeConverters.toModelList(json['movements'], Movements.fromJson);
    }
    comparisonPeriod = SafeConverters.toStringOrNull(json['comparison_period']);
    period = SafeConverters.toMapOrNull(json['period']) != null ? Period.fromJson(SafeConverters.toMap(json['period'])) : null;
  }

  Map<String, dynamic> toJson() => {
        'total_balance': totalBalance,
        'previous_balance': previousBalance,
        'percentage_change': percentageChange,
        'is_positive_change': isPositiveChange,
        if (cashRegisters != null)
          'cash_registers': cashRegisters!.map((v) => v.toJson()).toList(),
        if (movements != null)
          'movements': movements!.map((v) => v.toJson()).toList(),
        'comparison_period': comparisonPeriod,
        if (period != null) 'period': period!.toJson(),
      };
}

class CashRegisters {
  int? id;
  String? name;
  num? balance;
  String? updatedAt;
  String? currencyName;

  CashRegisters({
    this.id,
    this.name,
    this.balance,
    this.updatedAt,
    this.currencyName,
  });

  CashRegisters.fromJson(Map<String, dynamic> json) {
    id = SafeConverters.toIntOrNull(json['id']);
    name = SafeConverters.toStringOrNull(json['name']);
    balance = SafeConverters.toNumOrNull(json['balance']);
    updatedAt = SafeConverters.toStringOrNull(json['updated_at']);
    currencyName = SafeConverters.toMapOrNull(json['currency']) != null ? SafeConverters.toStringOrNull(SafeConverters.toMap(json['currency'])['name']) : null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'balance': balance,
        'updated_at': updatedAt,
        'currency_name': currencyName,
      };
}

class Movements {
  int? id;
  String? date;
  String? time;
  String? operation;
  String? counterparty;
  num? amount;
  String? formattedAmount;
  String? method;
  String? operationType;
  bool? isIncome;

  Movements({
    this.id,
    this.date,
    this.time,
    this.operation,
    this.counterparty,
    this.amount,
    this.formattedAmount,
    this.method,
    this.operationType,
    this.isIncome,
  });

  Movements.fromJson(Map<String, dynamic> json) {
    id = SafeConverters.toIntOrNull(json['id']);
    date = SafeConverters.toStringOrNull(json['date']);
    time = SafeConverters.toStringOrNull(json['time']);
    operation = SafeConverters.toStringOrNull(json['operation']);
    counterparty = SafeConverters.toStringOrNull(json['counterparty']);
    amount = SafeConverters.toNumOrNull(json['amount']);
    formattedAmount = SafeConverters.toStringOrNull(json['formatted_amount']);
    method = SafeConverters.toStringOrNull(json['method']);
    operationType = SafeConverters.toStringOrNull(json['operation_type']);
    isIncome = SafeConverters.toBoolOrNull(json['is_income']);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'time': time,
        'operation': operation,
        'counterparty': counterparty,
        'amount': amount,
        'formatted_amount': formattedAmount,
        'method': method,
        'operation_type': operationType,
        'is_income': isIncome,
      };
}

class Period {
  Current? current;
  Current? previous;

  Period({this.current, this.previous});

  Period.fromJson(Map<String, dynamic> json) {
    current = SafeConverters.toMapOrNull(json['current']) != null ? Current.fromJson(SafeConverters.toMap(json['current'])) : null;
    previous = SafeConverters.toMapOrNull(json['previous']) != null ? Current.fromJson(SafeConverters.toMap(json['previous'])) : null;
  }

  Map<String, dynamic> toJson() => {
        if (current != null) 'current': current!.toJson(),
        if (previous != null) 'previous': previous!.toJson(),
      };
}

class Current {
  String? from;
  String? to;

  Current({this.from, this.to});

  Current.fromJson(Map<String, dynamic> json) {
    from = SafeConverters.toStringOrNull(json['from']);
    to = json['to'];
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
      };
}

class CheckingAccounts {
  int? currentPage;
  List<Data>? data;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  String? lastPageUrl;
  List<Links>? links;
  String? nextPageUrl;
  String? path;
  int? perPage;
  String? prevPageUrl;
  num? to;
  num? total;

  CheckingAccounts({
    this.currentPage,
    this.data,
    this.firstPageUrl,
    this.from,
    this.lastPage,
    this.lastPageUrl,
    this.links,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
  });

  CheckingAccounts.fromJson(Map<String, dynamic> json) {
    currentPage = SafeConverters.toIntOrNull(json['current_page']);
    if (json['data'] != null) {
      data = SafeConverters.toModelList(json['data'], Data.fromJson);
    }
    firstPageUrl = SafeConverters.toStringOrNull(json['first_page_url']);
    from = SafeConverters.toIntOrNull(json['from']);
    lastPage = SafeConverters.toIntOrNull(json['last_page']);
    lastPageUrl = SafeConverters.toStringOrNull(json['last_page_url']);
    if (json['links'] != null) {
      links = SafeConverters.toModelList(json['links'], Links.fromJson);
    }
    nextPageUrl = SafeConverters.toStringOrNull(json['next_page_url']);
    path = SafeConverters.toStringOrNull(json['path']);
    perPage = SafeConverters.toIntOrNull(json['per_page']);
    prevPageUrl = SafeConverters.toStringOrNull(json['prev_page_url']);
    to = SafeConverters.toNumOrNull(json['to']);
    total = SafeConverters.toNumOrNull(json['total']);
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        if (data != null) 'data': data!.map((v) => v.toJson()).toList(),
        'first_page_url': firstPageUrl,
        'from': from,
        'last_page': lastPage,
        'last_page_url': lastPageUrl,
        if (links != null) 'links': links!.map((v) => v.toJson()).toList(),
        'next_page_url': nextPageUrl,
        'path': path,
        'per_page': perPage,
        'prev_page_url': prevPageUrl,
        'to': to,
        'total': total,
      };
}

// Add this new class for Article
class Article {
  int? id;
  String? name;

  Article({this.id, this.name});

  Article.fromJson(Map<String, dynamic> json) {
    id = SafeConverters.toIntOrNull(json['id']);
    name = SafeConverters.toStringOrNull(json['name']);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

// Updated Data class
class Data {
  int? id;
  String? docNumber;
  String? date;
  String? amount;
  String? formattedAmount;
  String? operationType;
  String? comment;
  bool? approved;
  String? createdAt;
  CashRegister? cashRegister;
  Article? article; // Changed from String? to Article?
  Counterparty? counterparty;
  bool? isIncome;

  Data({
    this.id,
    this.docNumber,
    this.date,
    this.amount,
    this.formattedAmount,
    this.operationType,
    this.comment,
    this.approved,
    this.createdAt,
    this.cashRegister,
    this.article,
    this.counterparty,
    this.isIncome,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = SafeConverters.toIntOrNull(json['id']);
    docNumber = SafeConverters.toStringOrNull(json['doc_number']);
    date = SafeConverters.toStringOrNull(json['date']);
    amount = SafeConverters.toStringOrNull(json['amount']);
    formattedAmount = SafeConverters.toStringOrNull(json['formatted_amount']);
    operationType = SafeConverters.toStringOrNull(json['operation_type']);
    comment = SafeConverters.toStringOrNull(json['comment']);
    approved = SafeConverters.toBoolOrNull(json['approved']);
    createdAt = SafeConverters.toStringOrNull(json['created_at']);
    cashRegister = SafeConverters.toMapOrNull(json['cash_register']) != null ? CashRegister.fromJson(SafeConverters.toMap(json['cash_register'])) : null;
    article = SafeConverters.toMapOrNull(json['article']) != null ? Article.fromJson(SafeConverters.toMap(json['article'])) : null;
    counterparty = SafeConverters.toMapOrNull(json['counterparty']) != null ? Counterparty.fromJson(SafeConverters.toMap(json['counterparty'])) : null;
    isIncome = SafeConverters.toBoolOrNull(json['is_income']);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doc_number': docNumber,
        'date': date,
        'amount': amount,
        'formatted_amount': formattedAmount,
        'operation_type': operationType,
        'comment': comment,
        'approved': approved,
        'created_at': createdAt,
        if (cashRegister != null) 'cash_register': cashRegister!.toJson(),
        if (article != null)
          'article': article!.toJson(), // Changed serialization
        if (counterparty != null) 'counterparty': counterparty!.toJson(),
        'is_income': isIncome,
      };
}

class CashRegister {
  int? id;
  String? name;
  String? type;

  CashRegister({this.id, this.name, this.type});

  CashRegister.fromJson(Map<String, dynamic> json) {
    id = SafeConverters.toIntOrNull(json['id']);
    name = SafeConverters.toStringOrNull(json['name']);
    type = SafeConverters.toStringOrNull(json['type']);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
      };
}

class Counterparty {
  String? type;
  int? id;
  String? name;
  String? phone;
  int? inn;

  Counterparty({this.type, this.id, this.name, this.phone, this.inn});

  Counterparty.fromJson(Map<String, dynamic> json) {
    type = SafeConverters.toStringOrNull(json['type']);
    id = SafeConverters.toIntOrNull(json['id']);
    name = SafeConverters.toStringOrNull(json['name']);
    phone = SafeConverters.toStringOrNull(json['phone']);
    inn = SafeConverters.toIntOrNull(json['inn']);
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'name': name,
        'phone': phone,
        'inn': inn,
      };
}

class Links {
  String? url;
  String? label;
  bool? active;

  Links({this.url, this.label, this.active});

  Links.fromJson(Map<String, dynamic> json) {
    url = SafeConverters.toStringOrNull(json['url']);
    label = SafeConverters.toStringOrNull(json['label']);
    active = SafeConverters.toBoolOrNull(json['active']);
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'label': label,
        'active': active,
      };
}

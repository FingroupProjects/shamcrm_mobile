class CashBalanceResponse {
  Result? result;
  String? errors;

  CashBalanceResponse({this.result, this.errors});

  CashBalanceResponse.fromJson(Map<String, dynamic> json) {
    result = json['result'] != null ? Result.fromJson(json['result']) : null;
    errors = json['errors'];
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
    cashBalanceSummary = json['cash_balance_summary'] != null
        ? CashBalanceSummary.fromJson(json['cash_balance_summary'])
        : null;
    checkingAccounts = json['checking_accounts'] != null
        ? CheckingAccounts.fromJson(json['checking_accounts'])
        : null;
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
    totalBalance = json['total_balance'];
    previousBalance = json['previous_balance'];
    percentageChange = json['percentage_change'];
    isPositiveChange = json['is_positive_change'];
    if (json['cash_registers'] != null) {
      cashRegisters = (json['cash_registers'] as List)
          .map((v) => CashRegisters.fromJson(v))
          .toList();
    }
    if (json['movements'] != null) {
      movements =
          (json['movements'] as List).map((v) => Movements.fromJson(v)).toList();
    }
    comparisonPeriod = json['comparison_period'];
    period = json['period'] != null ? Period.fromJson(json['period']) : null;
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

  CashRegisters({this.id, this.name, this.balance, this.updatedAt});

  CashRegisters.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    balance = json['balance'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'balance': balance,
    'updated_at': updatedAt,
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
    id = json['id'];
    date = json['date'];
    time = json['time'];
    operation = json['operation'];
    counterparty = json['counterparty'];
    amount = json['amount'];
    formattedAmount = json['formatted_amount'];
    method = json['method'];
    operationType = json['operation_type'];
    isIncome = json['is_income'];
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
    current =
    json['current'] != null ? Current.fromJson(json['current']) : null;
    previous =
    json['previous'] != null ? Current.fromJson(json['previous']) : null;
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
    from = json['from'];
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
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = (json['data'] as List).map((v) => Data.fromJson(v)).toList();
    }
    firstPageUrl = json['first_page_url'];
    from = json['from'];
    lastPage = json['last_page'];
    lastPageUrl = json['last_page_url'];
    if (json['links'] != null) {
      links = (json['links'] as List).map((v) => Links.fromJson(v)).toList();
    }
    nextPageUrl = json['next_page_url'];
    path = json['path'];
    perPage = json['per_page'];
    prevPageUrl = json['prev_page_url'];
    to = json['to'];
    total = json['total'];
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
    id = json['id'];
    name = json['name'];
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
  Article? article;  // Changed from String? to Article?
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
    id = json['id'];
    docNumber = json['doc_number'];
    date = json['date'];
    amount = json['amount'];
    formattedAmount = json['formatted_amount'];
    operationType = json['operation_type'];
    comment = json['comment'];
    approved = json['approved'];
    createdAt = json['created_at'];
    cashRegister = json['cash_register'] != null
        ? CashRegister.fromJson(json['cash_register'])
        : null;
    article = json['article'] != null
        ? Article.fromJson(json['article'])  // Changed parsing logic
        : null;
    counterparty = json['counterparty'] != null
        ? Counterparty.fromJson(json['counterparty'])
        : null;
    isIncome = json['is_income'];
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
    if (article != null) 'article': article!.toJson(),  // Changed serialization
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
    id = json['id'];
    name = json['name'];
    type = json['type'];
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
    type = json['type'];
    id = json['id'];
    name = json['name'];
    phone = json['phone'];
    inn = json['inn'];
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
    url = json['url'];
    label = json['label'];
    active = json['active'];
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'label': label,
    'active': active,
  };
}

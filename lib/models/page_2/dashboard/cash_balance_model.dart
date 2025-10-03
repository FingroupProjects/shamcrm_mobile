class CashBalanceResponse {
  Result? result;
  String? errors;

  CashBalanceResponse({this.result, this.errors});

  CashBalanceResponse.fromJson(Map<String, dynamic> json) {
    result =
    json['result'] != null ? new Result.fromJson(json['result']) : null;
    errors = json['errors'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.result != null) {
      data['result'] = this.result!.toJson();
    }
    data['errors'] = this.errors;
    return data;
  }
}

class Result {
  CashBalanceSummary? cashBalanceSummary;
  CheckingAccounts? checkingAccounts;

  Result({this.cashBalanceSummary, this.checkingAccounts});

  Result.fromJson(Map<String, dynamic> json) {
    cashBalanceSummary = json['cash_balance_summary'] != null
        ? new CashBalanceSummary.fromJson(json['cash_balance_summary'])
        : null;
    checkingAccounts = json['checking_accounts'] != null
        ? new CheckingAccounts.fromJson(json['checking_accounts'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.cashBalanceSummary != null) {
      data['cash_balance_summary'] = this.cashBalanceSummary!.toJson();
    }
    if (this.checkingAccounts != null) {
      data['checking_accounts'] = this.checkingAccounts!.toJson();
    }
    return data;
  }
}

class CashBalanceSummary {
  int? totalBalance;
  int? previousBalance;
  int? percentageChange;
  bool? isPositiveChange;
  List<CashRegisters>? cashRegisters;
  List<Movements>? movements;
  String? comparisonPeriod;
  Period? period;

  CashBalanceSummary(
      {this.totalBalance,
        this.previousBalance,
        this.percentageChange,
        this.isPositiveChange,
        this.cashRegisters,
        this.movements,
        this.comparisonPeriod,
        this.period});

  CashBalanceSummary.fromJson(Map<String, dynamic> json) {
    totalBalance = json['total_balance'];
    previousBalance = json['previous_balance'];
    percentageChange = json['percentage_change'];
    isPositiveChange = json['is_positive_change'];
    if (json['cash_registers'] != null) {
      cashRegisters = <CashRegisters>[];
      json['cash_registers'].forEach((v) {
        cashRegisters!.add(new CashRegisters.fromJson(v));
      });
    }
    if (json['movements'] != null) {
      movements = <Movements>[];
      json['movements'].forEach((v) {
        movements!.add(new Movements.fromJson(v));
      });
    }
    comparisonPeriod = json['comparison_period'];
    period =
    json['period'] != null ? new Period.fromJson(json['period']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_balance'] = this.totalBalance;
    data['previous_balance'] = this.previousBalance;
    data['percentage_change'] = this.percentageChange;
    data['is_positive_change'] = this.isPositiveChange;
    if (this.cashRegisters != null) {
      data['cash_registers'] =
          this.cashRegisters!.map((v) => v.toJson()).toList();
    }
    if (this.movements != null) {
      data['movements'] = this.movements!.map((v) => v.toJson()).toList();
    }
    data['comparison_period'] = this.comparisonPeriod;
    if (this.period != null) {
      data['period'] = this.period!.toJson();
    }
    return data;
  }
}

class CashRegisters {
  int? id;
  String? name;
  int? balance;
  String? updatedAt;

  CashRegisters({this.id, this.name, this.balance, this.updatedAt});

  CashRegisters.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    balance = json['balance'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['balance'] = this.balance;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class Movements {
  int? id;
  String? date;
  String? time;
  String? operation;
  String? counterparty;
  int? amount;
  String? formattedAmount;
  String? method;
  String? operationType;
  bool? isIncome;

  Movements(
      {this.id,
        this.date,
        this.time,
        this.operation,
        this.counterparty,
        this.amount,
        this.formattedAmount,
        this.method,
        this.operationType,
        this.isIncome});

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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['date'] = this.date;
    data['time'] = this.time;
    data['operation'] = this.operation;
    data['counterparty'] = this.counterparty;
    data['amount'] = this.amount;
    data['formatted_amount'] = this.formattedAmount;
    data['method'] = this.method;
    data['operation_type'] = this.operationType;
    data['is_income'] = this.isIncome;
    return data;
  }
}

class Period {
  Current? current;
  Current? previous;

  Period({this.current, this.previous});

  Period.fromJson(Map<String, dynamic> json) {
    current =
    json['current'] != null ? new Current.fromJson(json['current']) : null;
    previous = json['previous'] != null
        ? new Current.fromJson(json['previous'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.current != null) {
      data['current'] = this.current!.toJson();
    }
    if (this.previous != null) {
      data['previous'] = this.previous!.toJson();
    }
    return data;
  }
}

class Current {
  String? from;
  String? to;

  Current({this.from, this.to});

  Current.fromJson(Map<String, dynamic> json) {
    from = json['from'];
    to = json['to'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['from'] = this.from;
    data['to'] = this.to;
    return data;
  }
}

class CheckingAccounts {
  int? currentPage;
  List<Data>? data;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  String? lastPageUrl;
  List<Links>? links;
  Null? nextPageUrl;
  String? path;
  int? perPage;
  Null? prevPageUrl;
  int? to;
  int? total;

  CheckingAccounts(
      {this.currentPage,
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
        this.total});

  CheckingAccounts.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    firstPageUrl = json['first_page_url'];
    from = json['from'];
    lastPage = json['last_page'];
    lastPageUrl = json['last_page_url'];
    if (json['links'] != null) {
      links = <Links>[];
      json['links'].forEach((v) {
        links!.add(new Links.fromJson(v));
      });
    }
    nextPageUrl = json['next_page_url'];
    path = json['path'];
    perPage = json['per_page'];
    prevPageUrl = json['prev_page_url'];
    to = json['to'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['current_page'] = this.currentPage;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['first_page_url'] = this.firstPageUrl;
    data['from'] = this.from;
    data['last_page'] = this.lastPage;
    data['last_page_url'] = this.lastPageUrl;
    if (this.links != null) {
      data['links'] = this.links!.map((v) => v.toJson()).toList();
    }
    data['next_page_url'] = this.nextPageUrl;
    data['path'] = this.path;
    data['per_page'] = this.perPage;
    data['prev_page_url'] = this.prevPageUrl;
    data['to'] = this.to;
    data['total'] = this.total;
    return data;
  }
}

class Data {
  int? id;
  String? docNumber;
  String? date;
  String? amount;
  String? formattedAmount;
  String? operationType;
  Null? comment;
  bool? approved;
  String? createdAt;
  CashRegister? cashRegister;
  Null? article;
  Counterparty? counterparty;
  bool? isIncome;

  Data(
      {this.id,
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
        this.isIncome});

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
        ? new CashRegister.fromJson(json['cash_register'])
        : null;
    article = json['article'];
    counterparty = json['counterparty'] != null
        ? new Counterparty.fromJson(json['counterparty'])
        : null;
    isIncome = json['is_income'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['doc_number'] = this.docNumber;
    data['date'] = this.date;
    data['amount'] = this.amount;
    data['formatted_amount'] = this.formattedAmount;
    data['operation_type'] = this.operationType;
    data['comment'] = this.comment;
    data['approved'] = this.approved;
    data['created_at'] = this.createdAt;
    if (this.cashRegister != null) {
      data['cash_register'] = this.cashRegister!.toJson();
    }
    data['article'] = this.article;
    if (this.counterparty != null) {
      data['counterparty'] = this.counterparty!.toJson();
    }
    data['is_income'] = this.isIncome;
    return data;
  }
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['type'] = this.type;
    return data;
  }
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['id'] = this.id;
    data['name'] = this.name;
    data['phone'] = this.phone;
    data['inn'] = this.inn;
    return data;
  }
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['label'] = this.label;
    data['active'] = this.active;
    return data;
  }
}

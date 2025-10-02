class DebtorsResponse {
  Result? result;
  Null? errors;

  DebtorsResponse({this.result, this.errors});

  DebtorsResponse.fromJson(Map<String, dynamic> json) {
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
  int? totalDebt;
  List<Debtors>? debtors;
  Period? period;
  double? percentageChange;
  bool? isPositiveChange;
  AppliedFilters? appliedFilters;

  Result(
      {this.totalDebt,
        this.debtors,
        this.period,
        this.percentageChange,
        this.isPositiveChange,
        this.appliedFilters});

  Result.fromJson(Map<String, dynamic> json) {
    totalDebt = json['total_debt'];
    if (json['debtors'] != null) {
      debtors = <Debtors>[];
      json['debtors'].forEach((v) {
        debtors!.add(new Debtors.fromJson(v));
      });
    }
    period =
    json['period'] != null ? new Period.fromJson(json['period']) : null;
    percentageChange = json['percentage_change'];
    isPositiveChange = json['is_positive_change'];
    appliedFilters = json['applied_filters'] != null
        ? new AppliedFilters.fromJson(json['applied_filters'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_debt'] = this.totalDebt;
    if (this.debtors != null) {
      data['debtors'] = this.debtors!.map((v) => v.toJson()).toList();
    }
    if (this.period != null) {
      data['period'] = this.period!.toJson();
    }
    data['percentage_change'] = this.percentageChange;
    data['is_positive_change'] = this.isPositiveChange;
    if (this.appliedFilters != null) {
      data['applied_filters'] = this.appliedFilters!.toJson();
    }
    return data;
  }
}

class Debtors {
  int? id;
  String? name;
  String? type;
  String? phone;
  int? debtAmount;

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

class AppliedFilters {
  Null? cashRegisterId;
  Null? supplierId;
  Null? clientId;
  Null? leadId;
  Null? operationType;
  Null? search;

  AppliedFilters(
      {this.cashRegisterId,
        this.supplierId,
        this.clientId,
        this.leadId,
        this.operationType,
        this.search});

  AppliedFilters.fromJson(Map<String, dynamic> json) {
    cashRegisterId = json['cash_register_id'];
    supplierId = json['supplier_id'];
    clientId = json['client_id'];
    leadId = json['lead_id'];
    operationType = json['operation_type'];
    search = json['search'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cash_register_id'] = this.cashRegisterId;
    data['supplier_id'] = this.supplierId;
    data['client_id'] = this.clientId;
    data['lead_id'] = this.leadId;
    data['operation_type'] = this.operationType;
    data['search'] = this.search;
    return data;
  }
}

import 'package:crm_task_manager/utils/safe_converters.dart';

class CashRegisterDetailsResponse {
  final CashRegisterDetailsInfo? cashRegister;
  final List<CashRegisterHistoryItem> checkingAccounts;
  final CashRegisterDetailsMeta? meta;

  const CashRegisterDetailsResponse({
    this.cashRegister,
    this.checkingAccounts = const [],
    this.meta,
  });

  factory CashRegisterDetailsResponse.fromJson(Map<String, dynamic> json) {
    return CashRegisterDetailsResponse(
      cashRegister: SafeConverters.toMapOrNull(json['cash_register']) != null
          ? CashRegisterDetailsInfo.fromJson(
              SafeConverters.toMap(json['cash_register']),
            )
          : null,
      checkingAccounts: SafeConverters.toList(json['checking_accounts'])
          .whereType<Map<String, dynamic>>()
          .map(CashRegisterHistoryItem.fromJson)
          .toList(),
      meta: SafeConverters.toMapOrNull(json['meta']) != null
          ? CashRegisterDetailsMeta.fromJson(SafeConverters.toMap(json['meta']))
          : null,
    );
  }

  bool get hasMore {
    final current = meta?.currentPage ?? 1;
    final last = meta?.lastPage ?? 1;
    return current < last;
  }
}

class CashRegisterDetailsInfo {
  final int? id;
  final String? name;
  final CashRegisterDetailsCurrency? currency;

  const CashRegisterDetailsInfo({
    this.id,
    this.name,
    this.currency,
  });

  factory CashRegisterDetailsInfo.fromJson(Map<String, dynamic> json) {
    return CashRegisterDetailsInfo(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      currency: SafeConverters.toMapOrNull(json['currency']) != null
          ? CashRegisterDetailsCurrency.fromJson(
              SafeConverters.toMap(json['currency']),
            )
          : null,
    );
  }

  String? get currencyLabel {
    final symbol = currency?.symbolCode?.trim();
    if (symbol != null && symbol.isNotEmpty) return symbol;
    final name = currency?.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }
}

class CashRegisterDetailsCurrency {
  final int? id;
  final String? name;
  final String? symbolCode;

  const CashRegisterDetailsCurrency({
    this.id,
    this.name,
    this.symbolCode,
  });

  factory CashRegisterDetailsCurrency.fromJson(Map<String, dynamic> json) {
    return CashRegisterDetailsCurrency(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      symbolCode: SafeConverters.toStringOrNull(json['symbol_code']),
    );
  }
}

class CashRegisterDetailsMeta {
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  const CashRegisterDetailsMeta({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  factory CashRegisterDetailsMeta.fromJson(Map<String, dynamic> json) {
    return CashRegisterDetailsMeta(
      currentPage: SafeConverters.toIntOrNull(json['current_page']),
      lastPage: SafeConverters.toIntOrNull(json['last_page']),
      perPage: SafeConverters.toIntOrNull(json['per_page']),
      total: SafeConverters.toIntOrNull(json['total']),
    );
  }
}

class CashRegisterHistoryItem {
  final int? id;
  final String? docNumber;
  final String? date;
  final String? amount;
  final String? comment;
  final String? operationType;
  final String? type;
  final bool? approved;
  final CashRegisterHistoryAuthor? author;
  final CashRegisterHistoryNamed? cashRegister;
  final CashRegisterHistoryNamed? senderCashRegister;

  const CashRegisterHistoryItem({
    this.id,
    this.docNumber,
    this.date,
    this.amount,
    this.comment,
    this.operationType,
    this.type,
    this.approved,
    this.author,
    this.cashRegister,
    this.senderCashRegister,
  });

  factory CashRegisterHistoryItem.fromJson(Map<String, dynamic> json) {
    return CashRegisterHistoryItem(
      id: SafeConverters.toIntOrNull(json['id']),
      docNumber: SafeConverters.toStringOrNull(json['doc_number']),
      date: SafeConverters.toStringOrNull(json['date']),
      amount: SafeConverters.toStringOrNull(json['amount']) ??
          SafeConverters.toStringOrNull(json['formatted_amount']),
      comment: SafeConverters.toStringOrNull(json['comment']),
      operationType: SafeConverters.toStringOrNull(json['operation_type']),
      type: SafeConverters.toStringOrNull(json['type']),
      approved: SafeConverters.toBoolOrNull(json['approved']),
      author: SafeConverters.toMapOrNull(json['author']) != null
          ? CashRegisterHistoryAuthor.fromJson(
              SafeConverters.toMap(json['author']),
            )
          : null,
      cashRegister: SafeConverters.toMapOrNull(json['cash_register']) != null
          ? CashRegisterHistoryNamed.fromJson(
              SafeConverters.toMap(json['cash_register']),
            )
          : null,
      senderCashRegister:
          SafeConverters.toMapOrNull(json['sender_cashregister']) != null
              ? CashRegisterHistoryNamed.fromJson(
                  SafeConverters.toMap(json['sender_cashregister']),
                )
              : null,
    );
  }

  bool get isIncome => (type ?? '').toUpperCase() == 'PKO';

  num get amountValue => SafeConverters.toNum(amount);
}

class CashRegisterHistoryAuthor {
  final int? id;
  final String? name;
  final String? lastname;
  final String? fullName;

  const CashRegisterHistoryAuthor({
    this.id,
    this.name,
    this.lastname,
    this.fullName,
  });

  factory CashRegisterHistoryAuthor.fromJson(Map<String, dynamic> json) {
    return CashRegisterHistoryAuthor(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      lastname: SafeConverters.toStringOrNull(json['lastname']),
      fullName: SafeConverters.toStringOrNull(json['full_name']),
    );
  }

  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    return [name, lastname]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
  }
}

class CashRegisterHistoryNamed {
  final int? id;
  final String? name;

  const CashRegisterHistoryNamed({this.id, this.name});

  factory CashRegisterHistoryNamed.fromJson(Map<String, dynamic> json) {
    return CashRegisterHistoryNamed(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
    );
  }
}

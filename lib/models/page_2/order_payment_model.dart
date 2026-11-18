import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(' ', '').replaceAll(',', '.') ?? '') ?? 0.0;
}

String _money(double value) {
  final text = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  return text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ' ');
}

class OrderPaymentAllocation {
  final int? id;
  final int? obligationId;
  final int? scheduleLineId;
  final double amount;
  final String type;

  const OrderPaymentAllocation({
    this.id,
    this.obligationId,
    this.scheduleLineId,
    required this.amount,
    required this.type,
  });

  factory OrderPaymentAllocation.fromJson(Map<String, dynamic> json) {
    return OrderPaymentAllocation(
      id: int.tryParse(json['id']?.toString() ?? ''),
      obligationId: int.tryParse(json['obligation_id']?.toString() ?? ''),
      scheduleLineId: int.tryParse(json['schedule_line_id']?.toString() ?? ''),
      amount: _toDouble(json['amount']),
      type: json['type']?.toString() ?? 'unallocated',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'obligation_id': obligationId,
        'schedule_line_id': scheduleLineId,
        'amount': amount,
        'type': type,
      };

  String get typeLabel {
    switch (type) {
      case 'down_payment':
        return 'Первоначальный взнос';
      case 'schedule_line':
        return 'Платёж по графику';
      case 'early_repayment':
        return 'Досрочное погашение';
      case 'unallocated':
      default:
        return 'Платёж по сделке';
    }
  }
}

class OrderPayment {
  final int id;
  final int orderId;
  final String? orderNumber;
  final String? dealType;
  final String? date;
  final int? leadId;
  final String? buyer;
  final String? manager;
  final String? object;
  final double? orderSum;
  final String? orderPaymentStatus;
  final String? paidAt;
  final double amount;
  final int? currencyId;
  final double? amountInObligationCurrency;
  final double? exchangeRate;
  final String method;
  final String? documentNumber;
  final String? comment;
  final String status;
  final String? confirmedAt;
  final int? sourcePaymentId;
  final List<OrderPaymentAllocation> allocations;
  final DateTime? deletedAt;
  final Map<String, dynamic> rawJson;

  const OrderPayment({
    required this.id,
    required this.orderId,
    this.orderNumber,
    this.dealType,
    this.date,
    this.leadId,
    this.buyer,
    this.manager,
    this.object,
    this.orderSum,
    this.orderPaymentStatus,
    this.paidAt,
    required this.amount,
    this.currencyId,
    this.amountInObligationCurrency,
    this.exchangeRate,
    required this.method,
    this.documentNumber,
    this.comment,
    required this.status,
    this.confirmedAt,
    this.sourcePaymentId,
    this.allocations = const [],
    this.deletedAt,
    this.rawJson = const {},
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    final rawAllocations = json['allocations'];
    final allocationsList = rawAllocations is List
        ? rawAllocations
            .whereType<Map>()
            .map((e) => OrderPaymentAllocation.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <OrderPaymentAllocation>[];

    DateTime? deletedAtParsed;
    if (json['deleted_at'] != null) {
      deletedAtParsed = DateTime.tryParse(json['deleted_at'].toString());
    }

    return OrderPayment(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      orderId: int.tryParse(json['order_id']?.toString() ?? '') ?? 0,
      orderNumber: json['order_number']?.toString(),
      dealType: json['deal_type']?.toString(),
      date: json['date']?.toString(),
      leadId: int.tryParse(json['lead_id']?.toString() ?? ''),
      buyer: json['buyer']?.toString(),
      manager: json['manager']?.toString(),
      object: json['object']?.toString(),
      orderSum: json['order_sum'] != null ? _toDouble(json['order_sum']) : null,
      orderPaymentStatus: json['order_payment_status']?.toString(),
      paidAt: json['paid_at']?.toString(),
      amount: _toDouble(json['amount']),
      currencyId: int.tryParse(json['currency_id']?.toString() ?? ''),
      amountInObligationCurrency: json['amount_in_obligation_currency'] != null
          ? _toDouble(json['amount_in_obligation_currency'])
          : null,
      exchangeRate: json['exchange_rate'] != null ? _toDouble(json['exchange_rate']) : null,
      method: json['method']?.toString() ?? 'cash',
      documentNumber: json['document_number']?.toString(),
      comment: json['comment']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      confirmedAt: json['confirmed_at']?.toString(),
      sourcePaymentId: int.tryParse(json['source_payment_id']?.toString() ?? ''),
      allocations: allocationsList,
      deletedAt: deletedAtParsed,
      rawJson: json,
    );
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isDraft => status == 'draft';
  bool get isReversed => status == 'reversed';

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Проведён';
      case 'draft':
        return 'Не проведён';
      case 'reversed':
        return 'Отменён';
      default:
        return status;
    }
  }

  Color statusColor(dynamic colors) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF16A34A);
      case 'draft':
        return const Color(0xFFE2A81C);
      case 'reversed':
        return const Color(0xFFDC2626);
      default:
        return colors.textSecondary;
    }
  }

  String get methodLabel {
    switch (method) {
      case 'cash':
        return 'Наличные';
      case 'transfer':
        return 'Банковский перевод';
      case 'terminal':
        return 'Терминал';
      default:
        return method.isNotEmpty ? method : 'Наличные';
    }
  }

  String get formattedPaidAt {
    if (paidAt == null || paidAt!.isEmpty) return '—';
    final parsed = DateTime.tryParse(paidAt!);
    if (parsed == null) return paidAt!;
    return DateFormat('dd.MM.yyyy').format(parsed);
  }

  String get formattedAmount => _money(amount);

  String get formattedOrderSum => orderSum == null ? '—' : _money(orderSum!);

  String get allocationsSummary {
    if (allocations.isEmpty) return 'Платёж по сделке';
    return allocations.map((a) => '${a.typeLabel}: ${_money(a.amount)}').join(', ');
  }

  OrderPayment copyWith({
    String? status,
    String? confirmedAt,
    DateTime? deletedAt,
  }) {
    return OrderPayment(
      id: id,
      orderId: orderId,
      orderNumber: orderNumber,
      dealType: dealType,
      date: date,
      leadId: leadId,
      buyer: buyer,
      manager: manager,
      object: object,
      orderSum: orderSum,
      orderPaymentStatus: orderPaymentStatus,
      paidAt: paidAt,
      amount: amount,
      currencyId: currencyId,
      amountInObligationCurrency: amountInObligationCurrency,
      exchangeRate: exchangeRate,
      method: method,
      documentNumber: documentNumber,
      comment: comment,
      status: status ?? this.status,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      sourcePaymentId: sourcePaymentId,
      allocations: allocations,
      deletedAt: deletedAt ?? this.deletedAt,
      rawJson: rawJson,
    );
  }
}

class OrderPaymentsResponse {
  final List<OrderPayment> data;
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;
  final double totalAmount;

  const OrderPaymentsResponse({
    required this.data,
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
    required this.totalAmount,
  });

  factory OrderPaymentsResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawResult = json['result'] ?? json['data'] ?? json;
    final Map<String, dynamic> result =
        rawResult is Map<String, dynamic> ? rawResult : Map<String, dynamic>.from(rawResult is Map ? rawResult : {});

    final rawData = result['data'] is List ? result['data'] as List : (json['data'] is List ? json['data'] as List : const []);
    final list = rawData
        .whereType<Map>()
        .map((e) => OrderPayment.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final pagination = result['pagination'] is Map ? result['pagination'] as Map : const {};
    final total = int.tryParse(pagination['total']?.toString() ?? '') ?? list.length;
    final count = int.tryParse(pagination['count']?.toString() ?? '') ?? list.length;
    final perPage = int.tryParse(pagination['per_page']?.toString() ?? '') ?? 50;
    final currentPage = int.tryParse(pagination['current_page']?.toString() ?? '') ?? 1;
    final totalPages = int.tryParse(pagination['total_pages']?.toString() ?? '') ?? 1;
    final totalAmount = list.fold<double>(0.0, (sum, item) => sum + item.amount);

    return OrderPaymentsResponse(
      data: list,
      total: total,
      count: count,
      perPage: perPage,
      currentPage: currentPage,
      totalPages: totalPages,
      totalAmount: totalAmount,
    );
  }
}

import 'dart:convert';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResidentialDealData {
  final int orderId;
  final String ownerName;
  final String gender;
  final String passport;
  final String? passportIssuedBy;
  final String? passportIssuedAt;
  final String? passportExpiresAt;
  final String? ownerBirthDate;
  final int? inn;
  final String? residenceAddress;
  final String dealType; // 'cash', 'installment', 'mixed'
  final double? pricePerM2;
  final double? totalArea;
  final double? sum;
  final int? currencyId;
  final String? currencySymbol;
  final double? downPayment;
  final int? installmentMonths;
  final String? firstPaymentDate;
  final double? barterAmount;
  final String? barterNote;
  final int? goodId;
  final int? variantId;
  final String? goodName;
  final String? buildingName;
  final String? phone;

  const ResidentialDealData({
    required this.orderId,
    required this.ownerName,
    this.gender = 'm',
    required this.passport,
    this.passportIssuedBy,
    this.passportIssuedAt,
    this.passportExpiresAt,
    this.ownerBirthDate,
    this.inn,
    this.residenceAddress,
    this.dealType = 'cash',
    this.pricePerM2,
    this.totalArea,
    this.sum,
    this.currencyId,
    this.currencySymbol,
    this.downPayment,
    this.installmentMonths,
    this.firstPaymentDate,
    this.barterAmount,
    this.barterNote,
    this.goodId,
    this.variantId,
    this.goodName,
    this.buildingName,
    this.phone,
  });

  String get cleanCurrencySymbol {
    final s = currencySymbol?.trim();
    if (s != null && s.isNotEmpty && !s.startsWith('{') && !s.startsWith('Instance of')) {
      return s;
    }
    return '\$';
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'ownerName': ownerName,
        'gender': gender,
        'passport': passport,
        'passportIssuedBy': passportIssuedBy,
        'passportIssuedAt': passportIssuedAt,
        'passportExpiresAt': passportExpiresAt,
        'ownerBirthDate': ownerBirthDate,
        'inn': inn,
        'residenceAddress': residenceAddress,
        'dealType': dealType,
        'pricePerM2': pricePerM2,
        'totalArea': totalArea,
        'sum': sum,
        'currencyId': currencyId,
        'currencySymbol': cleanCurrencySymbol,
        'downPayment': downPayment,
        'installmentMonths': installmentMonths,
        'firstPaymentDate': firstPaymentDate,
        'barterAmount': barterAmount,
        'barterNote': barterNote,
        'goodId': goodId,
        'variantId': variantId,
        'goodName': goodName,
        'buildingName': buildingName,
        'phone': phone,
      };

  factory ResidentialDealData.fromJson(Map<String, dynamic> json) {
    String? extractCurrency(dynamic val) {
      if (val == null) return null;
      if (val is Map) {
        final symbolCode = val['symbol_code']?.toString().trim();
        if (symbolCode != null && symbolCode.isNotEmpty && !symbolCode.startsWith('{')) {
          return symbolCode;
        }
        final name = val['name']?.toString().trim();
        if (name != null && name.isNotEmpty && !name.startsWith('{')) {
          return name;
        }
      }
      final s = val.toString().trim();
      if (s.isEmpty || s.startsWith('{') || s.startsWith('Instance of')) {
        return null;
      }
      return s;
    }

    return ResidentialDealData(
      orderId: (json['orderId'] is int)
          ? json['orderId']
          : int.tryParse(json['orderId']?.toString() ?? '') ?? 0,
      ownerName: json['ownerName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'm',
      passport: json['passport']?.toString() ?? '',
      passportIssuedBy: json['passportIssuedBy']?.toString(),
      passportIssuedAt: json['passportIssuedAt']?.toString(),
      passportExpiresAt: json['passportExpiresAt']?.toString(),
      ownerBirthDate: json['ownerBirthDate']?.toString(),
      inn: (json['inn'] is num) ? (json['inn'] as num).toInt() : int.tryParse(json['inn']?.toString() ?? ''),
      residenceAddress: json['residenceAddress']?.toString(),
      dealType: json['dealType']?.toString() ?? 'cash',
      pricePerM2: (json['pricePerM2'] is num) ? (json['pricePerM2'] as num).toDouble() : double.tryParse(json['pricePerM2']?.toString() ?? ''),
      totalArea: (json['totalArea'] is num) ? (json['totalArea'] as num).toDouble() : double.tryParse(json['totalArea']?.toString() ?? ''),
      sum: (json['sum'] is num) ? (json['sum'] as num).toDouble() : double.tryParse(json['sum']?.toString() ?? ''),
      currencyId: (json['currencyId'] is num) ? (json['currencyId'] as num).toInt() : int.tryParse(json['currencyId']?.toString() ?? ''),
      currencySymbol: extractCurrency(json['currencySymbol']),
      downPayment: (json['downPayment'] is num) ? (json['downPayment'] as num).toDouble() : double.tryParse(json['downPayment']?.toString() ?? ''),
      installmentMonths: (json['installmentMonths'] is num) ? (json['installmentMonths'] as num).toInt() : int.tryParse(json['installmentMonths']?.toString() ?? ''),
      firstPaymentDate: json['firstPaymentDate']?.toString(),
      barterAmount: (json['barterAmount'] is num) ? (json['barterAmount'] as num).toDouble() : double.tryParse(json['barterAmount']?.toString() ?? ''),
      barterNote: json['barterNote']?.toString(),
      goodId: (json['goodId'] is num) ? (json['goodId'] as num).toInt() : int.tryParse(json['goodId']?.toString() ?? ''),
      variantId: (json['variantId'] is num) ? (json['variantId'] as num).toInt() : int.tryParse(json['variantId']?.toString() ?? ''),
      goodName: json['goodName']?.toString(),
      buildingName: json['buildingName']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  factory ResidentialDealData.fromServerMap(int orderId, Map<String, dynamic> raw) {
    String str(dynamic val) => val?.toString().trim() ?? '';
    double? dbl(dynamic val) => (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? '');
    int? integer(dynamic val) => (val is num) ? val.toInt() : int.tryParse(val?.toString() ?? '');

    String? extractCurrency(dynamic val) {
      if (val == null) return null;
      if (val is Map) {
        final symbolCode = val['symbol_code']?.toString().trim();
        if (symbolCode != null && symbolCode.isNotEmpty && !symbolCode.startsWith('{')) {
          return symbolCode;
        }
        final name = val['name']?.toString().trim();
        if (name != null && name.isNotEmpty && !name.startsWith('{')) {
          return name;
        }
      }
      final s = val.toString().trim();
      if (s.isEmpty || s.startsWith('{') || s.startsWith('Instance of')) {
        return null;
      }
      return s;
    }

    return ResidentialDealData(
      orderId: orderId,
      ownerName: str(raw['owner_name'] ?? raw['ownerName'] ?? raw['buyer_name']),
      gender: str(raw['gender']).isNotEmpty ? str(raw['gender']) : 'm',
      passport: str(raw['passport']),
      passportIssuedBy: str(raw['passport_issued_by'] ?? raw['passportIssuedBy']),
      passportIssuedAt: str(raw['passport_issued_at'] ?? raw['passportIssuedAt']),
      passportExpiresAt: str(raw['passport_expires_at'] ?? raw['passportExpiresAt']),
      ownerBirthDate: str(raw['owner_birth_date'] ?? raw['ownerBirthDate']),
      inn: integer(raw['inn']),
      residenceAddress: str(raw['residence_address'] ?? raw['residenceAddress']),
      dealType: str(raw['deal_type'] ?? raw['dealType']).isNotEmpty
          ? str(raw['deal_type'] ?? raw['dealType'])
          : 'cash',
      pricePerM2: dbl(raw['price_per_m2'] ?? raw['price_per_sqm']),
      totalArea: dbl(raw['total_area']),
      sum: dbl(raw['sum'] ?? raw['price']),
      currencyId: integer(raw['currency_id']),
      currencySymbol: extractCurrency(raw['currency']) ?? extractCurrency(raw['currency_symbol']) ?? extractCurrency(raw['currencySymbol']),
      downPayment: dbl(raw['down_payment']),
      installmentMonths: integer(raw['installment_months']),
      firstPaymentDate: str(raw['first_payment_date']),
      barterAmount: dbl(raw['barter_amount']),
      barterNote: str(raw['barter_note']),
      goodId: integer(raw['good_id']),
      variantId: integer(raw['variant_id']),
      goodName: str(raw['good_name'] ?? raw['apartment_number']),
      buildingName: str(raw['building_name']),
      phone: str(raw['phone']),
    );
  }

  ResidentialDealData copyWith({
    String? ownerName,
    String? gender,
    String? passport,
    String? passportIssuedBy,
    String? passportIssuedAt,
    String? passportExpiresAt,
    String? ownerBirthDate,
    int? inn,
    String? residenceAddress,
    String? dealType,
    double? pricePerM2,
    double? totalArea,
    double? sum,
    int? currencyId,
    String? currencySymbol,
    double? downPayment,
    int? installmentMonths,
    String? firstPaymentDate,
    double? barterAmount,
    String? barterNote,
    int? goodId,
    int? variantId,
    String? goodName,
    String? buildingName,
    String? phone,
  }) {
    return ResidentialDealData(
      orderId: orderId,
      ownerName: ownerName ?? this.ownerName,
      gender: gender ?? this.gender,
      passport: passport ?? this.passport,
      passportIssuedBy: passportIssuedBy ?? this.passportIssuedBy,
      passportIssuedAt: passportIssuedAt ?? this.passportIssuedAt,
      passportExpiresAt: passportExpiresAt ?? this.passportExpiresAt,
      ownerBirthDate: ownerBirthDate ?? this.ownerBirthDate,
      inn: inn ?? this.inn,
      residenceAddress: residenceAddress ?? this.residenceAddress,
      dealType: dealType ?? this.dealType,
      pricePerM2: pricePerM2 ?? this.pricePerM2,
      totalArea: totalArea ?? this.totalArea,
      sum: sum ?? this.sum,
      currencyId: currencyId ?? this.currencyId,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      downPayment: downPayment ?? this.downPayment,
      installmentMonths: installmentMonths ?? this.installmentMonths,
      firstPaymentDate: firstPaymentDate ?? this.firstPaymentDate,
      barterAmount: barterAmount ?? this.barterAmount,
      barterNote: barterNote ?? this.barterNote,
      goodId: goodId ?? this.goodId,
      variantId: variantId ?? this.variantId,
      goodName: goodName ?? this.goodName,
      buildingName: buildingName ?? this.buildingName,
      phone: phone ?? this.phone,
    );
  }
}

class ResidentialDealStore {
  static const String _prefix = 'chess_residential_deal_';

  static Future<void> save(ResidentialDealData data, [int? orderId]) async {
    try {
      final id = orderId ?? data.orderId;
      if (id <= 0) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$id', jsonEncode(data.toJson()));
    } catch (e) {
      debugPrint('ResidentialDealStore.save error: $e');
    }
  }

  static Future<ResidentialDealData?> get(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$orderId');
      if (raw != null && raw.isNotEmpty) {
        return ResidentialDealData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('ResidentialDealStore.get error: $e');
    }
    return null;
  }

  /// Merges server raw data with locally cached data so no field is ever lost.
  static Future<ResidentialDealData> resolve(Order order) async {
    final cached = await get(order.id);
    final raw = order.rawJson;

    ResidentialDealData serverData = (raw != null && raw.isNotEmpty)
        ? ResidentialDealData.fromServerMap(order.id, raw)
        : ResidentialDealData(
            orderId: order.id,
            ownerName: order.lead.name,
            passport: '',
            sum: order.sum,
          );

    // Extract good info from order.goods if available
    String? goodName = serverData.goodName;
    int? goodId = serverData.goodId;
    int? variantId = serverData.variantId;
    if (order.goods.isNotEmpty) {
      final firstGood = order.goods.first;
      goodName ??= firstGood.getCorrectGoodName();
      goodId ??= firstGood.good.id > 0 ? firstGood.good.id : (firstGood.goodId > 0 ? firstGood.goodId : null);
      variantId ??= firstGood.goodId > 0 ? firstGood.goodId : null;
    }

    if (cached == null) {
      return serverData.copyWith(
        goodName: goodName,
        goodId: goodId,
        variantId: variantId,
      );
    }

    // Merge: prefer serverData if non-empty, otherwise fallback to cached
    return ResidentialDealData(
      orderId: order.id,
      ownerName: serverData.ownerName.isNotEmpty ? serverData.ownerName : cached.ownerName,
      gender: serverData.gender.isNotEmpty ? serverData.gender : cached.gender,
      passport: serverData.passport.isNotEmpty ? serverData.passport : cached.passport,
      passportIssuedBy: (serverData.passportIssuedBy != null && serverData.passportIssuedBy!.isNotEmpty)
          ? serverData.passportIssuedBy
          : cached.passportIssuedBy,
      passportIssuedAt: (serverData.passportIssuedAt != null && serverData.passportIssuedAt!.isNotEmpty)
          ? serverData.passportIssuedAt
          : cached.passportIssuedAt,
      passportExpiresAt: (serverData.passportExpiresAt != null && serverData.passportExpiresAt!.isNotEmpty)
          ? serverData.passportExpiresAt
          : cached.passportExpiresAt,
      ownerBirthDate: (serverData.ownerBirthDate != null && serverData.ownerBirthDate!.isNotEmpty)
          ? serverData.ownerBirthDate
          : cached.ownerBirthDate,
      inn: serverData.inn ?? cached.inn,
      residenceAddress: (serverData.residenceAddress != null && serverData.residenceAddress!.isNotEmpty)
          ? serverData.residenceAddress
          : cached.residenceAddress,
      dealType: serverData.dealType.isNotEmpty ? serverData.dealType : cached.dealType,
      pricePerM2: serverData.pricePerM2 ?? cached.pricePerM2,
      totalArea: serverData.totalArea ?? cached.totalArea,
      sum: serverData.sum ?? cached.sum ?? order.sum,
      currencyId: serverData.currencyId ?? cached.currencyId,
      currencySymbol: (serverData.cleanCurrencySymbol != '\$')
          ? serverData.cleanCurrencySymbol
          : cached.cleanCurrencySymbol,
      downPayment: serverData.downPayment ?? cached.downPayment,
      installmentMonths: serverData.installmentMonths ?? cached.installmentMonths,
      firstPaymentDate: (serverData.firstPaymentDate != null && serverData.firstPaymentDate!.isNotEmpty)
          ? serverData.firstPaymentDate
          : cached.firstPaymentDate,
      barterAmount: serverData.barterAmount ?? cached.barterAmount,
      barterNote: (serverData.barterNote != null && serverData.barterNote!.isNotEmpty)
          ? serverData.barterNote
          : cached.barterNote,
      goodId: goodId ?? cached.goodId,
      variantId: variantId ?? cached.variantId,
      goodName: goodName ?? cached.goodName,
      buildingName: serverData.buildingName ?? cached.buildingName,
      phone: (serverData.phone != null && serverData.phone!.isNotEmpty)
          ? serverData.phone
          : (cached.phone != null && cached.phone!.isNotEmpty
              ? cached.phone
              : (order.phone.isNotEmpty ? order.phone : order.lead.phone)),
    );
  }
}

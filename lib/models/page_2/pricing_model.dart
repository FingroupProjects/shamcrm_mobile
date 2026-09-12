import 'package:crm_task_manager/utils/safe_converters.dart';

class PricingDocument {
  const PricingDocument({
    required this.id,
    required this.startDate,
    required this.authorName,
  });

  final int id;
  final DateTime? startDate;
  final String authorName;

  factory PricingDocument.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    final firstName = author is Map ? author['name']?.toString() ?? '' : '';
    final lastName = author is Map ? author['lastname']?.toString() ?? '' : '';
    final rawDate = json['start_date'] ?? json['created_at'];
    return PricingDocument(
      id: SafeConverters.toIntOrNull(json['id']) ?? 0,
      startDate: rawDate == null ? null : DateTime.tryParse(rawDate.toString()),
      authorName: '$firstName $lastName'.trim().isEmpty
          ? '—'
          : '$firstName $lastName'.trim(),
    );
  }
}

class PricingDocumentItem {
  const PricingDocumentItem({
    required this.goodName,
    required this.price,
    required this.priceTypeName,
  });

  final String goodName;
  final double price;
  final String priceTypeName;

  factory PricingDocumentItem.fromJson(Map<String, dynamic> json) {
    final variant = json['variant'];
    final good = variant is Map ? variant['good'] : null;
    final priceType = json['price_type'];
    final rawGoodName = good is Map
        ? (good['full_name'] ?? good['name'] ?? 'Без названия').toString()
        : 'Без названия';
    return PricingDocumentItem(
      // API иногда добавляет разделитель варианта в конце названия товара.
      goodName: rawGoodName.replaceFirst(RegExp(r'\s*/\s*$'), '').trim(),
      price: SafeConverters.toDouble(json['price']),
      priceTypeName:
          priceType is Map ? (priceType['name'] ?? 'Цена').toString() : 'Цена',
    );
  }
}

class PricingGoodsPage {
  const PricingGoodsPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.totalPages,
  });

  final List<PricingGood> items;
  final int total;
  final int currentPage;
  final int totalPages;

  factory PricingGoodsPage.fromJson(dynamic json) {
    final root = json is Map ? json : const <String, dynamic>{};
    final result = root['result'] is Map ? root['result'] as Map : root;
    final data = result['data'] is List ? result['data'] as List : const [];
    // Пагинация может лежать в result.pagination или в корне result.
    final pagination = result['pagination'] is Map
        ? result['pagination'] as Map
        : result;
    final currentPage =
        SafeConverters.toIntOrNull(pagination['current_page']) ?? 1;
    // 0 значит, что сервер не прислал total_pages — тогда смотрим total.
    final totalPages =
        SafeConverters.toIntOrNull(pagination['total_pages']) ?? 0;
    final total = SafeConverters.toIntOrNull(pagination['total']) ??
        SafeConverters.toIntOrNull(result['total']) ??
        0;
    return PricingGoodsPage(
      items: data
          .whereType<Map>()
          .map((item) => PricingGood.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      total: total,
      currentPage: currentPage,
      totalPages: totalPages,
    );
  }
}

class PricingGood {
  PricingGood(
      {required this.variantId, required this.name, required this.prices});

  final int variantId;
  final String name;
  final List<PricingValue> prices;

  factory PricingGood.fromJson(Map<String, dynamic> json) => PricingGood(
        variantId: SafeConverters.toIntOrNull(json['variant_id']) ?? 0,
        name: json['full_name']?.toString() ?? 'Без названия',
        prices: (json['prices'] as List? ?? const [])
            .whereType<Map>()
            .map((item) =>
                PricingValue.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
}

class PricingValue {
  PricingValue({
    required this.priceTypeId,
    required this.priceTypeName,
    required this.currentPrice,
    required this.newPrice,
    this.isEntered = false,
  });

  final int priceTypeId;
  final String priceTypeName;
  final double currentPrice;
  double newPrice;
  bool isEntered;

  factory PricingValue.fromJson(Map<String, dynamic> json) => PricingValue(
        priceTypeId: SafeConverters.toIntOrNull(json['price_type_id']) ?? 0,
        priceTypeName: json['price_type_name']?.toString() ?? 'Цена',
        currentPrice: SafeConverters.toDouble(json['current_price']),
        newPrice: SafeConverters.toDouble(json['new_price']),
      );
}

part of '../api_service.dart';

extension ApiWarehousePricingX on ApiService {
  Future<List<PricingDocument>> getPricingDocuments({
    int page = 1,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    var requestPath = '/pricing?page=$page';
    if (search != null && search.trim().isNotEmpty) {
      requestPath += '&search=${Uri.encodeQueryComponent(search.trim())}';
    }
    if (filters != null) {
      const keys = ['date_from', 'date_to', 'author_id'];
      for (final key in keys) {
        final value = filters[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          requestPath += '&$key=${Uri.encodeQueryComponent(value.toString())}';
        }
      }
    }
    final path = await _appendQueryParams(requestPath);
    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw ApiException(
          _extractErrorMessageFromResponse(response) ??
              'Не удалось загрузить цены',
          response.statusCode);
    }
    final decoded = json.decode(response.body);
    final result = decoded is Map ? decoded['result'] : null;
    final data = result is Map && result['data'] is List
        ? result['data'] as List
        : const [];
    return data
        .whereType<Map>()
        .map(
            (item) => PricingDocument.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<PricingGoodsPage> getPricingGoods({
    int page = 1,
    String? priceFrom,
    String? priceTo,
    int? categoryId,
    List<Map<String, dynamic>> rules = const [],
  }) async {
    var path = '/pricing/getGoods?page=$page';
    if (priceFrom != null && priceFrom.isNotEmpty)
      path += '&price_from=${Uri.encodeQueryComponent(priceFrom)}';
    if (priceTo != null && priceTo.isNotEmpty)
      path += '&price_to=${Uri.encodeQueryComponent(priceTo)}';
    if (categoryId != null) path += '&category_id=$categoryId';
    for (var i = 0; i < rules.length; i++) {
      rules[i].forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          path +=
              '&rules%5B$i%5D%5B$key%5D=${Uri.encodeQueryComponent(value.toString())}';
        }
      });
    }
    path = await _appendQueryParams(path);
    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw ApiException(
          _extractErrorMessageFromResponse(response) ??
              'Не удалось загрузить товары',
          response.statusCode);
    }
    return PricingGoodsPage.fromJson(json.decode(response.body));
  }

  Future<List<PricingDocumentItem>> getPricingDocumentItems(
      int pricingId) async {
    final path = await _appendQueryParams('/pricing/$pricingId');
    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw ApiException(
          _extractErrorMessageFromResponse(response) ??
              'Не удалось загрузить документ цен',
          response.statusCode);
    }
    final decoded = json.decode(response.body);
    final data = decoded is List
        ? decoded
        : decoded is Map && decoded['result'] is List
            ? decoded['result'] as List
            : const [];
    return data
        .whereType<Map>()
        .map((item) =>
            PricingDocumentItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> createPricingDocument({
    required List<PricingGood> goods,
    required DateTime startDate,
  }) async {
    final path = await _appendQueryParams('/pricing');
    final payload = {
      'data': goods
          .map((good) {
            final enteredPrices = good.prices
                .where((price) => price.isEntered)
                .map((price) => {
                      'price_type_id': price.priceTypeId,
                      'price': price.newPrice,
                    })
                .toList();
            return enteredPrices.isEmpty
                ? null
                : {'variant_id': good.variantId, 'prices': enteredPrices};
          })
          .whereType<Map<String, dynamic>>()
          .toList(),
      'start_date': startDate.toIso8601String(),
    };
    final response = await _postRequest(path, payload);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
          _extractErrorMessageFromResponse(response) ??
              'Не удалось сохранить цены',
          response.statusCode);
    }
  }
}

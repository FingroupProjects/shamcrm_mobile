import 'package:crm_task_manager/utils/safe_converters.dart';

enum TopSellingTimePeriod { day, week, month, year }

class TopSellingGoodsResponse {
  final TopSellingResult result;
  final dynamic errors;

  TopSellingGoodsResponse({required this.result, required this.errors});

  factory TopSellingGoodsResponse.fromJson(Map<String, dynamic> json) {
    return TopSellingGoodsResponse(
      result: TopSellingResult.fromJson(SafeConverters.toMap(json['result'])),
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result.toJson(),
      'errors': errors,
    };
  }
}

class TopSellingResult {
  final int? currentPage;
  final List<TopSellingData> data;
  final String firstPageUrl;
  final int from; // Non-nullable
  final int lastPage; // Non-nullable
  final String lastPageUrl;
  final List<Link> links;
  final String? nextPageUrl;
  final String path;
  final int perPage; // Non-nullable
  final String? prevPageUrl;
  final num to; // Non-nullable
  final num total; // Non-nullable

  TopSellingResult({
    this.currentPage,
    required this.data,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory TopSellingResult.fromJson(Map<String, dynamic> json) {
    return TopSellingResult(
      currentPage: SafeConverters.toIntOrNull(json['current_page']),
      data: SafeConverters.toList(json['data'])
          .map((item) => TopSellingData.fromJson(SafeConverters.toMap(item)))
          .toList(),
      firstPageUrl: SafeConverters.toSafeString(json['first_page_url']),
      from: SafeConverters.toInt(json['from']),
      lastPage: SafeConverters.toInt(json['last_page']),
      lastPageUrl: SafeConverters.toSafeString(json['last_page_url']),
      links: SafeConverters.toList(json['links'])
          .map((item) => Link.fromJson(SafeConverters.toMap(item)))
          .toList(),
      nextPageUrl: SafeConverters.toStringOrNull(json['next_page_url']),
      path: SafeConverters.toSafeString(json['path']),
      perPage: SafeConverters.toInt(json['per_page']),
      prevPageUrl: SafeConverters.toStringOrNull(json['prev_page_url']),
      to: SafeConverters.toNum(json['to']),
      total: SafeConverters.toNum(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'data': data.map((item) => item.toJson()).toList(),
      'first_page_url': firstPageUrl,
      'from': from,
      'last_page': lastPage,
      'last_page_url': lastPageUrl,
      'links': links.map((item) => item.toJson()).toList(),
      'next_page_url': nextPageUrl,
      'path': path,
      'per_page': perPage,
      'prev_page_url': prevPageUrl,
      'to': to,
      'total': total,
    };
  }
}

class TopSellingData {
  final int id;
  final String name;
  final String category;
  final num totalQuantity;
  final String totalAmount;
  final String avgPrice;

  TopSellingData({
    required this.id,
    required this.name,
    required this.category,
    required this.totalQuantity,
    required this.totalAmount,
    required this.avgPrice,
  });

  factory TopSellingData.fromJson(Map<String, dynamic> json) {
    return TopSellingData(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      category: SafeConverters.toSafeString(json['category']),
      totalQuantity: SafeConverters.toNum(json['total_quantity']),
      totalAmount: SafeConverters.toSafeString(json['total_amount']),
      avgPrice: SafeConverters.toSafeString(json['avg_price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'total_quantity': totalQuantity,
      'total_amount': totalAmount,
      'avg_price': avgPrice,
    };
  }
}

class Link {
  final String? url;
  final String label;
  final bool active;

  Link({required this.url, required this.label, required this.active});

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      url: SafeConverters.toStringOrNull(json['url']),
      label: SafeConverters.toSafeString(json['label']),
      active: SafeConverters.toBool(json['active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'label': label,
      'active': active,
    };
  }
}

class AllTopSellingData {
  final TopSellingTimePeriod period;
  final TopSellingResult data;

  AllTopSellingData({required this.period, required this.data});
}

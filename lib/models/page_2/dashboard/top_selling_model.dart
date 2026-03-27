enum TopSellingTimePeriod { day, week, month, year }

class TopSellingGoodsResponse {
  final TopSellingResult result;
  final dynamic errors;

  TopSellingGoodsResponse({required this.result, required this.errors});

  factory TopSellingGoodsResponse.fromJson(Map<String, dynamic> json) {
    return TopSellingGoodsResponse(
      result: TopSellingResult.fromJson(json['result'] as Map<String, dynamic>),
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
      currentPage: json['current_page'] as int?,
      data: (json['data'] as List<dynamic>)
          .map((item) => TopSellingData.fromJson(item as Map<String, dynamic>))
          .toList(),
      firstPageUrl: json['first_page_url'] as String? ?? '',
      from: json['from'] as int? ?? 0, // Default to 0 if null
      lastPage: json['last_page'] as int? ?? 0, // Default to 0 if null
      lastPageUrl: json['last_page_url'] as String? ?? '',
      links: (json['links'] as List<dynamic>)
          .map((item) => Link.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextPageUrl: json['next_page_url'] as String?,
      path: json['path'] as String? ?? '',
      perPage: json['per_page'] as int? ?? 0, // Default to 0 if null
      prevPageUrl: json['prev_page_url'] as String?,
      to: json['to'] as int? ?? 0, // Default to 0 if null
      total: json['total'] as int? ?? 0, // Default to 0 if null
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
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      totalQuantity: json['total_quantity'] as int,
      totalAmount: json['total_amount'].toString(),
      avgPrice: json['avg_price'].toString(),
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
      url: json['url'] as String?,
      label: json['label'] as String,
      active: json['active'] as bool,
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
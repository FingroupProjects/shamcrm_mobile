import 'package:crm_task_manager/models/page_2/order_status_model.dart';

class Order {
  final int id;
  final String phone;
  final String orderNumber;
  final bool delivery;
  final String? deliveryAddress;
  final OrderLead lead;
  final OrderStatusName orderStatus;
  final List<Good> goods;
  final int? organizationId;

  Order({
    required this.id,
    required this.phone,
    required this.orderNumber,
    required this.delivery,
    this.deliveryAddress,
    required this.lead,
    required this.orderStatus,
    required this.goods,
    this.organizationId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      return Order(
        id: json['id'] ?? 0,
        phone: (json['phone'] ?? '').toString(),
        orderNumber: json['order_number'] ?? '',
        delivery: json['deliveryType'] == 'delivery',
        deliveryAddress: json['delivery_address'] != null
            ? json['delivery_address']['address']?.toString()
            : null,
        lead: OrderLead.fromJson(json['lead'] ?? {}),
        orderStatus: OrderStatusName.fromJson(json['order_status'] ?? {}),
        goods: (json['order_goods'] as List? ?? [])
            .map((g) => Good.fromJson(g))
            .toList(),
        organizationId: json['organization_id'] ?? 1,
      );
    } catch (e) {
      print('Error parsing Order: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'order_number': orderNumber,
      'delivery': delivery,
      'delivery_address': deliveryAddress,
      'lead': lead.toJson(),
      'order_status': orderStatus.toJson(),
      'order_goods': goods.map((g) => g.toJson()).toList(),
      'organization_id': organizationId,
    };
  }

  Order copyWith({
    int? id,
    String? phone,
    String? orderNumber,
    bool? delivery,
    String? deliveryAddress,
    OrderLead? lead,
    OrderStatusName? orderStatus,
    List<Good>? goods,
    int? organizationId,
  }) {
    return Order(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      orderNumber: orderNumber ?? this.orderNumber,
      delivery: delivery ?? this.delivery,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      lead: lead ?? this.lead,
      orderStatus: orderStatus ?? this.orderStatus,
      goods: goods ?? this.goods,
      organizationId: organizationId ?? this.organizationId,
    );
  }
}

class OrderLead {
  final int id;
  final String name;
  final String? facebookLogin;
  final String? instaLogin;
  final String? tgNick;
  final String? tgId;
  final List<dynamic> channels;
  final String? position;
  final String? waName;
  final String? waPhone;
  final String? address;
  final String phone;
  final String? birthday;
  final String? description;
  final DateTime? createdAt;
  final int? lastUpdate;

  OrderLead({
    required this.id,
    required this.name,
    this.facebookLogin,
    this.instaLogin,
    this.tgNick,
    this.tgId,
    required this.channels,
    this.position,
    this.waName,
    this.waPhone,
    this.address,
    required this.phone,
    this.birthday,
    this.description,
    this.createdAt,
    this.lastUpdate,
  });

  factory OrderLead.fromJson(Map<String, dynamic> json) {
    return OrderLead(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      facebookLogin: json['facebook_login'],
      instaLogin: json['insta_login'],
      tgNick: json['tg_nick'],
      tgId: json['tg_id']?.toString(),
      channels: json['channels'] ?? [],
      position: json['position']?.toString(),
      waName: json['wa_name'],
      waPhone: json['wa_phone']?.toString(),
      address: json['address'],
      phone: (json['phone'] ?? '').toString(),
      birthday: json['birthday'],
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      lastUpdate: json['last_update'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'facebook_login': facebookLogin,
      'insta_login': instaLogin,
      'tg_nick': tgNick,
      'tg_id': tgId,
      'channels': channels,
      'position': position,
      'wa_name': waName,
      'wa_phone': waPhone,
      'address': address,
      'phone': phone,
      'birthday': birthday,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'last_update': lastUpdate,
    };
  }
}

class Good {
  final GoodItem good;
  final GoodItem? variantGood;
  final int goodId;
  final String goodName;
  final int quantity;
  final double price;

  Good({
    required this.good,
    this.variantGood,
    required this.goodId,
    required this.goodName,
    required this.quantity,
    required this.price,
  });

  factory Good.fromJson(Map<String, dynamic> json) {
    // Парсим good
    final goodItem = GoodItem.fromJson(json['good'] ?? {});
    
    // Парсим variant.good, если variant существует
    final variantGoodItem = json['variant'] != null && json['variant']['good'] != null
        ? GoodItem.fromJson(json['variant']['good'])
        : null;

    return Good(
      good: goodItem,
      variantGood: variantGoodItem,
      goodId: json['good_id'] ?? json['good']?['id'] ?? 0,
      goodName: json['good']?['name'] ?? json['variant']?['good']?['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(
              json['variant']?['price']?['price']?.toString() ??
                  json['good']?['good_price']?['price']?.toString() ??
                  '0') ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'good_id': goodId,
      'good_name': goodName,
      'quantity': quantity,
      'price': price,
    };
  }
}

class GoodItem {
  final int id;
  final String name;
  final String description;
  final int quantity;
  final List<GoodFile> files;

  GoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.files,
  });

  factory GoodItem.fromJson(Map<String, dynamic> json) {
    return GoodItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      files: (json['files'] as List? ?? [])
          .map((f) => GoodFile.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GoodFile {
  final int id;
  final String name;
  final String path;

  GoodFile({
    required this.id,
    required this.name,
    required this.path,
  });

  factory GoodFile.fromJson(Map<String, dynamic> json) {
    return GoodFile(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      path: json['path'] ?? '',
    );
  }
}

class OrderResponse {
  final List<Order> data;
  final Pagination pagination;

  OrderResponse({required this.data, required this.pagination});

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      data: (json['data'] as List? ?? []).map((o) => Order.fromJson(o)).toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      count: json['count'] ?? 0,
      perPage: json['per_page'] ?? 20,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

class OrderStatusName {
  final int id;
  final String name;

  OrderStatusName({required this.id, required this.name});

  factory OrderStatusName.fromJson(Map<String, dynamic> json) {
    return OrderStatusName(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  factory OrderStatusName.fromOrderStatus(OrderStatus status) {
    return OrderStatusName(
      id: status.id,
      name: status.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
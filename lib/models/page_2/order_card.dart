// models/order_model.dart

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
    print('Parsing Order JSON: $json');
    return Order(
      id: json['id'] ?? 0,
      phone: (json['phone'] ?? '').toString(),
      orderNumber: json['order_number'] ?? '',
      delivery: json['delivery'] ?? false,
      deliveryAddress: json['delivery_address'],
      lead: OrderLead.fromJson(json['lead'] ?? {}),
      orderStatus: OrderStatusName.fromJson(json['orderStatus'] ?? {}),
      goods: (json['goods'] as List? ?? []).map((g) => Good.fromJson(g)).toList(),
      organizationId: json['organization_id'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'order_number': orderNumber,
      'delivery': delivery,
      'delivery_address': deliveryAddress,
      'lead': lead.toJson(),
      'orderStatus': orderStatus.toJson(),
      'goods': goods.map((g) => g.toJson()).toList(),
      'organization_id': organizationId,
    };
  }

  // Исправленный метод copyWith
  Order copyWith({
    int? id, // Оставляем int?, так как это входной параметр
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
      id: id ?? this.id, // this.id всегда int, так как id в классе не null
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
    print('Parsing Lead JSON: $json');
    return OrderLead(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      facebookLogin: json['facebook_login'],
      instaLogin: json['insta_login'],
      tgNick: json['tg_nick'],
      tgId: json['tg_id']?.toString(),
      channels: json['channels'] ?? [],
      position: json['position'] != null ? json['position'].toString() : null,
      waName: json['wa_name'],
      waPhone: json['wa_phone']?.toString(),
      address: json['address'],
      phone: (json['phone'] ?? '').toString(),
      birthday: json['birthday'],
      description: json['description'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
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
  final int goodId; // Прямое поле вместо вложенного good.id
  final String goodName; // Прямое поле вместо вложенного good.name
  final int quantity;
  final double price; // Добавляем цену для UI и API

  Good({
    required this.good,
    required this.goodId,
    required this.goodName,
    required this.quantity,
    required this.price,
  });

  factory Good.fromJson(Map<String, dynamic> json) {
    return Good(
      good: GoodItem.fromJson(json['good'] ?? {}),
      goodId: json['good_id'] ?? json['good']?['id'] ?? 0, // Поддержка разных форматов JSON
      goodName: json['good_name'] ?? json['good']?['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(), // Парсим цену
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'good_id': good.id, // Используем good.id для API
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
      files: (json['files'] as List? ?? []).map((f) => GoodFile.fromJson(f as Map<String, dynamic>)).toList(),
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
    print('Parsing OrderStatus JSON: $json');
    return OrderStatusName(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  // Новый метод для преобразования из OrderStatus
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


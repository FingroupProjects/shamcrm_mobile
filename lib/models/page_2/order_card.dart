// models/order_model.dart

class Order {
  final int id;
  final String phone;
  final String orderNumber;
  final String? deliveryAddress;
  final OrderLead lead;
  final OrderStatusName orderStatus;
  final List<Good> goods;

  Order({
    required this.id,
    required this.phone,
    required this.orderNumber,
    this.deliveryAddress,
    required this.lead,
    required this.orderStatus,
    required this.goods,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print('Parsing Order JSON: $json');
    print('id type: ${json['id'].runtimeType}, value: ${json['id']}');
    print('phone type: ${json['phone'].runtimeType}, value: ${json['phone']}');
    print(
        'order_number type: ${json['order_number'].runtimeType}, value: ${json['order_number']}');
    print(
        'delivery_address type: ${json['delivery_address'].runtimeType}, value: ${json['delivery_address']}');
    print('lead type: ${json['lead'].runtimeType}, value: ${json['lead']}');
    print(
        'orderStatus type: ${json['orderStatus'].runtimeType}, value: ${json['orderStatus']}');
    print('goods type: ${json['goods'].runtimeType}, value: ${json['goods']}');
    return Order(
      id: json['id'] ?? 0,
      phone: (json['phone'] ?? '').toString(), // Приводим к строке
      orderNumber: json['order_number'] ?? '',
      deliveryAddress: json['delivery_address'],
      lead: OrderLead.fromJson(json['lead'] ?? {}),
      orderStatus: OrderStatusName.fromJson(json['orderStatus'] ?? {}),
      goods:
          (json['goods'] as List? ?? []).map((g) => Good.fromJson(g)).toList(),
    );
  }
}

// models/lead_model.dart
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
    print('id type: ${json['id'].runtimeType}, value: ${json['id']}');
    print('name type: ${json['name'].runtimeType}, value: ${json['name']}');
    print(
        'facebook_login type: ${json['facebook_login'].runtimeType}, value: ${json['facebook_login']}');
    print(
        'insta_login type: ${json['insta_login'].runtimeType}, value: ${json['insta_login']}');
    print(
        'tg_nick type: ${json['tg_nick'].runtimeType}, value: ${json['tg_nick']}');
    print('tg_id type: ${json['tg_id'].runtimeType}, value: ${json['tg_id']}');
    print(
        'channels type: ${json['channels'].runtimeType}, value: ${json['channels']}');
    print(
        'position type: ${json['position'].runtimeType}, value: ${json['position']}');
    print(
        'wa_name type: ${json['wa_name'].runtimeType}, value: ${json['wa_name']}');
    print(
        'wa_phone type: ${json['wa_phone'].runtimeType}, value: ${json['wa_phone']}');
    print(
        'address type: ${json['address'].runtimeType}, value: ${json['address']}');
    print('phone type: ${json['phone'].runtimeType}, value: ${json['phone']}');
    print(
        'birthday type: ${json['birthday'].runtimeType}, value: ${json['birthday']}');
    print(
        'description type: ${json['description'].runtimeType}, value: ${json['description']}');
    print(
        'created_at type: ${json['created_at'].runtimeType}, value: ${json['created_at']}');
    print(
        'last_update type: ${json['last_update'].runtimeType}, value: ${json['last_update']}');
    return OrderLead(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      facebookLogin: json['facebook_login'],
      instaLogin: json['insta_login'],
      tgNick: json['tg_nick'],
      tgId: json['tg_id']?.toString(), // Приводим к строке, если не null
      channels: json['channels'] ?? [],
      position: json['position'] != null ? json['position'].toString() : null,
      waName: json['wa_name'],
      waPhone: json['wa_phone']?.toString(), // Приводим к строке, если не null
      address: json['address'],
      phone: (json['phone'] ?? '').toString(), // Приводим к строке
      birthday: json['birthday'],
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
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
  final int quantity;

  Good({required this.good, required this.quantity});

  factory Good.fromJson(Map<String, dynamic> json) {
    return Good(
      good: GoodItem.fromJson(json['good'] as Map<String, dynamic>),
      quantity: json['quantity'] ?? 0,
    );
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
      data:
          (json['data'] as List? ?? []).map((o) => Order.fromJson(o)).toList(),
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

// Обновляем OrderStatus
class OrderStatusName {
  final int id;
  final String name;

  OrderStatusName({required this.id, required this.name});

  factory OrderStatusName.fromJson(Map<String, dynamic> json) {
    print('Parsing OrderStatus JSON: $json');
    print('id type: ${json['id'].runtimeType}, value: ${json['id']}');
    print('name type: ${json['name'].runtimeType}, value: ${json['name']}');
    return OrderStatusName(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

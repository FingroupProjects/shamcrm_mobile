  import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
  class Order {
    final int id;
    final String phone;
    final String orderNumber;
    final bool delivery;
    final String? deliveryAddress;
    final int? deliveryAddressId;
    final String? branchName;
    final int? branchId; // Новое поле для branch_id
    final ManagerData? manager;
    final OrderLead lead;
    final OrderStatusName orderStatus;
    final List<Good> goods;
    final int? organizationId;
    final String? commentToCourier;
    final double? sum;
    final String? paymentMethod; // Add this field
    final String? paymentStatus; // Новое поле
        final DateTime? createdAt;



    Order({
      required this.id,
      required this.phone,
      required this.orderNumber,
      required this.delivery,
      this.deliveryAddress,
      this.deliveryAddressId,
      this.branchName,
      this.branchId,
      required this.lead,
      required this.orderStatus,
      required this.goods,
      this.organizationId,
      this.commentToCourier,
      this.manager,
      this.sum,
      this.paymentMethod, // Add to constructor
      this.paymentStatus, // Добавляем в конструктор
      this.createdAt
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
        deliveryAddressId: json['delivery_address_id'] != null
            ? int.tryParse(json['delivery_address_id'].toString())
            : null,
        branchName: json['branch'] != null
            ? json['branch']['name']?.toString()
            : null,
        branchId: json['branch_id'] != null
            ? int.tryParse(json['branch_id'].toString())
            : null,
        lead: OrderLead.fromJson(json['lead'] ?? {}),
        orderStatus: OrderStatusName.fromJson(json['order_status'] ?? {}),
          createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
        goods: (json['order_goods'] as List? ?? [])
            .map((g) => Good.fromJson(g))
            .toList(),
        organizationId: json['organization_id'] ?? 1,
        commentToCourier: json['comment_to_courier']?.toString(),
        sum: double.tryParse(json['sum']?.toString() ?? '0'),
        paymentMethod: json['payment_type']?.toString(), // Parse payment_type
        paymentStatus: json['payment_status']?.toString(), // Парсим payment_status
         manager: json['manager'] != null ? ManagerData.fromJson(json['manager']) : null,
      );
    } catch (e) {
      //print('Error parsing Order: $e');
      //print('JSON: $json');
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
        'delivery_address_id': deliveryAddressId,
        'branch_name': branchName,
        'branch_id': branchId, // Добавляем в JSON
        'lead': lead.toJson(),
        'order_status': orderStatus.toJson(),
                'created_at': createdAt?.toIso8601String(),

        'order_goods': goods.map((g) => g.toJson()).toList(),
        'organization_id': organizationId,
        'comment_to_courier': commentToCourier,
        'sum': sum,
        'payment_status': paymentStatus, // Добавляем в JSON
      };
    }

    Order copyWith({
      int? id,
      String? phone,
      String? orderNumber,
      bool? delivery,
      String? deliveryAddress,
      int? deliveryAddressId,
      String? branchName,
      int? branchId,
      OrderLead? lead,
      OrderStatusName? orderStatus,
      List<Good>? goods,
      int? organizationId,
      String? commentToCourier,
      double? sum,
      String? paymentStatus,
    }) {
      return Order(
        id: id ?? this.id,
        phone: phone ?? this.phone,
        orderNumber: orderNumber ?? this.orderNumber,
        delivery: delivery ?? this.delivery,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
        branchName: branchName ?? this.branchName,
        branchId: branchId ?? this.branchId, // Добавляем
        lead: lead ?? this.lead,
        orderStatus: orderStatus ?? this.orderStatus,
        goods: goods ?? this.goods,
        organizationId: organizationId ?? this.organizationId,
        commentToCourier: commentToCourier ?? this.commentToCourier,
        sum: sum ?? this.sum,
        paymentStatus: paymentStatus ?? this.paymentStatus,
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

  // Метод для получения корректного ID товара
  int getCorrectGoodId() {
    if (variantGood != null && variantGood!.id != 0) {
      return variantGood!.id; // Приоритет variantGood.id (19)
    }
    if (good.id != 0) {
      return good.id;
    }
    return goodId;
  }

  // Метод для получения корректного названия товара
  String getCorrectGoodName() {
    if (variantGood != null && variantGood!.name.isNotEmpty) {
      return variantGood!.name;
    }
    if (good.name.isNotEmpty) {
      return good.name;
    }
    return goodName;
  }

  // Метод для получения корректных файлов
  List<GoodFile> getCorrectFiles() {
    if (good.files.isNotEmpty) {
      return good.files;
    }
    if (variantGood != null && variantGood!.files.isNotEmpty) {
      return variantGood!.files;
    }
    return [];
  }

  factory Good.fromJson(Map<String, dynamic> json) {
    final goodItem = GoodItem.fromJson(json['good'] ?? {});
    final variantGoodItem = json['variant'] != null && json['variant']['good'] != null
        ? GoodItem.fromJson(json['variant']['good'])
        : null;

    return Good(
      good: goodItem,
      variantGood: variantGoodItem,
      goodId: json['variant_id'] ?? json['good_id'] ?? json['good']?['id'] ?? 0,
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
      'variant_id': getCorrectGoodId(),
      'good_name': getCorrectGoodName(),
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
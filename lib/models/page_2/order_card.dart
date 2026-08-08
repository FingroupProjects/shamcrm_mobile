import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/models/dealById_model.dart';

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
  final OrderDeal? deal;
  final OrderStatusName orderStatus;
  final List<Good> goods;
  final int? organizationId;
  final String? commentToCourier;
  final double? sum;
  final String? paymentMethod; // Add this field
  final String? paymentStatus; // Новое поле
  final int? integrationId;
  final DateTime? createdAt;
  final int?
      storageId; // Новое поле для storage_id (пока используется вместо branchId)
  final List<CustomFieldValue> customFieldValues;
  final List<DirectoryValue> directoryValues;
  final List<OrderFile> files;
  final int? reasonForRefusalId;
  final String? reasonForRefusalComment;
  final String? refusalReasonText;

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
    this.deal,
    required this.orderStatus,
    required this.goods,
    this.organizationId,
    this.commentToCourier,
    this.manager,
    this.sum,
    this.paymentMethod, // Add to constructor
    this.paymentStatus, // Добавляем в конструктор
    this.integrationId,
    this.createdAt,
    this.storageId,
    this.customFieldValues = const [],
    this.directoryValues = const [],
    this.files = const [],
    this.reasonForRefusalId,
    this.reasonForRefusalComment,
    this.refusalReasonText,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      final deliveryAddressRaw = json['delivery_address'];
      final branchRaw = json['branch'];
      final isDelivery = json['delivery'] is bool
          ? json['delivery'] as bool
          : json['deliveryType'] == 'delivery';

      return Order(
        id: json['id'] ?? 0,
        phone: (json['phone'] ?? '').toString(),
        orderNumber: json['order_number']?.toString() ?? '',
        delivery: isDelivery,
        deliveryAddress: deliveryAddressRaw is Map<String, dynamic>
            ? deliveryAddressRaw['address']?.toString()
            : deliveryAddressRaw?.toString(),
        deliveryAddressId: json['delivery_address_id'] != null
            ? int.tryParse(json['delivery_address_id'].toString())
            : null,
        branchName: branchRaw is Map<String, dynamic>
            ? branchRaw['name']?.toString()
            : (json['branch_name'] ?? branchRaw)?.toString(),
        branchId: json['branch_id'] != null
            ? int.tryParse(json['branch_id'].toString())
            : null,
        lead: OrderLead.fromJson(json['lead'] ?? {}),
        deal: json['deal'] != null
            ? OrderDeal.fromJson(json['deal'] as Map<String, dynamic>)
            : null,
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
        paymentStatus:
            json['payment_status']?.toString(), // Парсим payment_status
        integrationId: int.tryParse(json['integration_id']?.toString() ?? ''),
        manager: json['manager'] != null
            ? ManagerData.fromJson(json['manager'])
            : null,
        storageId: json['storage_id'] != null
            ? int.tryParse(json['storage_id'].toString())
            : null,
        reasonForRefusalId: json['reason_for_refusal_id'] is int
            ? json['reason_for_refusal_id'] as int
            : int.tryParse('${json['reason_for_refusal_id']}'),
        reasonForRefusalComment: json['reason_for_refusal']?.toString(),
        refusalReasonText: _extractRefusalReasonText(json['refusalReason']),
        // The order API returns this relation as `custom_field_values`.
        // Keep the camelCase fallback for locally cached/legacy payloads.
        customFieldValues: ((json['custom_field_values'] ??
                    json['customFieldValues']) as List<dynamic>? ??
                [])
            .whereType<Map<String, dynamic>>()
            .map(CustomFieldValue.fromJson)
            .toList(),
        directoryValues: (json['directory_values'] as List<dynamic>? ?? [])
            .map(
                (item) => DirectoryValue.fromJson(item as Map<String, dynamic>))
            .toList(),
        files: (json['files'] as List<dynamic>? ?? [])
            .map((item) => OrderFile.fromJson(item as Map<String, dynamic>))
            .toList(),
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
      'deal': deal?.toJson(),
      'order_status': orderStatus.toJson(),
      'created_at': createdAt?.toIso8601String(),

      'order_goods': goods.map((g) => g.toJson()).toList(),
      'organization_id': organizationId,
      'comment_to_courier': commentToCourier,
      'sum': sum,
      'payment_status': paymentStatus, // Добавляем в JSON
      'payment_type': paymentMethod, // Add to JSON
      'integration_id': integrationId,
      'storage_id': storageId,
      'reason_for_refusal_id': reasonForRefusalId,
      'reason_for_refusal': reasonForRefusalComment,
      'refusalReason': refusalReasonText,
      'customFieldValues': customFieldValues.map((e) => e.toJson()).toList(),
      'directory_values': directoryValues.map((e) => e.toJson()).toList(),
      'files': files.map((e) => e.toJson()).toList(),
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
    OrderDeal? deal,
    OrderStatusName? orderStatus,
    List<Good>? goods,
    int? organizationId,
    String? commentToCourier,
    double? sum,
    String? paymentStatus,
    int? integrationId,
    int? storageId,
    List<CustomFieldValue>? customFieldValues,
    List<DirectoryValue>? directoryValues,
    List<OrderFile>? files,
    int? reasonForRefusalId,
    String? reasonForRefusalComment,
    String? refusalReasonText,
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
      deal: deal ?? this.deal,
      orderStatus: orderStatus ?? this.orderStatus,
      goods: goods ?? this.goods,
      organizationId: organizationId ?? this.organizationId,
      commentToCourier: commentToCourier ?? this.commentToCourier,
      sum: sum ?? this.sum,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      integrationId: integrationId ?? this.integrationId,
      storageId: storageId ?? this.storageId,
      reasonForRefusalId: reasonForRefusalId ?? this.reasonForRefusalId,
      reasonForRefusalComment:
          reasonForRefusalComment ?? this.reasonForRefusalComment,
      refusalReasonText: refusalReasonText ?? this.refusalReasonText,
      customFieldValues: customFieldValues ?? this.customFieldValues,
      directoryValues: directoryValues ?? this.directoryValues,
      files: files ?? this.files,
    );
  }
}

class OrderFile {
  final int id;
  final String name;
  final String path;
  final String? size;

  const OrderFile({
    required this.id,
    required this.name,
    required this.path,
    this.size,
  });

  factory OrderFile.fromJson(Map<String, dynamic> json) {
    return OrderFile(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? json['file_name'] ?? '').toString(),
      path: (json['path'] ?? json['url'] ?? json['file'] ?? '').toString(),
      size: json['size']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'size': size,
    };
  }
}

String? _extractRefusalReasonText(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    return raw.trim().isEmpty ? null : raw.trim();
  }
  if (raw is Map<String, dynamic>) {
    final text = raw['text']?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
    final name = raw['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
  }
  return null;
}

class OrderDeal {
  final int id;
  final String name;

  const OrderDeal({
    required this.id,
    required this.name,
  });

  factory OrderDeal.fromJson(Map<String, dynamic> json) {
    return OrderDeal(
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
  final String? availabilityStatus;

  Good({
    required this.good,
    this.variantGood,
    required this.goodId,
    required this.goodName,
    required this.quantity,
    required this.price,
    this.availabilityStatus,
  });

  // Метод для получения корректного ID товара
  // Возвращает ID товара с приоритетом variant_id из order_goods
  int getCorrectGoodId() {
    if (goodId != 0) {
      return goodId; // variant_id из order_goods
    }
    if (variantGood != null && variantGood!.id != 0) {
      return variantGood!.id; // ID из variant.good
    }
    if (good.id != 0) {
      return good.id; // ID из good
    }
    return 0;
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
    String? parseStatus(dynamic value) {
      if (value == null) return null;
      if (value is Map) {
        for (final key in const ['name', 'title', 'value', 'status']) {
          final parsed = parseStatus(value[key]);
          if (parsed != null) return parsed;
        }
        return null;
      }
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final goodRaw = json['good'];
    final variantRaw = json['variant'];
    final goodItem = goodRaw is Map<String, dynamic>
        ? GoodItem.fromJson(goodRaw)
        : GoodItem(
            id: json['good_id'] ?? json['variant_id'] ?? 0,
            name: json['good_name']?.toString() ?? '',
            description: '',
            quantity: json['quantity'] ?? 0,
            files: const [],
          );
    final variantGoodItem = variantRaw is Map<String, dynamic> &&
            variantRaw['good'] is Map<String, dynamic>
        ? GoodItem.fromJson(variantRaw['good'] as Map<String, dynamic>)
        : null;
    final cachedGoodName = json['good_name']?.toString();
    final variantGoodRaw =
        variantRaw is Map<String, dynamic> ? variantRaw['good'] : null;
    final availabilityStatus = parseStatus(json['availability_status']) ??
        parseStatus(json['status_name']) ??
        parseStatus(json['status']) ??
        (goodRaw is Map
            ? parseStatus(goodRaw['availability_status']) ??
                parseStatus(goodRaw['status_name']) ??
                parseStatus(goodRaw['status'])
            : null) ??
        (variantRaw is Map
            ? parseStatus(variantRaw['availability_status']) ??
                parseStatus(variantRaw['status_name']) ??
                parseStatus(variantRaw['status'])
            : null) ??
        (variantGoodRaw is Map
            ? parseStatus(variantGoodRaw['availability_status']) ??
                parseStatus(variantGoodRaw['status_name']) ??
                parseStatus(variantGoodRaw['status'])
            : null);

    return Good(
      good: goodItem,
      variantGood: variantGoodItem,
      goodId: json['variant_id'] ?? json['good_id'] ?? goodItem.id,
      goodName: cachedGoodName ??
          (goodItem.name.isNotEmpty
              ? goodItem.name
              : (variantGoodItem?.name ?? '')),
      quantity: json['quantity'] ?? 0,
      availabilityStatus: availabilityStatus,
      price: double.tryParse(
            json['price']?.toString() ??
                (variantRaw is Map<String, dynamic>
                    ? ((variantRaw['price'] as Map<String, dynamic>?)?['price'])
                        ?.toString()
                    : null) ??
                (goodRaw is Map<String, dynamic>
                    ? ((goodRaw['good_price']
                            as Map<String, dynamic>?)?['price'])
                        ?.toString()
                    : null) ??
                '0',
          ) ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variant_id': getCorrectGoodId(),
      'good_name': getCorrectGoodName(),
      'quantity': quantity,
      'price': price,
      if (availabilityStatus != null) 'availability_status': availabilityStatus,
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
    final rawOrders = (json['data'] as List?) ??
        (json['result'] as List?) ??
        const <dynamic>[];
    final rawPagination = json['pagination'] ??
        {
          'total': rawOrders.length,
          'count': rawOrders.length,
          'per_page': rawOrders.length == 0 ? 20 : rawOrders.length,
          'current_page': 1,
          'total_pages': 1,
        };

    return OrderResponse(
      data: rawOrders.map((o) => Order.fromJson(o)).toList(),
      pagination: Pagination.fromJson(rawPagination),
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

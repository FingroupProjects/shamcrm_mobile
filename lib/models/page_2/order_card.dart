import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/models/deal/dealById_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

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
      final isDelivery = SafeConverters.toBoolOrNull(json['delivery']) ??
          (json['deliveryType'] == 'delivery');

      return Order(
        id: SafeConverters.toInt(json['id']),
        phone: SafeConverters.toSafeString(json['phone']),
        orderNumber: SafeConverters.toSafeString(json['order_number']),
        delivery: isDelivery,
        deliveryAddress: deliveryAddressRaw is Map
            ? SafeConverters.toStringOrNull(
                SafeConverters.toMap(deliveryAddressRaw)['address'])
            : SafeConverters.toStringOrNull(deliveryAddressRaw),
        deliveryAddressId: SafeConverters.toIntOrNull(json['delivery_address_id']),
        branchName: branchRaw is Map
            ? SafeConverters.toStringOrNull(SafeConverters.toMap(branchRaw)['name'])
            : SafeConverters.toStringOrNull(json['branch_name'] ?? branchRaw),
        branchId: SafeConverters.toIntOrNull(json['branch_id']),
        lead: OrderLead.fromJson(SafeConverters.toMap(json['lead'])),
        deal: SafeConverters.toMapOrNull(json['deal']) != null
            ? OrderDeal.fromJson(SafeConverters.toMap(json['deal']))
            : null,
        orderStatus: OrderStatusName.fromJson(
            SafeConverters.toMap(json['order_status'])),
        createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
        goods: SafeConverters.toList(json['order_goods'])
            .map((g) => Good.fromJson(SafeConverters.toMap(g)))
            .toList(),
        organizationId: SafeConverters.toInt(json['organization_id'], defaultValue: 1),
        commentToCourier: SafeConverters.toStringOrNull(json['comment_to_courier']),
        sum: SafeConverters.toDoubleOrNull(json['sum']),
        paymentMethod: SafeConverters.toStringOrNull(json['payment_type']),
        paymentStatus: SafeConverters.toStringOrNull(json['payment_status']),
        integrationId: SafeConverters.toIntOrNull(json['integration_id']),
        manager: SafeConverters.toMapOrNull(json['manager']) != null
            ? ManagerData.fromJson(SafeConverters.toMap(json['manager']))
            : null,
        storageId: SafeConverters.toIntOrNull(json['storage_id']),
        reasonForRefusalId: SafeConverters.toIntOrNull(json['reason_for_refusal_id']),
        reasonForRefusalComment: SafeConverters.toStringOrNull(json['reason_for_refusal']),
        refusalReasonText: _extractRefusalReasonText(json['refusalReason']),
        customFieldValues: SafeConverters.toList(
                json['custom_field_values'] ?? json['customFieldValues'])
            .map((item) =>
                CustomFieldValue.fromJson(SafeConverters.toMap(item)))
            .toList(),
        directoryValues: SafeConverters.toList(json['directory_values'])
            .map((item) =>
                DirectoryValue.fromJson(SafeConverters.toMap(item)))
            .toList(),
        files: SafeConverters.toList(json['files'])
            .map((item) => OrderFile.fromJson(SafeConverters.toMap(item)))
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'] ?? json['file_name']),
      path: SafeConverters.toSafeString(json['path'] ?? json['url'] ?? json['file']),
      size: SafeConverters.toStringOrNull(json['size']),
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      facebookLogin: SafeConverters.toStringOrNull(json['facebook_login']),
      instaLogin: SafeConverters.toStringOrNull(json['insta_login']),
      tgNick: SafeConverters.toStringOrNull(json['tg_nick']),
      tgId: SafeConverters.toStringOrNull(json['tg_id']),
      channels: SafeConverters.toList(json['channels']),
      position: SafeConverters.toStringOrNull(json['position']),
      waName: SafeConverters.toStringOrNull(json['wa_name']),
      waPhone: SafeConverters.toStringOrNull(json['wa_phone']),
      address: SafeConverters.toStringOrNull(json['address']),
      phone: SafeConverters.toSafeString(json['phone']),
      birthday: SafeConverters.toStringOrNull(json['birthday']),
      description: SafeConverters.toStringOrNull(json['description']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      lastUpdate: SafeConverters.toIntOrNull(json['last_update']),
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
    final goodMap = goodRaw is Map ? SafeConverters.toMap(goodRaw) : null;
    final variantMap = variantRaw is Map ? SafeConverters.toMap(variantRaw) : null;
    final goodItem = goodMap != null
        ? GoodItem.fromJson(goodMap)
        : GoodItem(
            id: SafeConverters.toInt(json['good_id'] != null
                ? json['good_id']
                : json['variant_id']),
            name: SafeConverters.toSafeString(json['good_name']),
            description: '',
            quantity: SafeConverters.toInt(json['quantity']),
            files: const [],
          );
    final variantGoodMap = variantMap != null &&
            SafeConverters.toMapOrNull(variantMap['good']) != null
        ? SafeConverters.toMap(variantMap['good'])
        : null;
    final variantGoodItem = variantGoodMap != null
        ? GoodItem.fromJson(variantGoodMap)
        : null;
    final cachedGoodName = SafeConverters.toStringOrNull(json['good_name']);
    final variantGoodRaw = variantMap?['good'];
    final availabilityStatus = parseStatus(json['availability_status']) ??
        parseStatus(json['status_name']) ??
        parseStatus(json['status']) ??
        (goodMap != null
            ? parseStatus(goodMap['availability_status']) ??
                parseStatus(goodMap['status_name']) ??
                parseStatus(goodMap['status'])
            : null) ??
        (variantMap != null
            ? parseStatus(variantMap['availability_status']) ??
                parseStatus(variantMap['status_name']) ??
                parseStatus(variantMap['status'])
            : null) ??
        (variantGoodRaw is Map
            ? parseStatus(SafeConverters.toMap(variantGoodRaw)['availability_status']) ??
                parseStatus(SafeConverters.toMap(variantGoodRaw)['status_name']) ??
                parseStatus(SafeConverters.toMap(variantGoodRaw)['status'])
            : null);

    final variantPriceMap = variantMap != null
        ? SafeConverters.toMapOrNull(variantMap['price'])
        : null;
    final goodPriceMap = goodMap != null
        ? SafeConverters.toMapOrNull(goodMap['good_price'])
        : null;

    return Good(
      good: goodItem,
      variantGood: variantGoodItem,
      goodId: SafeConverters.toInt(json['variant_id'] != null
          ? json['variant_id']
          : json['good_id'] != null
              ? json['good_id']
              : goodItem.id),
      goodName: cachedGoodName ??
          (goodItem.name.isNotEmpty
              ? goodItem.name
              : (variantGoodItem?.name ?? '')),
      quantity: SafeConverters.toInt(json['quantity']),
      availabilityStatus: availabilityStatus,
      price: SafeConverters.toDouble(
        json['price'] ?? variantPriceMap?['price'] ?? goodPriceMap?['price'],
      ),
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      description: SafeConverters.toSafeString(json['description']),
      quantity: SafeConverters.toInt(json['quantity']),
      files: SafeConverters.toList(json['files'])
          .map((f) => GoodFile.fromJson(SafeConverters.toMap(f)))
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      path: SafeConverters.toSafeString(json['path']),
    );
  }
}

class OrderResponse {
  final List<Order> data;
  final Pagination pagination;

  OrderResponse({required this.data, required this.pagination});

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    final rawOrders = SafeConverters.toList(json['data'] ?? json['result']);
    final rawPagination = json['pagination'] ??
        {
          'total': rawOrders.length,
          'count': rawOrders.length,
          'per_page': rawOrders.isEmpty ? 20 : rawOrders.length,
          'current_page': 1,
          'total_pages': 1,
        };

    return OrderResponse(
      data: rawOrders
          .map((o) => Order.fromJson(SafeConverters.toMap(o)))
          .toList(),
      pagination: Pagination.fromJson(SafeConverters.toMap(rawPagination)),
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
      total: SafeConverters.toInt(json['total']),
      count: SafeConverters.toInt(json['count']),
      perPage: SafeConverters.toInt(json['per_page'], defaultValue: 20),
      currentPage: SafeConverters.toInt(json['current_page'], defaultValue: 1),
      totalPages: SafeConverters.toInt(json['total_pages'], defaultValue: 1),
    );
  }
}

class OrderStatusName {
  final int id;
  final String name;

  OrderStatusName({required this.id, required this.name});

  factory OrderStatusName.fromJson(Map<String, dynamic> json) {
    return OrderStatusName(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
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

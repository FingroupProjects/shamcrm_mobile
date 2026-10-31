import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:flutter/material.dart';
export 'chess_zoom_level.dart';

extension ChessGridIterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum ApartmentStatus { available, booked, sold, reserved }

enum DealType { cash, installment, mixed }

enum OrderStatus { inProgress, success, rejected }

// ─────────────────────────────────────────────────────────────────────────────
// Status helpers
// ─────────────────────────────────────────────────────────────────────────────

extension ApartmentStatusX on ApartmentStatus {
  Color get color {
    switch (this) {
      case ApartmentStatus.available:
        return const Color(0xFF2E9E63);
      case ApartmentStatus.booked:
        return const Color(0xFFE2A81C);
      case ApartmentStatus.sold:
        return const Color(0xFFD0463C);
      case ApartmentStatus.reserved:
        return const Color(0xFF2563EB);
    }
  }

  Color get bgColor {
    switch (this) {
      case ApartmentStatus.available:
        return const Color(0xFF2E9E63).withValues(alpha: 0.12);
      case ApartmentStatus.booked:
        return const Color(0xFFE2A81C).withValues(alpha: 0.12);
      case ApartmentStatus.sold:
        return const Color(0xFFD0463C).withValues(alpha: 0.12);
      case ApartmentStatus.reserved:
        return const Color(0xFF2563EB).withValues(alpha: 0.12);
    }
  }

  String get labelRu {
    switch (this) {
      case ApartmentStatus.available:
        return 'Свободно';
      case ApartmentStatus.booked:
        return 'Бронь';
      case ApartmentStatus.sold:
        return 'Продано';
      case ApartmentStatus.reserved:
        return 'Резерв';
    }
  }

  IconData get icon {
    switch (this) {
      case ApartmentStatus.available:
        return Icons.check_circle_outline_rounded;
      case ApartmentStatus.booked:
        return Icons.schedule_rounded;
      case ApartmentStatus.sold:
        return Icons.lock_outline_rounded;
      case ApartmentStatus.reserved:
        return Icons.bookmark_border_rounded;
    }
  }
}

extension DealTypeX on DealType {
  String get labelRu {
    switch (this) {
      case DealType.cash:
        return 'Наличными';
      case DealType.installment:
        return 'Рассрочка';
      case DealType.mixed:
        return 'Смешанная оплата';
    }
  }
}

extension OrderStatusX on OrderStatus {
  String get labelRu {
    switch (this) {
      case OrderStatus.inProgress:
        return 'В работе';
      case OrderStatus.success:
        return 'Успешно';
      case OrderStatus.rejected:
        return 'Неуспешно';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.inProgress:
        return const Color(0xFFE2A81C);
      case OrderStatus.success:
        return const Color(0xFF2E9E63);
      case OrderStatus.rejected:
        return const Color(0xFFD0463C);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class SalesOfficeInfo {
  final String address;
  final String email;
  final String phone;
  final String workingHours;

  const SalesOfficeInfo({
    required this.address,
    required this.email,
    required this.phone,
    required this.workingHours,
  });

  SalesOfficeInfo copyWith({
    String? address,
    String? email,
    String? phone,
    String? workingHours,
  }) {
    return SalesOfficeInfo(
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      workingHours: workingHours ?? this.workingHours,
    );
  }
}

class InstallmentScheduleRow {
  final int number;
  final DateTime date;
  final double paymentAmount;
  final double remainingDebt;

  const InstallmentScheduleRow({
    required this.number,
    required this.date,
    required this.paymentAmount,
    required this.remainingDebt,
  });
}

class PaymentDetails {
  final double downPayment;
  final int months;
  final double installmentSum;
  final double monthlyPayment;
  final String? barterSubject;
  final double barterAmount;
  final List<InstallmentScheduleRow> schedule;

  const PaymentDetails({
    required this.downPayment,
    required this.months,
    required this.installmentSum,
    required this.monthlyPayment,
    this.barterSubject,
    this.barterAmount = 0,
    required this.schedule,
  });

  static List<InstallmentScheduleRow> generateSchedule({
    required double totalInstallmentSum,
    required int months,
    DateTime? startDate,
  }) {
    if (months <= 0 || totalInstallmentSum <= 0) return [];
    final baseMonthly = (totalInstallmentSum / months).floorToDouble();
    double remaining = totalInstallmentSum;
    final start = startDate ?? DateTime.now();
    final rows = <InstallmentScheduleRow>[];

    for (int i = 1; i <= months; i++) {
      final isLast = i == months;
      final payment = isLast ? remaining : baseMonthly;
      remaining = (remaining - payment).clamp(0, double.infinity);
      final cleanPayment = (payment * 100).roundToDouble() / 100;
      final cleanRemaining = (remaining * 100).roundToDouble() / 100;

      final payDate = DateTime(start.year, start.month + i, 1);
      rows.add(InstallmentScheduleRow(
        number: i,
        date: payDate,
        paymentAmount: cleanPayment,
        remainingDebt: cleanRemaining,
      ));
    }
    return rows;
  }
}

class CustomField {
  final int id;
  final String scope; // 'flat' or 'order'
  final String name;
  final String type; // 'текст', 'число', 'дата', 'флажок'
  final bool isRequired;

  const CustomField({
    required this.id,
    required this.scope,
    required this.name,
    required this.type,
    this.isRequired = false,
  });
}

class Apartment {
  final int id;
  final int complexId;
  final String number;
  final ApartmentStatus status;
  final String type; // 'Студия', 'Евроремонт', 'Предчистовая', 'Черновая'
  final int rooms;
  final double totalArea;
  final double livingArea;
  final double kitchenArea;
  final double pricePerSqm;
  final double totalPrice;
  final String currency;
  final String? layoutImageUrl;
  final List<String> plans;
  final String? layoutType;
  final int balconiesCount;
  final int combinedBathroomsCount;
  final int floor;
  final int entrance;
  final int? entranceId;
  final int position;
  final String buildingKey;
  final String buildingName;
  final int bookingCountMonth;
  final Map<int, String> customFields;

  const Apartment({
    required this.id,
    this.complexId = 1,
    required this.number,
    required this.status,
    required this.type,
    required this.rooms,
    required this.totalArea,
    required this.livingArea,
    required this.kitchenArea,
    required this.pricePerSqm,
    required this.totalPrice,
    required this.currency,
    this.layoutImageUrl,
    this.plans = const [],
    this.layoutType,
    this.balconiesCount = 0,
    this.combinedBathroomsCount = 1,
    required this.floor,
    required this.entrance,
    this.entranceId,
    this.position = 0,
    required this.buildingKey,
    required this.buildingName,
    this.bookingCountMonth = 0,
    this.customFields = const {},
  });

  factory Apartment.fromJson(Map<String, dynamic> json) => Apartment.fromGood(json);

  factory Apartment.fromGood(
    Map<String, dynamic> json, {
    int complexId = 1,
    String buildingKey = '',
    String buildingName = '',
  }) {
    final Map<String, dynamic> data =
        json.containsKey('good') && json['good'] is Map ? SafeConverters.toMap(json['good']) : json;

    final id = SafeConverters.toInt(data['id'] ?? json['id']);
    final cId = SafeConverters.toIntOrNull(data['residential_complex_id'] ?? json['residential_complex_id'] ?? data['complex_id']) ?? complexId;

    // Attributes map helper (lowercase key -> value)
    final Map<String, String> attrs = {};
    final rawAttrs = SafeConverters.toList(data['attributes'] ?? json['attributes'] ?? data['attribute_values'] ?? json['attribute_values']);
    for (final item in rawAttrs) {
      if (item is Map) {
        String? attrName;
        if (item['attribute'] is Map && item['attribute']['name'] != null) {
          attrName = item['attribute']['name']?.toString();
        } else if (item['category_attribute'] is Map && item['category_attribute']['attribute'] is Map) {
          attrName = item['category_attribute']['attribute']['name']?.toString();
        } else if (item['name'] != null) {
          attrName = item['name']?.toString();
        }
        final val = item['value']?.toString() ?? item['val']?.toString();
        if (attrName != null && val != null) {
          attrs[attrName.trim().toLowerCase()] = val.trim();
        }
      }
    }

    String? findAttr(List<String> keys) {
      for (final k in keys) {
        final match = attrs.entries.firstWhereOrNull((e) => e.key.contains(k));
        if (match != null && match.value.isNotEmpty) return match.value;
      }
      return null;
    }

    // Number extraction
    String number = SafeConverters.toSafeString(data['number'] ?? json['number'] ?? data['apartment_number'] ?? json['apartment_number']);
    if (number.isEmpty) {
      final nameStr = SafeConverters.toSafeString(data['name'] ?? json['name']);
      final match = RegExp(r'(?:кв|квартира|№|\#)\s*([0-9A-Za-zА-Яа-я\-]+)', caseSensitive: false).firstMatch(nameStr);
      if (match != null) {
        number = match.group(1) ?? nameStr;
      } else {
        number = nameStr.isNotEmpty ? nameStr : '$id';
      }
    }

    // Floor
    final floorVal = SafeConverters.toIntOrNull(data['floor'] ?? json['floor'] ?? data['number_of_floors']) ??
        SafeConverters.toIntOrNull(findAttr(['этаж', 'floor'])) ?? 1;

    // Entrance
    final entranceIdVal = SafeConverters.toIntOrNull(data['entrance_id'] ?? json['entrance_id']);
    final entranceVal = SafeConverters.toIntOrNull(data['entrance'] ?? json['entrance'] ?? data['porch'] ?? data['entrance_number']) ??
        SafeConverters.toIntOrNull(findAttr(['подъезд', 'entrance', 'секция'])) ??
        (entranceIdVal ?? 1);

    // Rooms
    final roomsVal = SafeConverters.toIntOrNull(data['rooms'] ?? json['rooms'] ?? data['room_count'] ?? data['number_of_rooms']) ??
        SafeConverters.toIntOrNull(findAttr(['комнат', 'комнаты', 'rooms'])) ?? 1;

    // Position
    final posVal = SafeConverters.toIntOrNull(data['position'] ?? json['position'] ?? data['apartment_position']) ??
        SafeConverters.toIntOrNull(findAttr(['позиция', 'position'])) ?? 0;

    // Type
    String typeVal = SafeConverters.toSafeString(data['type'] ?? json['type'] ?? data['apartment_type'] ?? json['apartment_type']);
    if (typeVal.isEmpty) {
      typeVal = findAttr(['тип', 'тип квартиры', 'отделка']) ?? '';
    }
    if (typeVal.isEmpty) {
      typeVal = roomsVal == 1 ? 'Студия' : (roomsVal == 2 ? 'Евроремонт' : 'Черновая');
    }

    // Areas
    final totalAreaVal = SafeConverters.toDoubleOrNull(data['total_area'] ?? json['total_area'] ?? data['area'] ?? json['area'] ?? data['square']) ??
        SafeConverters.toDoubleOrNull(findAttr(['общая площадь', 'площадь', 'квадратура', 'area', 'м2', 'м²'])) ??
        (38.0 + (roomsVal * 16.0));

    final livingAreaVal = SafeConverters.toDoubleOrNull(data['living_area'] ?? json['living_area'] ?? data['living_square']) ??
        SafeConverters.toDoubleOrNull(findAttr(['жилая площадь', 'жилая'])) ??
        (totalAreaVal * 0.6).roundToDouble();

    final kitchenAreaVal = SafeConverters.toDoubleOrNull(data['kitchen_area'] ?? json['kitchen_area'] ?? data['kitchen_square']) ??
        SafeConverters.toDoubleOrNull(findAttr(['площадь кухни', 'кухня'])) ??
        10.0;

    // Prices
    final totalPriceVal = SafeConverters.toDoubleOrNull(data['price'] ?? json['price'] ?? data['total_price'] ?? json['total_price']) ??
        (totalAreaVal * 800.0);

    final pricePerSqmVal = SafeConverters.toDoubleOrNull(data['price_per_sqm'] ?? json['price_per_sqm'] ?? data['price_per_m2'] ?? json['price_m2']) ??
        SafeConverters.toDoubleOrNull(findAttr(['цена за м', 'цена за метр', 'за кв.м'])) ??
        (totalAreaVal > 0 ? (totalPriceVal / totalAreaVal).roundToDouble() : 800.0);

    // Status
    final statusStr = (data['status'] ?? json['status'] ?? data['apartment_status'] ?? json['apartment_status'] ?? data['availability_status'] ?? '').toString().toLowerCase().trim();
    ApartmentStatus status;
    if (statusStr.contains('book') || statusStr.contains('брон')) {
      status = ApartmentStatus.booked;
    } else if (statusStr.contains('sold') || statusStr.contains('продан') || statusStr.contains('куплен')) {
      status = ApartmentStatus.sold;
    } else if (statusStr.contains('reserv') || statusStr.contains('резерв')) {
      status = ApartmentStatus.reserved;
    } else {
      status = ApartmentStatus.available;
    }

    // Images
    String? layoutImg = SafeConverters.toStringOrNull(data['image'] ?? json['image'] ?? data['layout_image_url'] ?? json['layout_image_url'] ?? data['image_url']);
    final List<String> plansList = [];
    final filesRaw = SafeConverters.toList(data['files'] ?? json['files'] ?? data['images'] ?? json['images']);
    for (final f in filesRaw) {
      if (f is Map) {
        final path = f['file_path'] ?? f['url'] ?? f['path'] ?? f['full_url'];
        if (path != null && path.toString().isNotEmpty) {
          plansList.add(path.toString());
        }
      } else if (f is String && f.isNotEmpty) {
        plansList.add(f);
      }
    }
    if (layoutImg == null && plansList.isNotEmpty) {
      layoutImg = plansList.first;
    }

    final rawBKey = (data['building_id'] ?? json['building_id'] ?? data['building_key'] ?? json['building_key'])?.toString();
    final effectiveBKey = buildingKey.isNotEmpty ? buildingKey : (rawBKey ?? 'A');
    final effectiveBName = buildingName.isNotEmpty ? buildingName : (data['building_name'] ?? json['building_name'] ?? 'Корпус').toString();

    final layoutTypeVal = SafeConverters.toStringOrNull(
      data['layout_type'] ?? json['layout_type'] ?? findAttr(['тип планировки', 'планировка']),
    ) ?? (roomsVal == 1 ? 'A' : (roomsVal == 2 ? 'B' : (roomsVal == 3 ? 'C' : 'D')));

    final balconiesVal = SafeConverters.toIntOrNull(
      data['balconies_count'] ?? json['balconies_count'] ?? findAttr(['балкон', 'лоджия', 'балконов']),
    ) ?? (totalAreaVal > 50 ? 1 : 0);

    final bathroomsVal = SafeConverters.toIntOrNull(
      data['combined_bathrooms_count'] ?? data['bathrooms_count'] ?? json['bathrooms_count'] ?? findAttr(['санузел', 'санузлов', 'ванная']),
    ) ?? 1;

    return Apartment(
      id: id,
      complexId: cId,
      number: number,
      status: status,
      type: typeVal,
      rooms: roomsVal > 0 ? roomsVal : 1,
      totalArea: totalAreaVal > 0 ? totalAreaVal : 45.0,
      livingArea: livingAreaVal > 0 ? livingAreaVal : 26.0,
      kitchenArea: kitchenAreaVal > 0 ? kitchenAreaVal : 10.0,
      pricePerSqm: pricePerSqmVal > 0 ? pricePerSqmVal : 800.0,
      totalPrice: totalPriceVal > 0 ? totalPriceVal : 36000.0,
      currency: SafeConverters.toSafeString(data['currency'] ?? json['currency'], defaultValue: '\$'),
      layoutImageUrl: layoutImg,
      plans: plansList,
      layoutType: layoutTypeVal,
      balconiesCount: balconiesVal,
      combinedBathroomsCount: bathroomsVal,
      floor: floorVal > 0 ? floorVal : 1,
      entrance: entranceVal > 0 ? entranceVal : 1,
      entranceId: entranceIdVal,
      position: posVal >= 0 ? posVal : 0,
      buildingKey: effectiveBKey,
      buildingName: effectiveBName,
      bookingCountMonth: status == ApartmentStatus.booked ? 1 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residential_complex_id': complexId,
      'number': number,
      'status': status.name,
      'type': type,
      'rooms': rooms,
      'total_area': totalArea,
      'living_area': livingArea,
      'kitchen_area': kitchenArea,
      'price_per_sqm': pricePerSqm,
      'price': totalPrice,
      'currency': currency,
      'layout_image_url': layoutImageUrl,
      'plans': plans,
      'layout_type': layoutType,
      'balconies_count': balconiesCount,
      'combined_bathrooms_count': combinedBathroomsCount,
      'floor': floor,
      'entrance': entrance,
      if (entranceId != null) 'entrance_id': entranceId,
      'position': position,
      'building_key': buildingKey,
      'building_name': buildingName,
    };
  }

  Apartment copyWith({
    int? id,
    int? complexId,
    String? number,
    ApartmentStatus? status,
    String? type,
    int? rooms,
    double? totalArea,
    double? livingArea,
    double? kitchenArea,
    double? pricePerSqm,
    double? totalPrice,
    String? currency,
    String? layoutImageUrl,
    List<String>? plans,
    String? layoutType,
    int? balconiesCount,
    int? combinedBathroomsCount,
    int? floor,
    int? entrance,
    int? entranceId,
    int? position,
    String? buildingKey,
    String? buildingName,
    int? bookingCountMonth,
    Map<int, String>? customFields,
  }) {
    return Apartment(
      id: id ?? this.id,
      complexId: complexId ?? this.complexId,
      number: number ?? this.number,
      status: status ?? this.status,
      type: type ?? this.type,
      rooms: rooms ?? this.rooms,
      totalArea: totalArea ?? this.totalArea,
      livingArea: livingArea ?? this.livingArea,
      kitchenArea: kitchenArea ?? this.kitchenArea,
      pricePerSqm: pricePerSqm ?? this.pricePerSqm,
      totalPrice: totalPrice ?? this.totalPrice,
      currency: currency ?? this.currency,
      layoutImageUrl: layoutImageUrl ?? this.layoutImageUrl,
      plans: plans ?? this.plans,
      layoutType: layoutType ?? this.layoutType,
      balconiesCount: balconiesCount ?? this.balconiesCount,
      combinedBathroomsCount: combinedBathroomsCount ?? this.combinedBathroomsCount,
      floor: floor ?? this.floor,
      entrance: entrance ?? this.entrance,
      entranceId: entranceId ?? this.entranceId,
      position: position ?? this.position,
      buildingKey: buildingKey ?? this.buildingKey,
      buildingName: buildingName ?? this.buildingName,
      bookingCountMonth: bookingCountMonth ?? this.bookingCountMonth,
      customFields: customFields ?? this.customFields,
    );
  }
}

class Entrance {
  final int id;
  final int buildingId;
  final int number;
  final String name;

  const Entrance({
    required this.id,
    required this.buildingId,
    required this.number,
    required this.name,
  });

  factory Entrance.fromJson(Map<String, dynamic> json) {
    final id = SafeConverters.toInt(json['id']);
    final bId = SafeConverters.toInt(json['building_id'] ?? json['buildingId']);
    final rawNum = json['number'] ?? json['entrance_number'] ?? json['name'];
    int numVal = SafeConverters.toInt(rawNum);
    if (numVal == 0 && json['name'] != null) {
      final match = RegExp(r'\d+').firstMatch(json['name'].toString());
      if (match != null) numVal = int.tryParse(match.group(0)!) ?? 0;
    }
    final nameStr = SafeConverters.toSafeString(
      json['name'] ?? 'Подъезд ${numVal > 0 ? numVal : id}',
      defaultValue: 'Подъезд $id',
    );

    return Entrance(
      id: id,
      buildingId: bId,
      number: numVal > 0 ? numVal : id,
      name: nameStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'building_id': buildingId,
      'number': number,
      'name': name,
    };
  }
}

class ParkingSpot {
  final int id;
  final int complexId;
  final String number;
  final String type; // 'Подземная', 'Открытая', 'Закрытая'
  final String buildingKey;
  final double price;
  final double area;
  final ApartmentStatus status;
  final int? linkedApartmentId;
  final String currency;

  const ParkingSpot({
    required this.id,
    this.complexId = 1,
    required this.number,
    required this.type,
    required this.buildingKey,
    required this.price,
    required this.area,
    required this.status,
    this.linkedApartmentId,
    this.currency = '\$',
  });

  ParkingSpot copyWith({
    int? id,
    int? complexId,
    String? number,
    String? type,
    String? buildingKey,
    double? price,
    double? area,
    ApartmentStatus? status,
    int? linkedApartmentId,
    String? currency,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      complexId: complexId ?? this.complexId,
      number: number ?? this.number,
      type: type ?? this.type,
      buildingKey: buildingKey ?? this.buildingKey,
      price: price ?? this.price,
      area: area ?? this.area,
      status: status ?? this.status,
      linkedApartmentId: linkedApartmentId ?? this.linkedApartmentId,
      currency: currency ?? this.currency,
    );
  }
}

class Building {
  final int? id;
  final String key;
  final String name;
  final int? residentialComplexId;
  final int entranceCount;
  final int floorCount;
  final int apartsPerFloor;
  final List<String> apartmentTypes;
  final dynamic floors;
  final String? imageUrl;
  final String? buildingShape;

  const Building({
    this.id,
    required this.key,
    required this.name,
    this.residentialComplexId,
    required this.entranceCount,
    required this.floorCount,
    required this.apartsPerFloor,
    required this.apartmentTypes,
    this.floors,
    this.imageUrl,
    this.buildingShape,
  });

  String get effectiveImage {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    if (buildingShape == 'curvedTower' || (floorCount >= 16 && entranceCount <= 2)) {
      return 'assets/images/building_tower.jpg';
    }
    return 'assets/images/building_cascade.jpg';
  }

  factory Building.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    final name = json['name']?.toString() ?? 'Корпус';
    final rawRcId = json['residential_complex_id'] ?? json['residentialComplexId'];
    final rcId = rawRcId is int ? rawRcId : int.tryParse(rawRcId?.toString() ?? '');

    int parseInt(dynamic val, int fallback) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    final entrances = parseInt(json['number_of_entrances'] ?? json['entranceCount'], 1);
    final floors = parseInt(json['number_of_floors'] ?? json['floorCount'], 1);
    final aparts = parseInt(json['number_of_apartments_per_floor'] ?? json['apartsPerFloor'], 4);

    List<String> types = [];
    if (json['apartment_types'] is List) {
      types = (json['apartment_types'] as List).map((e) => e.toString()).toList();
    } else if (json['apartmentTypes'] is List) {
      types = (json['apartmentTypes'] as List).map((e) => e.toString()).toList();
    }
    if (types.isEmpty) {
      types = ['Студия', 'Евроремонт', 'Черновая'];
    }

    final key = json['key']?.toString() ?? (id != null ? id.toString() : name);
    final img = json['image_url'] ?? json['photo'] ?? json['image'];
    final shape = json['building_shape'] ?? json['shape'];

    return Building(
      id: id,
      key: key,
      name: name,
      residentialComplexId: rcId,
      entranceCount: entrances > 0 ? entrances : 1,
      floorCount: floors > 0 ? floors : 1,
      apartsPerFloor: aparts > 0 ? aparts : 4,
      apartmentTypes: types,
      floors: json['floors'],
      imageUrl: img?.toString(),
      buildingShape: shape?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (residentialComplexId != null) 'residential_complex_id': residentialComplexId,
      'number_of_entrances': entranceCount,
      'number_of_floors': floorCount,
      'number_of_apartments_per_floor': apartsPerFloor,
      'type_of_floors': apartmentTypes,
      'apartment_types': apartmentTypes,
      if (imageUrl != null) 'image_url': imageUrl,
      if (buildingShape != null) 'building_shape': buildingShape,
    };
  }

  Building copyWith({
    int? id,
    String? key,
    String? name,
    int? residentialComplexId,
    int? entranceCount,
    int? floorCount,
    int? apartsPerFloor,
    List<String>? apartmentTypes,
    dynamic floors,
    String? imageUrl,
    String? buildingShape,
  }) {
    return Building(
      id: id ?? this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      residentialComplexId: residentialComplexId ?? this.residentialComplexId,
      entranceCount: entranceCount ?? this.entranceCount,
      floorCount: floorCount ?? this.floorCount,
      apartsPerFloor: apartsPerFloor ?? this.apartsPerFloor,
      apartmentTypes: apartmentTypes ?? this.apartmentTypes,
      floors: floors ?? this.floors,
      imageUrl: imageUrl ?? this.imageUrl,
      buildingShape: buildingShape ?? this.buildingShape,
    );
  }
}

class ResidentialComplex {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final List<String> photos;
  final int buildingCount;
  final List<Building> buildings;
  final SalesOfficeInfo salesOffice;
  final String? startTime;
  final String? endTime;

  const ResidentialComplex({
    required this.id,
    required this.name,
    required this.address,
    this.lat = 41.311081,
    this.lng = 69.240562,
    this.photos = const [],
    required this.buildingCount,
    required this.buildings,
    required this.salesOffice,
    this.startTime = '09:00',
    this.endTime = '18:00',
  });

  factory ResidentialComplex.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final name = json['name']?.toString() ?? '';
    final address = json['address']?.toString() ?? '';

    double parseCoord(dynamic val, double fallback) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    final lat = parseCoord(json['latitude'] ?? json['lat'], 41.311081);
    final lng = parseCoord(json['longitude'] ?? json['lng'], 69.240562);

    int parseBuildingsCount(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 1;
      return 1;
    }

    final bCount = parseBuildingsCount(
      json['number_of_buildings'] ?? json['buildings_count'] ?? json['buildingCount'],
    );

    final salesAddr = json['sales_department_address']?.toString() ??
        (json['salesOffice'] is Map ? json['salesOffice']['address']?.toString() : null) ??
        '';
    final salesMail = json['sales_department_mail']?.toString() ??
        (json['salesOffice'] is Map ? json['salesOffice']['email']?.toString() : null) ??
        '';
    final salesPhone = json['sales_department_phone']?.toString() ??
        (json['salesOffice'] is Map ? json['salesOffice']['phone']?.toString() : null) ??
        '';
    final startTime = json['start_time']?.toString() ?? '09:00';
    final endTime = json['end_time']?.toString() ?? '18:00';
    final workingHours = '$startTime – $endTime';

    List<Building> parsedBuildings = [];
    if (json['buildings'] is List) {
      parsedBuildings = (json['buildings'] as List)
          .whereType<Map<String, dynamic>>()
          .map((b) => Building.fromJson(b))
          .toList();
    }

    List<String> parsedPhotos = [];
    if (json['photos'] is List) {
      parsedPhotos = (json['photos'] as List).map((p) => p.toString()).toList();
    }

    return ResidentialComplex(
      id: id,
      name: name,
      address: address,
      lat: lat,
      lng: lng,
      photos: parsedPhotos,
      buildingCount: bCount,
      buildings: parsedBuildings,
      salesOffice: SalesOfficeInfo(
        address: salesAddr,
        email: salesMail,
        phone: salesPhone,
        workingHours: workingHours,
      ),
      startTime: startTime,
      endTime: endTime,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'address': address,
      'latitude': lat.toString(),
      'longitude': lng.toString(),
      'number_of_buildings': buildingCount,
      'sales_department_address': salesOffice.address,
      'sales_department_mail': salesOffice.email,
      'sales_department_phone': salesOffice.phone,
      'start_time': startTime ?? '09:00',
      'end_time': endTime ?? '18:00',
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'number_of_buildings': buildingCount,
    };
  }

  ResidentialComplex copyWith({
    int? id,
    String? name,
    String? address,
    double? lat,
    double? lng,
    List<String>? photos,
    int? buildingCount,
    List<Building>? buildings,
    SalesOfficeInfo? salesOffice,
    String? startTime,
    String? endTime,
  }) {
    return ResidentialComplex(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      photos: photos ?? this.photos,
      buildingCount: buildingCount ?? this.buildingCount,
      buildings: buildings ?? this.buildings,
      salesOffice: salesOffice ?? this.salesOffice,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

class Order {
  final String id; // 'З-1041'
  final int complexId;
  final int? apartmentId;
  final int? parkingId;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String? comment;
  final String manager;
  final DealType dealType;
  final double price;
  final OrderStatus status;
  final DateTime? reservedUntil;
  final PaymentDetails? paymentDetails;
  final Map<int, String> customFields;
  final String? sourceId;

  const Order({
    required this.id,
    this.complexId = 1,
    this.apartmentId,
    this.parkingId,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    this.comment,
    required this.manager,
    required this.dealType,
    required this.price,
    required this.status,
    this.reservedUntil,
    this.paymentDetails,
    this.customFields = const {},
    this.sourceId,
  });

  Order copyWith({
    String? id,
    int? complexId,
    int? apartmentId,
    int? parkingId,
    String? buyerName,
    String? buyerPhone,
    String? buyerEmail,
    String? comment,
    String? manager,
    DealType? dealType,
    double? price,
    OrderStatus? status,
    DateTime? reservedUntil,
    PaymentDetails? paymentDetails,
    Map<int, String>? customFields,
    String? sourceId,
  }) {
    return Order(
      id: id ?? this.id,
      complexId: complexId ?? this.complexId,
      apartmentId: apartmentId ?? this.apartmentId,
      parkingId: parkingId ?? this.parkingId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      comment: comment ?? this.comment,
      manager: manager ?? this.manager,
      dealType: dealType ?? this.dealType,
      price: price ?? this.price,
      status: status ?? this.status,
      reservedUntil: reservedUntil ?? this.reservedUntil,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      customFields: customFields ?? this.customFields,
      sourceId: sourceId ?? this.sourceId,
    );
  }
}

class RoleBookingSetting {
  final int? roleId;
  final String roleName;
  final int durationDays;

  const RoleBookingSetting({
    this.roleId,
    required this.roleName,
    required this.durationDays,
  });
}

class CompanyRequisites {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String inn;

  const CompanyRequisites({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.inn,
  });

  CompanyRequisites copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? inn,
  }) {
    return CompanyRequisites(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      inn: inn ?? this.inn,
    );
  }
}

class ChessGridFilter {
  final String buildingKey;
  final int entrance; // 0 = all
  final Set<int> rooms; // empty = all
  final double? minPrice;
  final double? maxPrice;
  final double? minArea;
  final double? maxArea;
  final Set<ApartmentStatus> statuses;

  const ChessGridFilter({
    this.buildingKey = 'A',
    this.entrance = 0,
    this.rooms = const {},
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.statuses = const {},
  });

  bool matches(Apartment apt) {
    if (entrance != 0 && apt.entrance != entrance) return false;
    if (rooms.isNotEmpty && !rooms.contains(apt.rooms)) return false;
    if (minPrice != null && apt.totalPrice < minPrice!) return false;
    if (maxPrice != null && apt.totalPrice > maxPrice!) return false;
    if (minArea != null && apt.totalArea < minArea!) return false;
    if (maxArea != null && apt.totalArea > maxArea!) return false;
    if (statuses.isNotEmpty && !statuses.contains(apt.status)) return false;
    return true;
  }

  bool get isDefault =>
      entrance == 0 &&
      rooms.isEmpty &&
      minPrice == null &&
      maxPrice == null &&
      minArea == null &&
      maxArea == null &&
      statuses.isEmpty;

  ChessGridFilter copyWith({
    String? buildingKey,
    int? entrance,
    Set<int>? rooms,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    Set<ApartmentStatus>? statuses,
  }) {
    return ChessGridFilter(
      buildingKey: buildingKey ?? this.buildingKey,
      entrance: entrance ?? this.entrance,
      rooms: rooms ?? this.rooms,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
      statuses: statuses ?? this.statuses,
    );
  }
}

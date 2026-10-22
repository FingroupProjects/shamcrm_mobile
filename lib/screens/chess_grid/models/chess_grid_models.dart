import 'package:flutter/material.dart';

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
        return const Color(0xFF3A7BD5);
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
        return const Color(0xFF3A7BD5).withValues(alpha: 0.12);
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
  final int floor;
  final int entrance;
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
    required this.floor,
    required this.entrance,
    this.position = 0,
    required this.buildingKey,
    required this.buildingName,
    this.bookingCountMonth = 0,
    this.customFields = const {},
  });

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
    int? floor,
    int? entrance,
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
      floor: floor ?? this.floor,
      entrance: entrance ?? this.entrance,
      position: position ?? this.position,
      buildingKey: buildingKey ?? this.buildingKey,
      buildingName: buildingName ?? this.buildingName,
      bookingCountMonth: bookingCountMonth ?? this.bookingCountMonth,
      customFields: customFields ?? this.customFields,
    );
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
  final String key;
  final String name;
  final int entranceCount;
  final int floorCount;
  final int apartsPerFloor;
  final List<String> apartmentTypes;
  final dynamic floors;

  const Building({
    required this.key,
    required this.name,
    required this.entranceCount,
    required this.floorCount,
    required this.apartsPerFloor,
    required this.apartmentTypes,
    this.floors,
  });

  Building copyWith({
    String? key,
    String? name,
    int? entranceCount,
    int? floorCount,
    int? apartsPerFloor,
    List<String>? apartmentTypes,
    dynamic floors,
  }) {
    return Building(
      key: key ?? this.key,
      name: name ?? this.name,
      entranceCount: entranceCount ?? this.entranceCount,
      floorCount: floorCount ?? this.floorCount,
      apartsPerFloor: apartsPerFloor ?? this.apartsPerFloor,
      apartmentTypes: apartmentTypes ?? this.apartmentTypes,
      floors: floors ?? this.floors,
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

  const ResidentialComplex({
    required this.id,
    required this.name,
    required this.address,
    this.lat = 40.2826,
    this.lng = 69.6221,
    this.photos = const [],
    required this.buildingCount,
    required this.buildings,
    required this.salesOffice,
  });

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
    );
  }
}

class RoleBookingSetting {
  final String roleName;
  final int durationDays;

  const RoleBookingSetting({
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

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';

class ChessGridController extends ChangeNotifier {
  static ChessGridController? _instance;
  static ChessGridController get instance => _instance ??= ChessGridController._();

  ChessGridController._() {
    _initData();
    _startExpirationTimer();
  }

  late List<ResidentialComplex> complexes;
  late List<Apartment> apartments;
  late List<ParkingSpot> parkingSpots;
  late List<Order> orders;
  late List<RoleBookingSetting> roleSettings;
  late CompanyRequisites requisites;
  int monthlyBookingLimit = 3;
  List<CustomField> customFields = [];

  int _selectedComplexId = 1;
  String _selectedBuildingKey = 'A';
  ChessGridFilter _filter = const ChessGridFilter();
  Apartment? _selectedApartment;

  Timer? _expireTimer;
  int _orderIdCounter = 1045;
  int _complexIdCounter = 3;

  int get selectedComplexId => _selectedComplexId;
  String get selectedBuildingKey => _selectedBuildingKey;
  ChessGridFilter get filter => _filter;
  Apartment? get selectedApartment => _selectedApartment;

  ResidentialComplex get complex {
    return findComplexById(_selectedComplexId) ??
        (complexes.isNotEmpty
            ? complexes.first
            : const ResidentialComplex(
                id: 1,
                name: 'ЖК',
                address: '',
                buildingCount: 1,
                buildings: [
                  Building(
                    key: 'A',
                    name: 'Блок А',
                    entranceCount: 1,
                    floorCount: 1,
                    apartsPerFloor: 1,
                    apartmentTypes: ['Студия'],
                  ),
                ],
                salesOffice: SalesOfficeInfo(
                  address: '',
                  email: '',
                  phone: '',
                  workingHours: '',
                ),
              ));
  }

  Building? get currentBuilding {
    final c = complex;
    try {
      return c.buildings.firstWhere((b) => b.key == _selectedBuildingKey);
    } catch (_) {
      return c.buildings.isNotEmpty ? c.buildings.first : null;
    }
  }

  void selectComplex(int id) {
    if (_selectedComplexId == id) return;
    _selectedComplexId = id;
    final c = findComplexById(id);
    if (c != null && c.buildings.isNotEmpty) {
      _selectedBuildingKey = c.buildings.first.key;
    } else {
      _selectedBuildingKey = 'A';
    }
    _filter = ChessGridFilter(buildingKey: _selectedBuildingKey);
    _selectedApartment = null;
    notifyListeners();
  }

  void selectBuilding(String key) {
    _selectedBuildingKey = key;
    _filter = _filter.copyWith(buildingKey: key);
    notifyListeners();
  }

  void selectApartment(Apartment? apt) {
    _selectedApartment = apt;
    notifyListeners();
  }

  void setFilter(ChessGridFilter f) {
    _filter = f;
    notifyListeners();
  }

  void toggleStatusFilter(ApartmentStatus status) {
    final set = Set<ApartmentStatus>.from(_filter.statuses);
    if (set.contains(status)) {
      set.remove(status);
    } else {
      set.add(status);
    }
    _filter = _filter.copyWith(statuses: set);
    notifyListeners();
  }

  void setEntranceFilter(int entrance) {
    _filter = _filter.copyWith(entrance: entrance);
    notifyListeners();
  }

  void resetFilter() {
    _filter = ChessGridFilter(buildingKey: _selectedBuildingKey);
    notifyListeners();
  }

  Apartment? findApartmentById(int? id) {
    if (id == null) return null;
    try {
      return apartments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  ParkingSpot? findParkingById(int? id) {
    if (id == null) return null;
    try {
      return parkingSpots.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Apartment> get filteredApartments {
    return apartments.where((a) {
      if (a.complexId != _selectedComplexId) return false;
      if (a.buildingKey != _selectedBuildingKey) return false;
      if (_filter.entrance != 0 && a.entrance != _filter.entrance) return false;
      if (_filter.rooms.isNotEmpty && !_filter.rooms.contains(a.rooms)) return false;
      if (_filter.minPrice != null && a.totalPrice < _filter.minPrice!) return false;
      if (_filter.maxPrice != null && a.totalPrice > _filter.maxPrice!) return false;
      if (_filter.minArea != null && a.totalArea < _filter.minArea!) return false;
      if (_filter.maxArea != null && a.totalArea > _filter.maxArea!) return false;
      if (_filter.statuses.isNotEmpty && !_filter.statuses.contains(a.status)) return false;
      return true;
    }).toList();
  }

  void updateComplex(ResidentialComplex updated) {
    final idx = complexes.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      complexes[idx] = updated;
      notifyListeners();
    }
  }

  void addBuilding(Building b) {
    final c = complex;
    final updatedBuildings = List<Building>.from(c.buildings)..add(b);
    updateComplex(c.copyWith(
      buildings: updatedBuildings,
      buildingCount: updatedBuildings.length,
    ));
  }

  void updateBuilding(Building b) {
    final c = complex;
    final idx = c.buildings.indexWhere((item) => item.key == b.key);
    if (idx != -1) {
      final updatedBuildings = List<Building>.from(c.buildings);
      updatedBuildings[idx] = b;
      updateComplex(c.copyWith(buildings: updatedBuildings));
    }
  }

  bool deleteBuilding(String key) {
    final c = complex;
    if (c.buildings.length <= 1) return false;
    final updatedBuildings = c.buildings.where((b) => b.key != key).toList();
    updateComplex(c.copyWith(
      buildings: updatedBuildings,
      buildingCount: updatedBuildings.length,
    ));
    if (_selectedBuildingKey == key) {
      _selectedBuildingKey = updatedBuildings.first.key;
    }
    return true;
  }

  void addApartment(Apartment apt, {List<int>? copyToFloors}) {
    apartments.add(apt);
    if (copyToFloors != null && copyToFloors.isNotEmpty) {
      int maxId = apartments.isNotEmpty ? apartments.map((a) => a.id).fold(0, max) : 0;
      for (final f in copyToFloors) {
        if (f == apt.floor) continue;
        apartments.add(apt.copyWith(
          id: ++maxId,
          floor: f,
          number: '${apt.number}-$f',
        ));
      }
    }
    notifyListeners();
  }

  void updateApartment(Apartment apt) {
    final idx = apartments.indexWhere((a) => a.id == apt.id);
    if (idx != -1) {
      apartments[idx] = apt;
      notifyListeners();
    }
  }

  bool deleteApartment(int id) {
    final before = apartments.length;
    apartments.removeWhere((a) => a.id == id);
    if (apartments.length != before) {
      notifyListeners();
      return true;
    }
    return false;
  }

  void addParkingSpot(ParkingSpot spot) {
    parkingSpots.add(spot);
    notifyListeners();
  }

  void updateParkingSpot(ParkingSpot spot) {
    final idx = parkingSpots.indexWhere((p) => p.id == spot.id);
    if (idx != -1) {
      parkingSpots[idx] = spot;
      notifyListeners();
    }
  }

  bool deleteParkingSpot(int id) {
    final before = parkingSpots.length;
    parkingSpots.removeWhere((p) => p.id == id);
    if (parkingSpots.length != before) {
      notifyListeners();
      return true;
    }
    return false;
  }

  void addCustomField(CustomField field) {
    customFields.add(field);
    notifyListeners();
  }

  void deleteCustomField(int id) {
    customFields.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  void updateRoleDuration(int index, int days) {
    if (index >= 0 && index < roleSettings.length) {
      roleSettings[index] = RoleBookingSetting(
        roleName: roleSettings[index].roleName,
        durationDays: days,
      );
      notifyListeners();
    }
  }

  void updateMonthlyLimit(int limit) {
    monthlyBookingLimit = limit;
    notifyListeners();
  }

  void updateCompanyRequisites(CompanyRequisites req) {
    requisites = req;
    notifyListeners();
  }

  void _initData() {
    customFields = [
      const CustomField(id: 1, scope: 'flat', name: 'Вид из окна', type: 'текст'),
      const CustomField(id: 2, scope: 'flat', name: 'Высота потолков', type: 'число'),
      const CustomField(id: 3, scope: 'order', name: 'Источник лида', type: 'текст'),
    ];

    roleSettings = [
      const RoleBookingSetting(roleName: 'Менеджер', durationDays: 3),
      const RoleBookingSetting(roleName: 'Руководитель', durationDays: 7),
      const RoleBookingSetting(roleName: 'Агент', durationDays: 1),
    ];

    requisites = const CompanyRequisites(
      name: 'ООО «Панорама Строй»',
      address: 'г. Худжанд, ул. Рудаки, 112',
      phone: '+992 92 000 00 00',
      email: 'sales@panorama.tj',
      inn: 'ИНН 030024819',
    );

    // 1. Complex 1: Панорама Согд
    final bA1 = Building(
      key: 'A',
      name: 'Блок А',
      entranceCount: 3,
      floorCount: 9,
      apartsPerFloor: 4,
      apartmentTypes: ['Студия', 'Евроремонт', 'Предчистовая', 'Черновая'],
    );
    final bB1 = Building(
      key: 'B',
      name: 'Блок Б',
      entranceCount: 2,
      floorCount: 7,
      apartsPerFloor: 4,
      apartmentTypes: ['Студия', 'Евроремонт', 'Черновая'],
    );

    final complex1 = ResidentialComplex(
      id: 1,
      name: 'ЖК «Панорама Согд»',
      address: 'Худжанд, ул. Рудаки, 112',
      lat: 40.2826,
      lng: 69.6221,
      photos: [
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600&auto=format&fit=crop&q=80',
      ],
      buildingCount: 2,
      buildings: [bA1, bB1],
      salesOffice: const SalesOfficeInfo(
        address: 'Худжанд, ул. Рудаки, 112, офис 1',
        email: 'sales@panorama.tj',
        phone: '+992 92 000 00 00',
        workingHours: 'Пн–Сб, 9:00–18:00',
      ),
    );

    // 2. Complex 2: Бухара Сити
    final bA2 = Building(
      key: 'A',
      name: 'Корпус 1',
      entranceCount: 2,
      floorCount: 12,
      apartsPerFloor: 4,
      apartmentTypes: ['Евроремонт', 'Студия', 'Премиум'],
    );
    final bB2 = Building(
      key: 'B',
      name: 'Корпус 2',
      entranceCount: 2,
      floorCount: 10,
      apartsPerFloor: 4,
      apartmentTypes: ['Евроремонт', 'Черновая'],
    );

    final complex2 = ResidentialComplex(
      id: 2,
      name: 'ЖК «Бухара Сити»',
      address: 'Бухара, ул. Навои, 45',
      lat: 39.7747,
      lng: 64.4286,
      photos: [
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600&auto=format&fit=crop&q=80',
      ],
      buildingCount: 2,
      buildings: [bA2, bB2],
      salesOffice: const SalesOfficeInfo(
        address: 'Бухара, ул. Навои, 45, офис 101',
        email: 'sales@bukhara-city.uz',
        phone: '+998 71 200 00 01',
        workingHours: '09:00 – 18:00',
      ),
    );

    // 3. Complex 3: Самарканд Парк
    final bA3 = Building(
      key: 'A',
      name: 'Блок Восток',
      entranceCount: 2,
      floorCount: 8,
      apartsPerFloor: 3,
      apartmentTypes: ['Студия', 'Евроремонт'],
    );

    final complex3 = ResidentialComplex(
      id: 3,
      name: 'ЖК «Самарканд Парк»',
      address: 'Самарканд, пр. Амира Темура, 112',
      lat: 39.6542,
      lng: 66.9597,
      photos: [
        'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=600&auto=format&fit=crop&q=80',
      ],
      buildingCount: 1,
      buildings: [bA3],
      salesOffice: const SalesOfficeInfo(
        address: 'Самарканд, пр. Амира Темура, 112А',
        email: 'info@samarkand-park.uz',
        phone: '+998 71 300 00 02',
        workingHours: '09:00 – 19:00',
      ),
    );

    complexes = [complex1, complex2, complex3];
    apartments = [];
    orders = [];
    parkingSpots = [];

    // Pre-populate apartments for each complex
    final rng = Random(42);
    final standardTemplates = [
      [1, 38.0, 'Студия'],
      [2, 58.5, 'Евроремонт'],
      [2, 65.0, 'Предчистовая'],
      [3, 86.0, 'Черновая'],
    ];

    int aptIdCounter = 1;
    for (final c in complexes) {
      for (final b in c.buildings) {
        final basePrice = b.key == 'A' ? 780.0 : 740.0;
        for (int e = 1; e <= b.entranceCount; e++) {
          for (int f = 1; f <= b.floorCount; f++) {
            for (int p = 0; p < b.apartsPerFloor; p++) {
              final t = standardTemplates[p % standardTemplates.length];
              final rooms = t[0] as int;
              final baseArea = t[1] as double;
              final type = t[2] as String;
              final area = double.parse((baseArea + (e - 1) * 0.8).toStringAsFixed(1));
              final pm = basePrice + f * 5 + (p == 3 ? 20 : 0);
              final totalPrice = (area * pm / 1000).round() * 1000.0;
              final aptNumber = '${(e - 1) * b.floorCount * b.apartsPerFloor + (f - 1) * b.apartsPerFloor + p + 1}';

              final r = rng.nextDouble();
              ApartmentStatus st;
              if (r < 0.48) {
                st = ApartmentStatus.available;
              } else if (r < 0.68) {
                st = ApartmentStatus.booked;
              } else if (r < 0.88) {
                st = ApartmentStatus.sold;
              } else {
                st = ApartmentStatus.reserved;
              }

              apartments.add(Apartment(
                id: aptIdCounter++,
                complexId: c.id,
                number: aptNumber,
                status: st,
                type: type,
                rooms: rooms,
                totalArea: area,
                livingArea: double.parse((area * 0.58).toStringAsFixed(1)),
                kitchenArea: double.parse((8.5 + p * 1.5).toStringAsFixed(1)),
                pricePerSqm: pm,
                totalPrice: totalPrice,
                currency: '\$',
                floor: f,
                entrance: e,
                position: p,
                buildingKey: b.key,
                buildingName: b.name,
                bookingCountMonth: st == ApartmentStatus.booked ? 1 : 0,
              ));
            }
          }
        }
      }
    }
  }

  void _startExpirationTimer() {
    _expireTimer?.cancel();
    _expireTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkExpiredReservations();
    });
  }

  @override
  void dispose() {
    _expireTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Complex Management (TZ section 1)
  // ─────────────────────────────────────────────────────────────────────────

  void addComplex({
    required String name,
    required String address,
    int buildingCount = 1,
    String? phone,
    String? email,
    String? salesAddress,
    String? workingHours,
  }) {
    final newId = ++_complexIdCounter;
    final defaultBuildings = List.generate(buildingCount, (i) {
      final key = String.fromCharCode(65 + i); // A, B, C...
      return Building(
        key: key,
        name: 'Корпус $key',
        entranceCount: 2,
        floorCount: 9,
        apartsPerFloor: 4,
        apartmentTypes: ['Студия', 'Евроремонт'],
      );
    });

    final newComplex = ResidentialComplex(
      id: newId,
      name: name,
      address: address,
      buildingCount: buildingCount,
      buildings: defaultBuildings,
      salesOffice: SalesOfficeInfo(
        address: salesAddress ?? address,
        email: email ?? 'sales@shamcrm.com',
        phone: phone ?? '+992 ...',
        workingHours: workingHours ?? '09:00 – 18:00',
      ),
    );

    complexes.insert(0, newComplex);

    // Pre-create apartments for this new complex
    int maxAptId = apartments.isNotEmpty ? apartments.map((a) => a.id).fold(0, max) : 0;
    for (final b in defaultBuildings) {
      for (int e = 1; e <= b.entranceCount; e++) {
        for (int f = 1; f <= b.floorCount; f++) {
          for (int p = 0; p < b.apartsPerFloor; p++) {
            final rooms = (p % 3) + 1;
            final area = 40.0 + rooms * 18.0;
            final pm = 750.0 + f * 5;
            final total = (area * pm).roundToDouble();
            final aptNumber = '${(e - 1) * b.floorCount * b.apartsPerFloor + (f - 1) * b.apartsPerFloor + p + 1}';
            apartments.add(Apartment(
              id: ++maxAptId,
              complexId: newId,
              number: aptNumber,
              status: ApartmentStatus.available,
              type: rooms == 1 ? 'Студия' : 'Евроремонт',
              rooms: rooms,
              totalArea: area,
              livingArea: double.parse((area * 0.6).toStringAsFixed(1)),
              kitchenArea: 10.0,
              pricePerSqm: pm,
              totalPrice: total,
              currency: '\$',
              floor: f,
              entrance: e,
              position: p,
              buildingKey: b.key,
              buildingName: b.name,
            ));
          }
        }
      }
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Queries
  // ─────────────────────────────────────────────────────────────────────────

  List<Apartment> getApartmentsForComplex(int complexId) {
    return apartments.where((a) => a.complexId == complexId).toList();
  }

  ResidentialComplex? findComplexById(int id) {
    try {
      return complexes.firstWhere((c) => c.id == id);
    } catch (_) {
      return complexes.isNotEmpty ? complexes.first : null;
    }
  }

  int getAvailableCount(int complexId) {
    return apartments.where((a) => a.complexId == complexId && a.status == ApartmentStatus.available).length;
  }

  int getBookedCount(int complexId) {
    return apartments.where((a) => a.complexId == complexId && a.status == ApartmentStatus.booked).length;
  }

  int getSoldCount(int complexId) {
    return apartments.where((a) => a.complexId == complexId && a.status == ApartmentStatus.sold).length;
  }

  int getReservedCount(int complexId) {
    return apartments.where((a) => a.complexId == complexId && a.status == ApartmentStatus.reserved).length;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Order actions & Automatic Status Management (TZ section 5.2)
  // ─────────────────────────────────────────────────────────────────────────

  String? createOrder({
    Apartment? apartment,
    required String buyerName,
    required String buyerPhone,
    required String buyerEmail,
    String? comment,
    required String roleName,
    required DealType dealType,
    double downPayment = 0,
    int months = 12,
    String? barterSubject,
    double barterAmount = 0,
    ParkingSpot? parking,
    Map<int, String>? customFields,
  }) {
    if (apartment == null && parking == null) {
      return 'Выберите помещение или паркинг для создания заказа';
    }

    // Strict TZ rule
    if (apartment != null) {
      if (apartment.status != ApartmentStatus.available) {
        return 'Заказ доступен только для свободных квартир!';
      }

      if (apartment.bookingCountMonth >= monthlyBookingLimit) {
        return 'Лимит исчерпан: одну квартиру нельзя бронировать более $monthlyBookingLimit раз в месяц';
      }
    }

    final setting = roleSettings.firstWhere(
      (r) => r.roleName == roleName,
      orElse: () => roleSettings.first,
    );
    final reservedUntil = DateTime.now().add(Duration(days: setting.durationDays));

    final totalPrice = (apartment?.totalPrice ?? 0) + (parking?.price ?? 0);

    PaymentDetails? pay;
    if (dealType != DealType.cash) {
      final effectiveBarter = dealType == DealType.mixed ? barterAmount : 0.0;
      final installmentSum = (totalPrice - downPayment - effectiveBarter).clamp(0.0, double.infinity);
      final sched = PaymentDetails.generateSchedule(totalInstallmentSum: installmentSum, months: months);
      pay = PaymentDetails(
        downPayment: downPayment,
        months: months,
        installmentSum: installmentSum,
        monthlyPayment: sched.isNotEmpty ? sched.first.paymentAmount : 0,
        barterSubject: barterSubject,
        barterAmount: effectiveBarter,
        schedule: sched,
      );
    }

    final orderId = 'З-${++_orderIdCounter}';
    final newOrder = Order(
      id: orderId,
      complexId: apartment?.complexId ?? parking?.complexId ?? _selectedComplexId,
      apartmentId: apartment?.id,
      parkingId: parking?.id,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      comment: comment,
      manager: roleName,
      dealType: dealType,
      price: totalPrice,
      status: OrderStatus.inProgress,
      reservedUntil: reservedUntil,
      paymentDetails: pay,
      customFields: customFields ?? const {},
    );

    orders.insert(0, newOrder);

    // Auto-change status of apartment to booked
    if (apartment != null) {
      final index = apartments.indexWhere((a) => a.id == apartment.id);
      if (index != -1) {
        apartments[index] = apartments[index].copyWith(
          status: ApartmentStatus.booked,
          bookingCountMonth: apartments[index].bookingCountMonth + 1,
        );
      }
    }

    if (parking != null) {
      final pIndex = parkingSpots.indexWhere((p) => p.id == parking.id);
      if (pIndex != -1) {
        parkingSpots[pIndex] = parkingSpots[pIndex].copyWith(
          status: ApartmentStatus.booked,
          linkedApartmentId: apartment?.id,
        );
      }
    }

    notifyListeners();
    return null; // success
  }

  void toggleApartmentReserve(Apartment apt) {
    final idx = apartments.indexWhere((a) => a.id == apt.id);
    if (idx == -1) return;
    if (apt.status != ApartmentStatus.available && apt.status != ApartmentStatus.reserved) {
      return;
    }
    final nextStatus = apt.status == ApartmentStatus.reserved
        ? ApartmentStatus.available
        : ApartmentStatus.reserved;

    apartments[idx] = apartments[idx].copyWith(status: nextStatus);
    notifyListeners();
  }

  void updateOrderStatus(Order order, OrderStatus newStatus) {
    final orderIdx = orders.indexWhere((o) => o.id == order.id);
    if (orderIdx == -1) return;

    orders[orderIdx] = orders[orderIdx].copyWith(
      status: newStatus,
      reservedUntil: newStatus == OrderStatus.inProgress ? order.reservedUntil : null,
    );

    if (order.apartmentId != null) {
      final aptIdx = apartments.indexWhere((a) => a.id == order.apartmentId);
      if (aptIdx != -1) {
        ApartmentStatus nextAptStatus;
        if (newStatus == OrderStatus.success) {
          nextAptStatus = ApartmentStatus.sold;
        } else if (newStatus == OrderStatus.rejected) {
          nextAptStatus = ApartmentStatus.available;
        } else {
          nextAptStatus = ApartmentStatus.booked;
        }
        apartments[aptIdx] = apartments[aptIdx].copyWith(status: nextAptStatus);
      }
    }
    notifyListeners();
  }

  int checkExpiredReservations() {
    final now = DateTime.now();
    int expiredCount = 0;
    for (final order in orders) {
      if (order.status == OrderStatus.inProgress &&
          order.reservedUntil != null &&
          order.reservedUntil!.isBefore(now)) {
        updateOrderStatus(order, OrderStatus.rejected);
        expiredCount++;
      }
    }
    return expiredCount;
  }
}

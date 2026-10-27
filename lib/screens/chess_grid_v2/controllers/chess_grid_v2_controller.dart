import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';

/// Controller for "Шахматка 2" (Interactive 3D / Smart Facade / 2.0).
/// Pre-loaded with rich, full-featured, photorealistic demo database
/// simulating a full production environment with hundreds of units,
/// diverse building shapes (cascading terraces, curved towers),
/// buyers, deals, parking spots, and analytics.
class ChessGridV2Controller extends ChangeNotifier {
  static ChessGridV2Controller? _instance;
  static ChessGridV2Controller get instance => _instance ??= ChessGridV2Controller._();

  ChessGridV2Controller._() {
    _initRichMockData();
    _startExpirationTimer();
  }

  List<ResidentialComplex> complexes = [];
  List<Apartment> apartments = [];
  List<ParkingSpot> parkingSpots = [];
  List<Order> orders = [];
  List<RoleBookingSetting> roleSettings = [];
  late CompanyRequisites requisites;
  int monthlyBookingLimit = 5;
  List<CustomField> customFields = [];

  bool isLoading = false;
  bool isLoadingComplex = false;
  bool isLoadingApartments = false;
  String? errorMessage;

  int _selectedComplexId = 201;
  String _selectedBuildingKey = 'A';
  ChessGridFilter _filter = const ChessGridFilter();
  Apartment? _selectedApartment;
  Timer? _expireTimer;

  int get selectedComplexId => _selectedComplexId;
  String get selectedBuildingKey => _selectedBuildingKey;
  ChessGridFilter get filter => _filter;
  Apartment? get selectedApartment => _selectedApartment;

  ResidentialComplex get complex {
    return complexes.firstWhereOrNull((c) => c.id == _selectedComplexId) ??
        (complexes.isNotEmpty ? complexes.first : _createDefaultComplex());
  }

  Building? get currentBuilding {
    final c = complex;
    return c.buildings.firstWhereOrNull((b) => b.key == _selectedBuildingKey) ??
        (c.buildings.isNotEmpty ? c.buildings.first : null);
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

  List<Apartment> getApartmentsForComplex(int complexId) {
    return apartments.where((a) => a.complexId == complexId).toList();
  }

  int getAvailableCount(int complexId) =>
      apartments.where((a) => a.complexId == complexId && a.status == ApartmentStatus.available).length;

  int getBookedCount(int complexId) =>
      apartments.where((a) => a.complexId == complexId && a.status == ApartmentStatus.booked).length;

  int getSoldCount(int complexId) =>
      apartments.where((a) => a.complexId == complexId && a.status == ApartmentStatus.sold).length;

  int getReservedCount(int complexId) =>
      apartments.where((a) => a.complexId == complexId && a.status == ApartmentStatus.reserved).length;

  ResidentialComplex? findComplexById(int id) {
    return complexes.firstWhereOrNull((c) => c.id == id);
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
    _selectedBuildingKey = f.buildingKey;
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

  Future<void> loadComplexDetails(int id, {bool showLoading = false}) async {
    _selectedComplexId = id;
    final c = complex;
    if (c.buildings.isNotEmpty) {
      if (!c.buildings.any((b) => b.key == _selectedBuildingKey)) {
        _selectedBuildingKey = c.buildings.first.key;
      }
    } else {
      _selectedBuildingKey = '';
    }
    _filter = ChessGridFilter(buildingKey: _selectedBuildingKey);
    notifyListeners();
  }

  Future<bool> updateComplex(ResidentialComplex updated) async {
    final idx = complexes.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      complexes[idx] = updated;
      notifyListeners();
    }
    return true;
  }

  Future<bool> addBuilding(Building b) async {
    final c = complex;
    final updatedBuildings = List<Building>.from(c.buildings)..add(b);
    updateComplex(c.copyWith(
      buildings: updatedBuildings,
      buildingCount: updatedBuildings.length,
    ));
    _selectedBuildingKey = b.key;
    notifyListeners();
    return true;
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
    notifyListeners();
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

  void addOrder(Order order) {
    orders.add(order);
    final idx = apartments.indexWhere((a) => a.id == order.apartmentId);
    if (idx != -1) {
      final newStatus = order.status == OrderStatus.success
          ? ApartmentStatus.sold
          : ApartmentStatus.booked;
      apartments[idx] = apartments[idx].copyWith(status: newStatus);
    }
    notifyListeners();
  }

  void cancelOrder(String orderId) {
    final oIdx = orders.indexWhere((o) => o.id == orderId);
    if (oIdx != -1) {
      final o = orders[oIdx];
      orders[oIdx] = o.copyWith(status: OrderStatus.rejected);
      final aIdx = apartments.indexWhere((a) => a.id == o.apartmentId);
      if (aIdx != -1) {
        apartments[aIdx] = apartments[aIdx].copyWith(status: ApartmentStatus.available);
      }
      notifyListeners();
    }
  }

  void confirmOrder(String orderId) {
    final oIdx = orders.indexWhere((o) => o.id == orderId);
    if (oIdx != -1) {
      final o = orders[oIdx];
      orders[oIdx] = o.copyWith(status: OrderStatus.success);
      final aIdx = apartments.indexWhere((a) => a.id == o.apartmentId);
      if (aIdx != -1) {
        apartments[aIdx] = apartments[aIdx].copyWith(status: ApartmentStatus.sold);
      }
      notifyListeners();
    }
  }

  void toggleReserve(Apartment apt) {
    final newStatus = apt.status == ApartmentStatus.reserved
        ? ApartmentStatus.available
        : ApartmentStatus.reserved;
    updateApartment(apt.copyWith(status: newStatus));
  }

  void toggleApartmentReserve(Apartment apt) => toggleReserve(apt);

  List<Entrance> loadBuildingEntrances(int buildingId) {
    final b = complex.buildings.firstWhereOrNull((item) => item.id == buildingId);
    final count = b?.entranceCount ?? 3;
    return List.generate(count, (i) {
      return Entrance(
        id: (buildingId * 10) + i + 1,
        buildingId: buildingId,
        number: i + 1,
        name: 'Подъезд ${i + 1}',
      );
    });
  }

  void _startExpirationTimer() {
    _expireTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      bool changed = false;
      for (int i = 0; i < orders.length; i++) {
        final o = orders[i];
        if (o.status == OrderStatus.inProgress &&
            o.reservedUntil != null &&
            now.isAfter(o.reservedUntil!)) {
          orders[i] = o.copyWith(status: OrderStatus.rejected);
          final aIdx = apartments.indexWhere((a) => a.id == o.apartmentId);
          if (aIdx != -1 && apartments[aIdx].status == ApartmentStatus.booked) {
            apartments[aIdx] = apartments[aIdx].copyWith(status: ApartmentStatus.available);
          }
          changed = true;
        }
      }
      if (changed) notifyListeners();
    });
  }

  ResidentialComplex _createDefaultComplex() {
    return const ResidentialComplex(
      id: 201,
      name: 'Grand Panorama Riverside',
      address: 'ул. Набережная, 42',
      buildingCount: 3,
      buildings: [],
      salesOffice: SalesOfficeInfo(
        address: 'ул. Набережная, 42, офис 101',
        email: 'sales@grand-riverside.com',
        phone: '+992 92 700 00 01',
        workingHours: '09:00 - 20:00 (без выходных)',
      ),
    );
  }

  void _initRichMockData() {
    // 1. Rich Residential Complexes
    complexes = [
      ResidentialComplex(
        id: 201,
        name: 'Grand Panorama Riverside',
        address: 'ул. Набережная реки, 42 (Премиум)',
        lat: 41.311081,
        lng: 69.240562,
        photos: const [
          'assets/images/building_cascade.jpg',
          'assets/images/building_tower.jpg',
        ],
        buildingCount: 3,
        salesOffice: const SalesOfficeInfo(
          address: 'ул. Набережная, 42, шоурум 1-й этаж',
          email: 'riverside@shamcrm.com',
          phone: '+992 92 966 40 41',
          workingHours: '09:00 - 20:00 (Пн-Вс)',
        ),
        buildings: const [
          Building(
            id: 2011,
            key: 'A',
            name: 'Корпус А (Riverside Cascade)',
            residentialComplexId: 201,
            entranceCount: 3,
            floorCount: 18,
            apartsPerFloor: 4,
            apartmentTypes: ['Студия', 'Евроремонт', 'Черновая', 'Пентхаус'],
            buildingShape: 'cascading',
            imageUrl: 'assets/images/building_cascade.jpg',
          ),
          Building(
            id: 2012,
            key: 'B',
            name: 'Корпус B (Sky Tower)',
            residentialComplexId: 201,
            entranceCount: 1,
            floorCount: 22,
            apartsPerFloor: 4,
            apartmentTypes: ['Студия', 'Евроремонт', 'Пентхаус'],
            buildingShape: 'curvedTower',
            imageUrl: 'assets/images/building_tower.jpg',
          ),
          Building(
            id: 2013,
            key: 'C',
            name: 'Корпус C (Park Residence)',
            residentialComplexId: 201,
            entranceCount: 2,
            floorCount: 12,
            apartsPerFloor: 4,
            apartmentTypes: ['Студия', 'Евроремонт', 'Черновая'],
            buildingShape: 'standard',
            imageUrl: 'assets/images/building_cascade.jpg',
          ),
        ],
      ),
      ResidentialComplex(
        id: 202,
        name: 'Silk Road Towers',
        address: 'Проспект Рудаки, 120 (Деловой центр)',
        lat: 41.320000,
        lng: 69.255000,
        photos: const [
          'assets/images/building_tower.jpg',
        ],
        buildingCount: 2,
        salesOffice: const SalesOfficeInfo(
          address: 'Проспект Рудаки, 120, этаж 3',
          email: 'silkroad@shamcrm.com',
          phone: '+992 93 500 11 22',
          workingHours: '09:00 - 19:00 (Пн-Сб)',
        ),
        buildings: const [
          Building(
            id: 2021,
            key: 'T1',
            name: 'Восточная Башня',
            residentialComplexId: 202,
            entranceCount: 2,
            floorCount: 20,
            apartsPerFloor: 4,
            apartmentTypes: ['Студия', 'Евроремонт', 'Пентхаус'],
            buildingShape: 'curvedTower',
            imageUrl: 'assets/images/building_tower.jpg',
          ),
          Building(
            id: 2022,
            key: 'T2',
            name: 'Западная Башня',
            residentialComplexId: 202,
            entranceCount: 2,
            floorCount: 16,
            apartsPerFloor: 4,
            apartmentTypes: ['Студия', 'Евроремонт', 'Черновая'],
            buildingShape: 'standard',
            imageUrl: 'assets/images/building_cascade.jpg',
          ),
        ],
      ),
      ResidentialComplex(
        id: 203,
        name: 'Зелёный Квартал',
        address: 'Парковая аллея, 15 (Эко-парк)',
        lat: 41.295000,
        lng: 69.230000,
        photos: const [
          'assets/images/building_cascade.jpg',
        ],
        buildingCount: 3,
        salesOffice: const SalesOfficeInfo(
          address: 'Парковая аллея, 15, блок 1',
          email: 'greenpark@shamcrm.com',
          phone: '+992 90 123 45 67',
          workingHours: '10:00 - 18:00 (Пн-Пт)',
        ),
        buildings: const [
          Building(
            id: 2031,
            key: 'BLK1',
            name: 'Блок 1 (Сосновый)',
            residentialComplexId: 203,
            entranceCount: 2,
            floorCount: 10,
            apartsPerFloor: 4,
            apartmentTypes: ['Евроремонт', 'Черновая'],
            buildingShape: 'standard',
            imageUrl: 'assets/images/building_cascade.jpg',
          ),
          Building(
            id: 2032,
            key: 'BLK2',
            name: 'Блок 2 (Берёзовый)',
            residentialComplexId: 203,
            entranceCount: 2,
            floorCount: 10,
            apartsPerFloor: 4,
            apartmentTypes: ['Евроремонт', 'Черновая'],
            buildingShape: 'standard',
            imageUrl: 'assets/images/building_cascade.jpg',
          ),
          Building(
            id: 2033,
            key: 'BLK3',
            name: 'Блок 3 (Кленовый)',
            residentialComplexId: 203,
            entranceCount: 2,
            floorCount: 8,
            apartsPerFloor: 4,
            apartmentTypes: ['Студия', 'Евроремонт'],
            buildingShape: 'cascading',
            imageUrl: 'assets/images/building_cascade.jpg',
          ),
        ],
      ),
    ];

    // 2. Full Apartment & Order generation across all complexes
    apartments = [];
    orders = [];
    parkingSpots = [];
    int aptIdCounter = 1000;
    final rnd = Random(777);

    final sampleBuyers = [
      'Рахимов Дилшод',
      'Каримова Нигора',
      'Ахмедов Фарход',
      'Юсупова Мадина',
      'Назаров Бахтиёр',
      'Иванов Сергей',
      'Саидова Зарина',
      'Гафуров Умед',
      'Холиков Шерзод',
      'Петрова Анна',
      'Мирзоев Джамшед',
      'Бобоев Исроил',
    ];

    final sampleManagers = [
      'Азиза Каримова',
      'Рустам Назаров',
      'Лола Темурова',
      'Фаррух Салимов',
    ];

    for (final c in complexes) {
      for (final b in c.buildings) {
        final bKey = b.key;
        final bName = b.name;
        final perFloor = b.apartsPerFloor > 0 ? b.apartsPerFloor : 4;
        final floorCount = b.floorCount > 0 ? b.floorCount : 10;
        final entCount = b.entranceCount > 0 ? b.entranceCount : 2;

        // Generate Parking Spots
        final pCount = (floorCount * entCount).clamp(8, 28);
        for (int pi = 1; pi <= pCount; pi++) {
          final pTypes = ['Подземная', 'Открытая', 'Закрытая'];
          final pType = pTypes[(pi - 1) % 3];
          final pPrice = pType == 'Подземная' ? 9500.0 : (pType == 'Закрытая' ? 7500.0 : 4500.0);
          final pArea = pType == 'Закрытая' ? 18.5 : 14.0;
          final rVal = rnd.nextDouble();
          final pStatus = rVal < 0.45
              ? ApartmentStatus.available
              : (rVal < 0.75 ? ApartmentStatus.booked : ApartmentStatus.sold);

          parkingSpots.add(ParkingSpot(
            id: parkingSpots.length + 1,
            complexId: c.id,
            number: 'П-${pi.toString().padLeft(2, '0')}',
            type: pType,
            buildingKey: bKey,
            price: pPrice,
            area: pArea,
            status: pStatus,
          ));
        }

        // Generate Apartments
        for (int e = 1; e <= entCount; e++) {
          for (int f = 1; f <= floorCount; f++) {
            for (int p = 0; p < perFloor; p++) {
              final isPenthouse = f >= floorCount - 1 && p == perFloor - 1;
              final rooms = isPenthouse ? 4 : (p % 3) + 1;
              final area = isPenthouse ? 142.0 : 38.0 + (rooms * 17.5);
              final priceSqm = 820.0 + (f * 12.0) + (isPenthouse ? 300.0 : 0.0);
              final totalPrice = (area * priceSqm).roundToDouble();

              final aptNumber = '${(e - 1) * floorCount * perFloor + (f - 1) * perFloor + p + 1}';

              // Status Distribution: ~45% free, ~25% booked, ~20% sold, ~10% reserved
              final r = rnd.nextDouble();
              ApartmentStatus status;
              if (r < 0.45) {
                status = ApartmentStatus.available;
              } else if (r < 0.70) {
                status = ApartmentStatus.booked;
              } else if (r < 0.90) {
                status = ApartmentStatus.sold;
              } else {
                status = ApartmentStatus.reserved;
              }

              final aptType = isPenthouse
                  ? 'Пентхаус с террасой'
                  : (rooms == 1 ? 'Студия' : (rooms == 2 ? 'Евроремонт' : 'Черновая'));

              final aptId = aptIdCounter++;
              final apt = Apartment(
                id: aptId,
                complexId: c.id,
                number: aptNumber,
                status: status,
                type: aptType,
                rooms: rooms,
                totalArea: area,
                livingArea: (area * 0.62).roundToDouble(),
                kitchenArea: isPenthouse ? 22.0 : 12.0,
                pricePerSqm: priceSqm,
                totalPrice: totalPrice,
                currency: '\$',
                floor: f,
                entrance: e,
                position: p,
                buildingKey: bKey,
                buildingName: bName,
                bookingCountMonth: status == ApartmentStatus.booked ? 1 : 0,
              );
              apartments.add(apt);

              // Create Realistic Orders for Booked & Sold units
              if (status == ApartmentStatus.booked || status == ApartmentStatus.sold) {
                final oIdx = orders.length;
                final buyer = sampleBuyers[oIdx % sampleBuyers.length];
                final mgr = sampleManagers[oIdx % sampleManagers.length];
                final isSold = status == ApartmentStatus.sold;
                final dealType = oIdx % 3 == 0
                    ? DealType.cash
                    : (oIdx % 3 == 1 ? DealType.installment : DealType.mixed);

                final downPayment = (totalPrice * 0.25).roundToDouble();
                final barterAmount = dealType == DealType.mixed ? 8000.0 : 0.0;
                final installmentSum = (totalPrice - downPayment - barterAmount).clamp(0, totalPrice).toDouble();
                const months = 18;
                final monthlyPayment = (installmentSum / months).roundToDouble();

                orders.add(Order(
                  id: 'З-${2100 + oIdx}',
                  complexId: c.id,
                  apartmentId: aptId,
                  buyerName: buyer,
                  buyerPhone: '+992 92 ${100 + (oIdx * 3 % 899)} ${20 + (oIdx % 70)} 00',
                  buyerEmail: 'client${oIdx + 1}@gmail.com',
                  manager: mgr,
                  dealType: dealType,
                  price: totalPrice,
                  status: isSold ? OrderStatus.success : OrderStatus.inProgress,
                  reservedUntil: isSold ? null : DateTime.now().add(Duration(days: (oIdx % 6) + 1)),
                  paymentDetails: dealType != DealType.cash
                      ? PaymentDetails(
                          downPayment: downPayment,
                          months: months,
                          installmentSum: installmentSum,
                          monthlyPayment: monthlyPayment,
                          barterSubject: dealType == DealType.mixed ? 'Автомобиль' : null,
                          barterAmount: barterAmount,
                          schedule: PaymentDetails.generateSchedule(
                            totalInstallmentSum: installmentSum,
                            months: months,
                          ),
                        )
                      : null,
                ));
              }
            }
          }
        }
      }
    }

    // Role booking settings
    roleSettings = const [
      RoleBookingSetting(roleName: 'Администратор', durationDays: 14),
      RoleBookingSetting(roleName: 'Менеджер по продажам', durationDays: 5),
      RoleBookingSetting(roleName: 'Стажёр', durationDays: 3),
      RoleBookingSetting(roleName: 'Партнёр / Риелтор', durationDays: 2),
    ];

    requisites = const CompanyRequisites(
      name: 'ООО «SHAM DEVELOPMENT GROUP»',
      address: 'г. Душанбе, ул. Айни, 48, БЦ «Созидание»',
      phone: '+992 92 966 40 41',
      email: 'invest@shamcrm.com',
      inn: '020054321',
    );
  }

  @override
  void dispose() {
    _expireTimer?.cancel();
    super.dispose();
  }
}

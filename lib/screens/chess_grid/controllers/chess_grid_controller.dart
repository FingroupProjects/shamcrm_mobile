import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';

class ChessGridController extends ChangeNotifier {
  static ChessGridController? _instance;
  static ChessGridController get instance => _instance ??= ChessGridController._();

  ChessGridController._() {
    _initData();
    _startExpirationTimer();
    loadDataFromApi();
    loadRolesFromApi();
  }

  final ApiService _apiService = ApiService();

  List<ResidentialComplex> complexes = [];
  List<Apartment> apartments = [];
  List<ParkingSpot> parkingSpots = [];
  List<Order> orders = [];
  List<RoleBookingSetting> roleSettings = [];
  late CompanyRequisites requisites;
  int monthlyBookingLimit = 3;
  List<CustomField> customFields = [];

  bool isLoading = false;
  bool isLoadingComplex = false;
  bool isLoadingApartments = false;
  String? errorMessage;

  int _selectedComplexId = 0;
  String _selectedBuildingKey = '';
  ChessGridFilter _filter = const ChessGridFilter();
  Apartment? _selectedApartment;

  Timer? _expireTimer;
  int _orderIdCounter = 1000;

  int get selectedComplexId => _selectedComplexId;
  String get selectedBuildingKey => _selectedBuildingKey;
  ChessGridFilter get filter => _filter;
  Apartment? get selectedApartment => _selectedApartment;

  ResidentialComplex get complex {
    return findComplexById(_selectedComplexId) ??
        (complexes.isNotEmpty
            ? complexes.first
            : const ResidentialComplex(
                id: 0,
                name: 'Жилой комплекс',
                address: '',
                buildingCount: 0,
                buildings: [],
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

  /// Loads residential complexes from backend API (GET /api/residential-complexes)
  Future<void> loadDataFromApi({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final fetchedComplexes = await _apiService.getResidentialComplexes();
      complexes = fetchedComplexes;

      if (complexes.isNotEmpty) {
        if (_selectedComplexId == 0 || !complexes.any((c) => c.id == _selectedComplexId)) {
          _selectedComplexId = complexes.first.id;
        }
        apartments = [];
        orders = [];
        parkingSpots = [];
        final c = complex;
        if (c.buildings.isNotEmpty) {
          if (_selectedBuildingKey.isEmpty || !c.buildings.any((b) => b.key == _selectedBuildingKey)) {
            _selectedBuildingKey = c.buildings.first.key;
          }
          final firstB = c.buildings.firstWhereOrNull((b) => b.key == _selectedBuildingKey);
          if (firstB != null && firstB.id != null) {
            await loadApartmentsForBuilding(buildingId: firstB.id, buildingKey: firstB.key);
          }
        } else {
          _selectedBuildingKey = '';
        }
      } else {
        _selectedComplexId = 0;
        _selectedBuildingKey = '';
        apartments = [];
        orders = [];
        parkingSpots = [];
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('ChessGridController.loadDataFromApi error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
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

  /// Loads full complex details & buildings from backend API
  Future<void> loadComplexDetails(int id, {bool showLoading = true}) async {
    _selectedComplexId = id;
    if (showLoading) {
      isLoadingComplex = true;
      notifyListeners();
    }

    try {
      // 1. Fetch buildings for this complex from API (GET /api/buildings?residential_complex_id={id})
      List<Building> fetchedBuildings = [];
      try {
        fetchedBuildings = await _apiService.getBuildings(residentialComplexId: id);
      } catch (e) {
        debugPrint('ChessGridController.loadComplexDetails getBuildings error: $e');
      }

      // 2. Fetch complex by ID from API (GET /api/residential-complexes/{id})
      ResidentialComplex? fetchedComplex;
      try {
        fetchedComplex = await _apiService.getResidentialComplexById(id);
      } catch (e) {
        debugPrint('ChessGridController.loadComplexDetails getResidentialComplexById error: $e');
      }

      final combinedBuildings = fetchedBuildings.isNotEmpty
          ? fetchedBuildings
          : (fetchedComplex != null && fetchedComplex.buildings.isNotEmpty
              ? fetchedComplex.buildings
              : <Building>[]);

      final current = findComplexById(id) ?? fetchedComplex;
      if (current != null) {
        final updated = current.copyWith(
          buildings: combinedBuildings,
          buildingCount: combinedBuildings.isNotEmpty ? combinedBuildings.length : current.buildingCount,
        );

        final idx = complexes.indexWhere((c) => c.id == id);
        if (idx != -1) {
          complexes[idx] = updated;
        } else {
          complexes.add(updated);
        }

        if (combinedBuildings.isNotEmpty) {
          if (_selectedBuildingKey.isEmpty || !combinedBuildings.any((b) => b.key == _selectedBuildingKey)) {
            _selectedBuildingKey = combinedBuildings.first.key;
          }
        } else {
          _selectedBuildingKey = '';
        }
        _filter = ChessGridFilter(buildingKey: _selectedBuildingKey);

        // Fetch real apartments (goods) from server for the selected building
        final selectedB = combinedBuildings.firstWhereOrNull((b) => b.key == _selectedBuildingKey);
        if (selectedB != null && selectedB.id != null) {
          await loadApartmentsForBuilding(buildingId: selectedB.id, buildingKey: selectedB.key);
        } else {
          apartments.removeWhere((a) => a.complexId == id);
        }
      }
    } catch (e) {
      debugPrint('ChessGridController.loadComplexDetails error: $e');
    } finally {
      isLoadingComplex = false;
      notifyListeners();
    }
  }

  /// Loads real apartments (goods) for a specific building from GET /good?building_id={id}
  Future<void> loadApartmentsForBuilding({int? buildingId, String? buildingKey}) async {
    final bKey = buildingKey ?? _selectedBuildingKey;
    Building? b;
    if (complex.buildings.isNotEmpty) {
      b = complex.buildings.firstWhereOrNull((item) =>
          item.key == bKey || (buildingId != null && item.id == buildingId));
    }

    final targetBuildingId = buildingId ?? b?.id;
    if (targetBuildingId == null) {
      if (kDebugMode) {
        debugPrint('ChessGridController.loadApartmentsForBuilding: no buildingId available for $bKey');
      }
      return;
    }

    isLoadingApartments = true;
    notifyListeners();

    try {
      final fetchedApts = await _apiService.getApartmentsByBuilding(
        buildingId: targetBuildingId,
        residentialComplexId: _selectedComplexId,
        buildingKey: b?.key ?? bKey,
        buildingName: b?.name ?? 'Корпус',
      );

      // Replace existing apartments for this building with real ones from server
      apartments.removeWhere((a) => a.buildingKey == (b?.key ?? bKey));
      apartments.addAll(fetchedApts);
      errorMessage = null;

      if (kDebugMode) {
        debugPrint('ChessGridController.loadApartmentsForBuilding: successfully loaded ${fetchedApts.length} apartments for building #$targetBuildingId');
      }
    } catch (e) {
      debugPrint('ChessGridController.loadApartmentsForBuilding error: $e');
    } finally {
      isLoadingApartments = false;
      notifyListeners();
    }
  }

  void selectBuilding(String key) {
    _selectedBuildingKey = key;
    _filter = _filter.copyWith(buildingKey: key);
    notifyListeners();

    final b = complex.buildings.firstWhereOrNull((item) => item.key == key);
    if (b != null && b.id != null) {
      loadApartmentsForBuilding(buildingId: b.id, buildingKey: b.key);
    }
  }

  void selectApartment(Apartment? apt) {
    _selectedApartment = apt;
    notifyListeners();
  }

  void setFilter(ChessGridFilter f) {
    final oldKey = _selectedBuildingKey;
    _filter = f;
    _selectedBuildingKey = f.buildingKey;
    notifyListeners();

    if (f.buildingKey.isNotEmpty && f.buildingKey != oldKey) {
      final b = complex.buildings.firstWhereOrNull((item) => item.key == f.buildingKey);
      if (b != null && b.id != null) {
        loadApartmentsForBuilding(buildingId: b.id, buildingKey: b.key);
      }
    }
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

  Future<bool> updateComplex(ResidentialComplex updated) async {
    final idx = complexes.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      complexes[idx] = updated;
      notifyListeners();
    }
    try {
      await _apiService.updateResidentialComplex(updated.id, updated.toUpdateJson());
      return true;
    } catch (e) {
      debugPrint('ChessGridController.updateComplex API error: $e');
      rethrow;
    }
  }

  Future<bool> addBuilding(Building b) async {
    final c = complex;
    final complexId = b.residentialComplexId ?? c.id;
    final selectedTypes = b.apartmentTypes.isNotEmpty ? b.apartmentTypes : ['Студия', 'Евроремонт'];
    final payload = {
      'name': b.name,
      'residential_complex_id': complexId,
      'number_of_entrances': b.entranceCount,
      'number_of_floors': b.floorCount,
      'number_of_apartments_per_floor': b.apartsPerFloor,
      'type_of_floors': selectedTypes,
      'apartment_types': selectedTypes,
    };

    try {
      final created = await _apiService.createBuilding(payload);
      final updatedBuildings = List<Building>.from(c.buildings)..add(created);
      final updatedComplex = c.copyWith(
        buildings: updatedBuildings,
        buildingCount: updatedBuildings.length,
      );
      final cIdx = complexes.indexWhere((item) => item.id == c.id);
      if (cIdx != -1) {
        complexes[cIdx] = updatedComplex;
      }
      _selectedBuildingKey = created.key;
      if (created.id != null) {
        await loadApartmentsForBuilding(buildingId: created.id, buildingKey: created.key);
      } else {
        apartments = [];
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ChessGridController.addBuilding API error: $e');
      rethrow;
    }
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

  /// Loads entrances for a building: GET /buildings/{building_id}/entrances
  Future<List<Entrance>> loadBuildingEntrances(int buildingId) async {
    try {
      return await _apiService.getBuildingEntrances(buildingId);
    } catch (e) {
      debugPrint('ChessGridController.loadBuildingEntrances error: $e');
      return [];
    }
  }

  Future<void> addApartment(Apartment apt, {List<int>? copyToFloors}) async {
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

    // Persist to server via API (POST /good)
    try {
      final b = complex.buildings.firstWhereOrNull((item) => item.key == apt.buildingKey);
      final targetBuildingId = b?.id;
      if (targetBuildingId != null) {
        final created = await _apiService.createApartmentGood(
          buildingId: targetBuildingId,
          entranceId: apt.entranceId,
          entrance: apt.entrance,
          residentialComplexId: apt.complexId > 0 ? apt.complexId : complex.id,
          number: apt.number,
          floor: apt.floor,
          rooms: apt.rooms,
          totalArea: apt.totalArea,
          livingArea: apt.livingArea,
          kitchenArea: apt.kitchenArea,
          totalPrice: apt.totalPrice,
          pricePerSqm: apt.pricePerSqm,
          type: apt.type,
          apartmentType: apt.type,
          status: apt.status,
          position: apt.position,
          buildingKey: apt.buildingKey,
          buildingName: apt.buildingName,
        );
        final idx = apartments.indexOf(apt);
        if (idx != -1) {
          apartments[idx] = created;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('ChessGridController.addApartment API error: $e');
    }
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
      _apiService.deleteApartmentGood(id).catchError((e) {
        debugPrint('ChessGridController.deleteApartment API error: $e');
        return false;
      });
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
        roleId: roleSettings[index].roleId,
        roleName: roleSettings[index].roleName,
        durationDays: days,
      );
      notifyListeners();
    }
  }

  Future<void> loadRolesFromApi() async {
    try {
      final roles = await _apiService.getRoles();
      if (roles.isNotEmpty) {
        final existingDurations = {
          for (final r in roleSettings) r.roleName.toLowerCase(): r.durationDays
        };
        roleSettings = roles.map((role) {
          final rName = role.name;
          final dur = existingDurations[rName.toLowerCase()] ??
              (rName.toLowerCase().contains('admin') ||
                      rName.toLowerCase().contains('роп') ||
                      rName.toLowerCase().contains('rop')
                  ? 7
                  : (rName.toLowerCase().contains('man') ||
                          rName.toLowerCase().contains('мен')
                      ? 3
                      : 1));
          return RoleBookingSetting(
            roleId: role.id,
            roleName: rName,
            durationDays: dur,
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ChessGridController.loadRolesFromApi: $e');
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
    ];

    roleSettings = [
      const RoleBookingSetting(roleId: 1, roleName: 'user', durationDays: 3),
      const RoleBookingSetting(roleId: 2, roleName: 'manager', durationDays: 3),
      const RoleBookingSetting(roleId: 3, roleName: 'admin', durationDays: 7),
      const RoleBookingSetting(roleId: 4, roleName: 'client', durationDays: 1),
      const RoleBookingSetting(roleId: 5, roleName: 'оператор', durationDays: 2),
      const RoleBookingSetting(roleId: 6, roleName: 'menejer', durationDays: 3),
      const RoleBookingSetting(roleId: 7, roleName: 'sas', durationDays: 1),
      const RoleBookingSetting(roleId: 8, roleName: 'Test', durationDays: 1),
      const RoleBookingSetting(roleId: 9, roleName: 'Тест 2', durationDays: 1),
      const RoleBookingSetting(roleId: 10, roleName: 'Тест', durationDays: 1),
      const RoleBookingSetting(roleId: 11, roleName: 'Тест новой роли', durationDays: 1),
      const RoleBookingSetting(roleId: 12, roleName: 'Новый роли', durationDays: 1),
      const RoleBookingSetting(roleId: 13, roleName: 'Роли', durationDays: 1),
      const RoleBookingSetting(roleId: 14, roleName: 'РОП', durationDays: 7),
      const RoleBookingSetting(roleId: 15, roleName: 'rop', durationDays: 7),
      const RoleBookingSetting(roleId: 16, roleName: 'task', durationDays: 1),
    ];

    requisites = const CompanyRequisites(
      name: 'ООО «Строительная компания»',
      address: '',
      phone: '',
      email: '',
      inn: '',
    );

    complexes = [];
    apartments = [];
    orders = [];
    parkingSpots = [];
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

  Future<bool> addComplex({
    required String name,
    required String address,
    int buildingCount = 1,
    String? phone,
    String? email,
    String? salesAddress,
    String? workingHours,
    String? startTime,
    String? endTime,
    double? lat,
    double? lng,
    List<String>? photos,
  }) async {
    final payload = {
      'name': name,
      'address': address,
      'latitude': (lat ?? 41.311081).toString(),
      'longitude': (lng ?? 69.240562).toString(),
      'number_of_buildings': buildingCount,
      'sales_department_address': (salesAddress != null && salesAddress.isNotEmpty)
          ? salesAddress
          : address,
      'sales_department_mail': (email != null && email.isNotEmpty)
          ? email
          : 'sales@panorama.uz',
      'sales_department_phone': (phone != null && phone.isNotEmpty)
          ? phone
          : '+998901234567',
      'start_time': (startTime != null && startTime.isNotEmpty)
          ? startTime
          : '09:00',
      'end_time': (endTime != null && endTime.isNotEmpty)
          ? endTime
          : '18:00',
    };

    try {
      final created = await _apiService.createResidentialComplex(
        payload,
        filePaths: photos,
      );
      complexes.insert(0, created);
      selectComplex(created.id);
      await loadDataFromApi(showLoading: false);
      return true;
    } catch (e) {
      debugPrint('ChessGridController.addComplex API error: $e');
      rethrow;
    }
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
    String? sourceId,
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

    if (parking != null && apartment == null) {
      if (parking.status != ApartmentStatus.available) {
        return 'Заказ доступен только для свободных парковочных мест!';
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
      sourceId: sourceId,
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

part of '../api_service.dart';

extension ApiChessGridX on ApiService {
  List _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final res = decoded['result'];
      if (res is List) return res;
      if (res is Map && res['data'] is List) return res['data'] as List;

      final data = decoded['data'];
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'] as List;
    }
    return [];
  }

  Map<String, dynamic> _extractMap(dynamic decoded) {
    if (decoded is Map) {
      final res = decoded['result'];
      if (res is Map) {
        if (res['data'] is Map) {
          return Map<String, dynamic>.from(res['data'] as Map);
        }
        return Map<String, dynamic>.from(res);
      }
      final data = decoded['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return Map<String, dynamic>.from(decoded);
    }
    return {};
  }

  /// GET /api/residential-complexes
  Future<List<ResidentialComplex>> getResidentialComplexes() async {
    const path = '/residential-complexes';
    if (kDebugMode) {
      debugPrint('ApiService: getResidentialComplexes - calling GET $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      debugPrint('ApiService: getResidentialComplexes status: ${response.statusCode}');
      debugPrint('ApiService: getResidentialComplexes body: ${response.body}');
    }

    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки ЖК (${response.statusCode}): ${response.body}');
    }

    final decoded = json.decode(response.body);
    final list = _extractList(decoded);

    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ResidentialComplex.fromJson(e))
        .toList();
  }

  /// GET /api/residential-complexes/{id}
  Future<ResidentialComplex> getResidentialComplexById(int id) async {
    final path = '/residential-complexes/$id';
    if (kDebugMode) {
      debugPrint('ApiService: getResidentialComplexById - path: $path');
    }

    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки ЖК #$id (${response.statusCode}): ${response.body}');
    }

    final decoded = json.decode(response.body);
    final map = _extractMap(decoded);

    return ResidentialComplex.fromJson(map);
  }

  /// POST /api/residential-complexes
  Future<ResidentialComplex> createResidentialComplex(Map<String, dynamic> body) async {
    const path = '/residential-complexes';
    if (kDebugMode) {
      debugPrint('ApiService: createResidentialComplex - path: $path, body: $body');
    }

    final response = await _postRequest(path, body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessageFromResponse(response) ?? response.body;
      throw Exception('Ошибка создания ЖК (${response.statusCode}): $msg');
    }

    final decoded = json.decode(response.body);
    final map = _extractMap(decoded);

    return ResidentialComplex.fromJson(map);
  }

  /// PUT /api/residential-complexes/{id}
  Future<ResidentialComplex> updateResidentialComplex(int id, Map<String, dynamic> body) async {
    final path = '/residential-complexes/$id';
    if (kDebugMode) {
      debugPrint('ApiService: updateResidentialComplex - path: $path, body: $body');
    }

    final response = await _putRequest(path, body);
    if (response.statusCode != 200) {
      final msg = _extractErrorMessageFromResponse(response) ?? response.body;
      throw Exception('Ошибка обновления ЖК #$id (${response.statusCode}): $msg');
    }

    final decoded = json.decode(response.body);
    final map = _extractMap(decoded);

    return ResidentialComplex.fromJson(map);
  }

  /// GET /api/buildings
  Future<List<Building>> getBuildings({int? residentialComplexId}) async {
    String path = '/buildings';
    if (residentialComplexId != null) {
      path = '/buildings?residential_complex_id=$residentialComplexId';
    }
    if (kDebugMode) {
      debugPrint('ApiService: getBuildings - path: $path');
    }

    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки корпусов (${response.statusCode}): ${response.body}');
    }

    final decoded = json.decode(response.body);
    final list = _extractList(decoded);

    final all = list
        .whereType<Map<String, dynamic>>()
        .map((e) => Building.fromJson(e))
        .toList();

    if (residentialComplexId != null) {
      final filtered = all
          .where((b) => b.residentialComplexId == null || b.residentialComplexId == residentialComplexId)
          .toList();
      return filtered.isNotEmpty ? filtered : all;
    }

    return all;
  }

  /// GET /api/buildings/{id}
  Future<Building> getBuildingById(int id) async {
    final path = '/buildings/$id';
    if (kDebugMode) {
      debugPrint('ApiService: getBuildingById - path: $path');
    }

    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки корпуса #$id (${response.statusCode}): ${response.body}');
    }

    final decoded = json.decode(response.body);
    final map = _extractMap(decoded);

    return Building.fromJson(map);
  }

  /// POST /api/buildings
  Future<Building> createBuilding(Map<String, dynamic> body) async {
    const path = '/buildings';
    if (kDebugMode) {
      debugPrint('ApiService: createBuilding - path: $path, body: $body');
    }

    var response = await _postRequest(path, body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessageFromResponse(response) ?? response.body;

      // Smart fallback: if type_of_floors failed on string vs array format, retry automatically
      if (msg.contains('type of floors') && (msg.contains('строк') || msg.contains('string')) && body['type_of_floors'] is List) {
        final retryBody = Map<String, dynamic>.from(body);
        retryBody['type_of_floors'] = (body['type_of_floors'] as List).join(', ');
        response = await _postRequest(path, retryBody);
      } else if (msg.contains('type of floors') && (msg.contains('массив') || msg.contains('array')) && body['type_of_floors'] is String) {
        final retryBody = Map<String, dynamic>.from(body);
        retryBody['type_of_floors'] = [(body['type_of_floors'] as String)];
        response = await _postRequest(path, retryBody);
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        final finalMsg = _extractErrorMessageFromResponse(response) ?? response.body;
        throw Exception('Ошибка создания корпуса (${response.statusCode}): $finalMsg');
      }
    }

    final decoded = json.decode(response.body);
    final map = _extractMap(decoded);

    return Building.fromJson(map);
  }

  /// GET /good?building_id={buildingId}
  /// Fetches real apartments/units from the goods catalog belonging to this building
  Future<List<Apartment>> getApartmentsByBuilding({
    required int buildingId,
    int? residentialComplexId,
    String buildingKey = '',
    String buildingName = '',
  }) async {
    String path = '/good?building_id=$buildingId&per_page=500';
    if (residentialComplexId != null) {
      path += '&residential_complex_id=$residentialComplexId';
    }
    if (kDebugMode) {
      debugPrint('ApiService: getApartmentsByBuilding - path: $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      debugPrint('ApiService: getApartmentsByBuilding status: ${response.statusCode}');
      debugPrint('ApiService: getApartmentsByBuilding body: ${response.body}');
    }

    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки квартир корпуса #$buildingId (${response.statusCode}): ${response.body}');
    }

    final decoded = json.decode(response.body);
    final list = _extractList(decoded);

    final apts = list
        .whereType<Map<String, dynamic>>()
        .map((e) => Apartment.fromGood(
              e,
              complexId: residentialComplexId ?? 1,
              buildingKey: buildingKey,
              buildingName: buildingName,
            ))
        .toList();

    _normalizeApartmentPositions(apts);

    return apts;
  }

  /// Normalizes positions on each floor (0..n-1) if not explicitly set by the server
  void _normalizeApartmentPositions(List<Apartment> apts) {
    final Map<String, List<Apartment>> groups = {};
    for (final a in apts) {
      final key = '${a.entrance}_${a.floor}';
      groups.putIfAbsent(key, () => []).add(a);
    }

    for (final entry in groups.entries) {
      final group = entry.value;
      final hasDuplicatePositions = group.length > 1 &&
          (group.every((a) => a.position == 0) ||
              group.map((a) => a.position).toSet().length < group.length);

      if (hasDuplicatePositions) {
        group.sort((a, b) {
          final nA = int.tryParse(a.number.replaceAll(RegExp(r'[^0-9]'), ''));
          final nB = int.tryParse(b.number.replaceAll(RegExp(r'[^0-9]'), ''));
          if (nA != null && nB != null) return nA.compareTo(nB);
          return a.id.compareTo(b.id);
        });

        for (int i = 0; i < group.length; i++) {
          final target = group[i];
          final idx = apts.indexOf(target);
          if (idx != -1) {
            apts[idx] = target.copyWith(position: i);
          }
        }
      }
    }
  }

  /// GET /buildings/{building_id}/entrances
  /// Fetches real entrances for a specific building
  Future<List<Entrance>> getBuildingEntrances(int buildingId) async {
    final path = '/buildings/$buildingId/entrances';
    if (kDebugMode) {
      debugPrint('ApiService: getBuildingEntrances - path: $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      debugPrint('ApiService: getBuildingEntrances status: ${response.statusCode}');
      debugPrint('ApiService: getBuildingEntrances body: ${response.body}');
    }

    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки подъездов корпуса #$buildingId (${response.statusCode}): ${response.body}');
    }

    final decoded = json.decode(response.body);
    final list = _extractList(decoded);

    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Entrance.fromJson(e))
        .toList();
  }

  /// POST /good - creates an apartment good in the CRM matching exact backend schema:
  /// {
  ///   "name": "Квартира № 45, 2-комнатная",
  ///   "building_id": 3,
  ///   "entrance_id": 5,
  ///   "apartment_type": "2-комнатная",
  ///   "type": "apartment",
  ///   "status": "Свободно",
  ///   "floor": 7,
  ///   "total_area": 68.50,
  ///   "price_per_m2": 1200.00,
  ///   "price": 82200.00,
  ///   "description": "...",
  ///   "is_active": true
  /// }
  Future<Apartment> createApartmentGood({
    required int buildingId,
    int? entranceId,
    int entrance = 1,
    required String number,
    required int floor,
    int rooms = 1,
    required double totalArea,
    double? livingArea,
    double? kitchenArea,
    required double totalPrice,
    required double pricePerSqm,
    required String type,
    String? apartmentType,
    required ApartmentStatus status,
    String? description,
    int? residentialComplexId,
    int position = 0,
    String buildingKey = '',
    String buildingName = '',
  }) async {
    final effectiveType = apartmentType ?? type;
    final aptName = 'Квартира № $number, $effectiveType';

    final body = <String, dynamic>{
      'name': aptName,
      'building_id': buildingId,
      if (entranceId != null) 'entrance_id': entranceId,
      'apartment_type': effectiveType,
      'type': 'apartment',
      'status': status.labelRu, // "Свободно", "Бронь", "Продано", "Резерв"
      'floor': floor,
      'total_area': totalArea,
      'price_per_m2': pricePerSqm,
      'price': totalPrice,
      'description': description ?? '$effectiveType с панорамными окнами на $floor этаже.',
      'is_active': true,
      if (residentialComplexId != null) 'residential_complex_id': residentialComplexId,
      'entrance': entrance,
      'rooms': rooms,
      'living_area': livingArea ?? (totalArea * 0.6).roundToDouble(),
      'kitchen_area': kitchenArea ?? 10.0,
      'position': position,
    };

    if (kDebugMode) {
      debugPrint('ApiService: createApartmentGood - body: $body');
    }

    final response = await _postRequest('/good', body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessageFromResponse(response) ?? response.body;
      throw Exception('Ошибка создания квартиры (${response.statusCode}): $msg');
    }

    final decoded = json.decode(response.body);
    final map = _extractMap(decoded);
    return Apartment.fromGood(
      map,
      complexId: residentialComplexId ?? 1,
      buildingKey: buildingKey,
      buildingName: buildingName,
    );
  }

  /// DELETE /good/{id}
  Future<bool> deleteApartmentGood(int goodId) async {
    final path = '/good/$goodId';
    if (kDebugMode) {
      debugPrint('ApiService: deleteApartmentGood - path: $path');
    }

    final response = await _deleteRequest(path);
    return response.statusCode == 200 || response.statusCode == 204;
  }
}


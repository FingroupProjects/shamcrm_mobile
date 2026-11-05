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

  /// POST /api/residential-complexes (Multipart with files, matching tasks pattern)
  Future<ResidentialComplex> createResidentialComplex(
    Map<String, dynamic> body, {
    List<String>? filePaths,
  }) async {
    const path = '/residential-complexes';
    final allFiles = <String>[];
    if (filePaths != null && filePaths.isNotEmpty) {
      allFiles.addAll(filePaths);
    }
    if (body.containsKey('photos') && body['photos'] is List) {
      for (final p in (body['photos'] as List)) {
        if (p is String && p.isNotEmpty) allFiles.add(p);
      }
      body.remove('photos');
    }
    if (body.containsKey('files') && body['files'] is List) {
      for (final f in (body['files'] as List)) {
        if (f is String && f.isNotEmpty) allFiles.add(f);
      }
      body.remove('files');
    }

    if (kDebugMode) {
      debugPrint('ApiService: createResidentialComplex - path: $path, body: $body, files count: ${allFiles.length}');
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final uri = Uri.parse('$baseUrl$updatedPath');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
    });

    body.forEach((key, val) {
      if (val != null) {
        request.fields[key] = val.toString();
      }
    });

    for (final filePath in allFiles) {
      try {
        final f = File(filePath);
        if (f.existsSync()) {
          final fileName = filePath.split(Platform.pathSeparator).last;
          // Send as 'files[]' (tasks format)
          request.files.add(await http.MultipartFile.fromPath(
            'files[]',
            filePath,
            filename: fileName,
          ));
          // Send as 'photos[]' (backend validation format)
          request.files.add(await http.MultipartFile.fromPath(
            'photos[]',
            filePath,
            filename: fileName,
          ));
        }
      } catch (e) {
        debugPrint('Error attaching complex photo file $filePath: $e');
      }
    }

    final response = await _multipartPostRequest('', request);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessageFromResponse(response) ?? response.body;
      throw Exception('Ошибка создания ЖК (${response.statusCode}): $msg');
    }

    final decoded = json.decode(response.body);
    final map = _extractMap(decoded);

    return ResidentialComplex.fromJson(map);
  }

  /// PUT /api/residential-complexes/{id} (Multipart with files)
  Future<ResidentialComplex> updateResidentialComplex(
    int id,
    Map<String, dynamic> body, {
    List<String>? filePaths,
  }) async {
    final path = '/residential-complexes/$id';
    final allFiles = <String>[];
    if (filePaths != null && filePaths.isNotEmpty) {
      allFiles.addAll(filePaths);
    }
    if (body.containsKey('photos') && body['photos'] is List) {
      for (final p in (body['photos'] as List)) {
        if (p is String && p.isNotEmpty) allFiles.add(p);
      }
      body.remove('photos');
    }
    if (body.containsKey('files') && body['files'] is List) {
      for (final f in (body['files'] as List)) {
        if (f is String && f.isNotEmpty) allFiles.add(f);
      }
      body.remove('files');
    }

    if (kDebugMode) {
      debugPrint('ApiService: updateResidentialComplex - path: $path, body: $body, files count: ${allFiles.length}');
    }

    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final uri = Uri.parse('$baseUrl$updatedPath');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
    });
    request.fields['_method'] = 'PUT';

    body.forEach((key, val) {
      if (val != null) {
        request.fields[key] = val.toString();
      }
    });

    for (final filePath in allFiles) {
      try {
        final f = File(filePath);
        if (f.existsSync()) {
          final fileName = filePath.split(Platform.pathSeparator).last;
          request.files.add(await http.MultipartFile.fromPath(
            'files[]',
            filePath,
            filename: fileName,
          ));
          request.files.add(await http.MultipartFile.fromPath(
            'photos[]',
            filePath,
            filename: fileName,
          ));
        }
      } catch (e) {
        debugPrint('Error attaching complex photo file $filePath: $e');
      }
    }

    final response = await _multipartPostRequest('', request);
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

  bool _isParkingGood(Map<String, dynamic> json) {
    final data = json['good'] is Map ? Map<String, dynamic>.from(json['good'] as Map) : json;
    final type = (data['type'] ?? json['type'] ?? '').toString().toLowerCase();
    final parkingType = (data['parking_type'] ?? json['parking_type'] ?? '').toString();
    return type.contains('парков') || parkingType.trim().isNotEmpty;
  }

  /// GET /good?building_id={buildingId}
  /// Apartments stay on the chess grid. Goods with type "парковочное место" go to parking.
  Future<BuildingGoods> getBuildingGoods({
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

    final apartments = <Apartment>[];
    final parking = <ParkingSpot>[];
    for (final item in list.whereType<Map<String, dynamic>>()) {
      if (_isParkingGood(item)) {
        parking.add(ParkingSpot.fromGood(
          item,
          complexId: residentialComplexId ?? 1,
          buildingId: buildingId,
          buildingKey: buildingKey,
        ));
      } else {
        apartments.add(Apartment.fromGood(
          item,
          complexId: residentialComplexId ?? 1,
          buildingKey: buildingKey,
          buildingName: buildingName,
        ));
      }
    }

    return BuildingGoods(
      apartments: Apartment.normalizePositions(apartments),
      parking: parking,
    );
  }

  /// GET /good?building_id={buildingId}
  Future<List<Apartment>> getApartmentsByBuilding({
    required int buildingId,
    int? residentialComplexId,
    String buildingKey = '',
    String buildingName = '',
  }) async {
    final goods = await getBuildingGoods(
      buildingId: buildingId,
      residentialComplexId: residentialComplexId,
      buildingKey: buildingKey,
      buildingName: buildingName,
    );
    return goods.apartments;
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

  /// POST /good for a parking spot.
  /// {
  ///   "name": "П-01",
  ///   "type": "парковочное место",
  ///   "parking_type": "подземная",
  ///   "building_id": 1,
  ///   "price": 5000,
  ///   "total_area": 15,
  ///   "status": "свободно"
  /// }
  Future<ParkingSpot> createParkingGood({
    required int buildingId,
    required String name,
    required String parkingType,
    required double price,
    required double totalArea,
    required ApartmentStatus status,
    int complexId = 1,
    String buildingKey = '',
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'type': 'парковочное место',
      'parking_type': _parkingTypeValue(parkingType),
      'building_id': buildingId,
      'price': price,
      'total_area': totalArea,
      'status': _parkingStatusValue(status),
    };

    final response = await _postRequest('/good', body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessageFromResponse(response) ?? response.body;
      throw Exception('Ошибка создания парковки (${response.statusCode}): $msg');
    }

    final decoded = response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
    final map = _extractMap(decoded);
    if (map.isEmpty) {
      return ParkingSpot(
        id: 0,
        complexId: complexId,
        buildingId: buildingId,
        number: name,
        type: parkingType,
        buildingKey: buildingKey,
        price: price,
        area: totalArea,
        status: status,
      );
    }
    return ParkingSpot.fromGood(
      map,
      complexId: complexId,
      buildingId: buildingId,
      buildingKey: buildingKey,
    );
  }

  String _parkingTypeValue(String type) {
    final value = type.trim().toLowerCase();
    if (value.contains('открыт')) return 'открытая';
    if (value.contains('закрыт') || value.contains('крыт')) return 'закрытая';
    return 'подземная';
  }

  String _parkingStatusValue(ApartmentStatus status) {
    switch (status) {
      case ApartmentStatus.available:
        return 'свободно';
      case ApartmentStatus.booked:
        return 'бронь';
      case ApartmentStatus.sold:
        return 'продано';
      case ApartmentStatus.reserved:
        return 'резерв';
    }
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

  /// POST /order for a chess-grid apartment deal.
  /// Field names match the backend contract. status_id, organization_id and
  /// deliveryType stay because the existing order endpoint still requires them.
  Future<Map<String, dynamic>> createResidentialOrder({
    required int leadId,
    required int managerId,
    required int orderStatusId,
    required int integrationId,
    required String phone,
    required double sum,
    required int currencyId,
    required String ownerName,
    required String gender,
    required String passport,
    String? passportIssuedBy,
    String? passportIssuedAt,
    String? passportExpiresAt,
    String? ownerBirthDate,
    int? inn,
    String? residenceAddress,
    required int goodId,
    required int variantId,
    required double pricePerM2,
    required String dealType,
    double? downPayment,
    int? installmentMonths,
  }) async {
    final organizationId = await resolveSelectedOrganizationId();
    final body = <String, dynamic>{
      'lead_id': leadId,
      'manager_id': managerId,
      'order_status_id': orderStatusId,
      'status_id': orderStatusId,
      'integration_id': integrationId,
      'phone': phone,
      'sum': sum,
      'currency_id': currencyId,
      'owner_name': ownerName,
      'gender': gender,
      'passport': passport,
      'goods': [
        {
          'good_id': goodId,
          'variant_id': variantId,
          'quantity': 1,
          'price': sum,
        },
      ],
      'price_per_m2': pricePerM2,
      'deal_type': dealType,
      'organization_id': organizationId,
      'deliveryType': 'pickup',
    };

    if (passportIssuedBy != null && passportIssuedBy.trim().isNotEmpty) {
      body['passport_issued_by'] = passportIssuedBy.trim();
    }
    if (passportIssuedAt != null && passportIssuedAt.isNotEmpty) {
      body['passport_issued_at'] = passportIssuedAt;
    }
    if (passportExpiresAt != null && passportExpiresAt.isNotEmpty) {
      body['passport_expires_at'] = passportExpiresAt;
    }
    if (ownerBirthDate != null && ownerBirthDate.isNotEmpty) {
      body['owner_birth_date'] = ownerBirthDate;
    }
    if (inn != null) {
      body['inn'] = inn;
    }
    if (residenceAddress != null && residenceAddress.trim().isNotEmpty) {
      body['residence_address'] = residenceAddress.trim();
    }
    if (dealType == 'installment' || dealType == 'mixed') {
      body['down_payment'] = downPayment ?? 0;
      body['installment_months'] = installmentMonths ?? 0;
    }

    final response = await _postRequest('/order', body);
    final decoded = response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
    if (<int>[200, 201, 202, 203, 204].contains(response.statusCode)) {
      String? orderId;
      if (decoded is Map) {
        final result = decoded['result'];
        if (result is Map && result['id'] != null) {
          orderId = result['id'].toString();
        } else if (decoded['id'] != null) {
          orderId = decoded['id'].toString();
        }
      }
      return {'success': true, 'orderId': orderId};
    }

    return {
      'success': false,
      'error': _orderErrorText(decoded) ?? 'Не удалось создать заказ (${response.statusCode})',
    };
  }

  String? _orderErrorText(dynamic decoded) {
    if (decoded is! Map) return null;
    final message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    if (message is Map) {
      for (final value in message.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    final errors = decoded['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    return null;
  }
}


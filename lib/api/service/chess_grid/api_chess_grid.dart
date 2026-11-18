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
    final remotePhotos = <String>[];
    if (filePaths != null && filePaths.isNotEmpty) {
      for (final p in filePaths) {
        if (p.startsWith('http://') || p.startsWith('https://')) {
          remotePhotos.add(p);
        } else {
          allFiles.add(p);
        }
      }
    }
    if (body.containsKey('photos') && body['photos'] is List) {
      for (final p in (body['photos'] as List)) {
        if (p is String && p.isNotEmpty) {
          if (p.startsWith('http://') || p.startsWith('https://')) {
            remotePhotos.add(p);
          } else {
            allFiles.add(p);
          }
        }
      }
      body.remove('photos');
    }
    if (body.containsKey('files') && body['files'] is List) {
      for (final f in (body['files'] as List)) {
        if (f is String && f.isNotEmpty) {
          if (f.startsWith('http://') || f.startsWith('https://')) {
            remotePhotos.add(f);
          } else {
            allFiles.add(f);
          }
        }
      }
      body.remove('files');
    }

    if (remotePhotos.isNotEmpty) {
      body['photos'] = json.encode(remotePhotos);
      body['photo'] = remotePhotos.first;
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
          // Also attach single-file fields commonly expected by Laravel/PHP controllers:
          if (request.files.where((mf) => mf.field == 'photo').isEmpty) {
            request.files.add(await http.MultipartFile.fromPath(
              'photo',
              filePath,
              filename: fileName,
            ));
          }
          if (request.files.where((mf) => mf.field == 'image').isEmpty) {
            request.files.add(await http.MultipartFile.fromPath(
              'image',
              filePath,
              filename: fileName,
            ));
          }
          if (request.files.where((mf) => mf.field == 'file').isEmpty) {
            request.files.add(await http.MultipartFile.fromPath(
              'file',
              filePath,
              filename: fileName,
            ));
          }
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
    final remotePhotos = <String>[];
    if (filePaths != null && filePaths.isNotEmpty) {
      for (final p in filePaths) {
        if (p.startsWith('http://') || p.startsWith('https://')) {
          remotePhotos.add(p);
        } else {
          allFiles.add(p);
        }
      }
    }
    if (body.containsKey('photos') && body['photos'] is List) {
      for (final p in (body['photos'] as List)) {
        if (p is String && p.isNotEmpty) {
          if (p.startsWith('http://') || p.startsWith('https://')) {
            remotePhotos.add(p);
          } else {
            allFiles.add(p);
          }
        }
      }
      body.remove('photos');
    }
    if (body.containsKey('files') && body['files'] is List) {
      for (final f in (body['files'] as List)) {
        if (f is String && f.isNotEmpty) {
          if (f.startsWith('http://') || f.startsWith('https://')) {
            remotePhotos.add(f);
          } else {
            allFiles.add(f);
          }
        }
      }
      body.remove('files');
    }

    if (remotePhotos.isNotEmpty) {
      body['photos'] = json.encode(remotePhotos);
      body['photo'] = remotePhotos.first;
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
          if (request.files.where((mf) => mf.field == 'photo').isEmpty) {
            request.files.add(await http.MultipartFile.fromPath(
              'photo',
              filePath,
              filename: fileName,
            ));
          }
          if (request.files.where((mf) => mf.field == 'image').isEmpty) {
            request.files.add(await http.MultipartFile.fromPath(
              'image',
              filePath,
              filename: fileName,
            ));
          }
          if (request.files.where((mf) => mf.field == 'file').isEmpty) {
            request.files.add(await http.MultipartFile.fromPath(
              'file',
              filePath,
              filename: fileName,
            ));
          }
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
    final rawType = (apartmentType ?? type).trim();
    final effectiveType = rawType.isEmpty || Apartment.isStudioLabel(rawType)
        ? (rooms > 0 ? '$rooms-комнатная' : '')
        : rawType;
    final aptName = 'Квартира № $number';

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

  /// GET /good/{id}
  Future<Map<String, dynamic>> getGoodById(int goodId) async {
    final path = await _appendQueryParams('/good/$goodId');
    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить квартиру');
    }
    final decoded = response.body.isNotEmpty ? json.decode(response.body) : null;
    if (decoded is Map && decoded['result'] is Map) {
      return Map<String, dynamic>.from(decoded['result'] as Map);
    }
    if (decoded is Map && decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data'] as Map);
    }
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw Exception('Неверный ответ сервера');
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
    int? variantId,
    required double pricePerM2,
    double? totalArea,
    required String dealType,
    double? downPayment,
    int? installmentMonths,
    String? firstPaymentDate,
    double? barterAmount,
    String? barterNote,
    List<Map<String, dynamic>>? orderCustomFields,
    List<Map<String, int>>? directoryValues,
    List<String>? filePaths,
  }) async {
    final organizationId = await resolveSelectedOrganizationId();
    final resolvedVariantId = await _resolveOrderVariantId(goodId: goodId, variantId: variantId);
    if (resolvedVariantId == null) {
      return {
        'success': false,
        'error': 'У квартиры нет варианта. Id товара в variant_id отправлять нельзя.',
      };
    }
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
          'variant_id': resolvedVariantId,
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
    if (totalArea != null && totalArea > 0) {
      body['total_area'] = totalArea;
    }
    if (dealType == 'installment' || dealType == 'mixed') {
      if (barterAmount != null && barterAmount > 0) {
        body['barter_amount'] = barterAmount;
      }
      if (barterNote != null && barterNote.trim().isNotEmpty) {
        body['barter_note'] = barterNote.trim();
      }
      if (downPayment != null) {
        body['down_payment'] = downPayment;
      }
      final months = installmentMonths ?? 0;
      if (months > 0) {
        body['installment_months'] = months;
        if (firstPaymentDate != null && firstPaymentDate.isNotEmpty) {
          body['first_payment_date'] = firstPaymentDate;
        }
      }
    }
    if (orderCustomFields != null && orderCustomFields.isNotEmpty) {
      body['order_custom_fields'] = orderCustomFields;
    }
    if (directoryValues != null && directoryValues.isNotEmpty) {
      body['directory_values'] = directoryValues;
    }

    final localFiles = (filePaths ?? const <String>[])
        .where((path) => path.isNotEmpty && !path.startsWith('http'))
        .toList();
    final response = localFiles.isEmpty
        ? await _postRequest('/order', body)
        : await _postResidentialOrderWithFiles('/order', body, localFiles);
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

  Future<int?> _resolveOrderVariantId({required int goodId, int? variantId}) async {
    if (variantId != null && variantId > 0 && variantId != goodId) return variantId;

    int? fromVariants(dynamic raw) {
      if (raw is! List) return null;
      for (final item in raw) {
        if (item is! Map) continue;
        final id = int.tryParse('${item['id']}') ?? 0;
        if (id > 0 && id != goodId) return id;
      }
      return null;
    }

    try {
      final raw = await getGoodById(goodId);
      final nested = raw['good'] is Map ? raw['good'] as Map : raw;
      final id = fromVariants(nested['variants']) ?? int.tryParse('${nested['variant_id']}') ?? 0;
      if (id > 0 && id != goodId) return id;
    } catch (_) {}

    return null;
  }

  Future<http.Response> _postResidentialOrderWithFiles(
    String path,
    Map<String, dynamic> body,
    List<String> filePaths,
  ) async {
    if (baseUrl == null || baseUrl!.isEmpty) {
      await _initializeIfDomainExists();
    }
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('Адрес сервера не задан');
    }
    final token = await getToken();
    final updatedPath = await _appendQueryParams(path);
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$updatedPath'));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
    });

    void writeField(String key, dynamic value) {
      if (value == null) return;
      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          writeField('$key[$i]', value[i]);
        }
        return;
      }
      if (value is Map) {
        value.forEach((nestedKey, nestedValue) {
          writeField('$key[$nestedKey]', nestedValue);
        });
        return;
      }
      request.fields[key] = value.toString();
    }

    body.forEach(writeField);
    for (final filePath in filePaths) {
      final file = File(filePath);
      if (!file.existsSync()) continue;
      request.files.add(await http.MultipartFile.fromPath(
        'files[]',
        filePath,
        filename: filePath.split(Platform.pathSeparator).last,
      ));
    }

    return _multipartPostRequest('', request);
  }

  Future<Map<String, dynamic>> updateResidentialOrder({
    required int orderId,
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
    int? variantId,
    required double pricePerM2,
    double? totalArea,
    required String dealType,
    double? downPayment,
    int? installmentMonths,
    String? firstPaymentDate,
    double? barterAmount,
    String? barterNote,
  }) async {
    final organizationId = await resolveSelectedOrganizationId();
    final resolvedVariantId = await _resolveOrderVariantId(goodId: goodId, variantId: variantId);
    if (resolvedVariantId == null) {
      return {
        'success': false,
        'error': 'У квартиры нет варианта. Id товара в variant_id отправлять нельзя.',
      };
    }
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
          'variant_id': resolvedVariantId,
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
    if (totalArea != null && totalArea > 0) {
      body['total_area'] = totalArea;
    }
    if (dealType == 'installment' || dealType == 'mixed') {
      if (barterAmount != null && barterAmount > 0) {
        body['barter_amount'] = barterAmount;
      }
      if (barterNote != null && barterNote.trim().isNotEmpty) {
        body['barter_note'] = barterNote.trim();
      }
      if (downPayment != null) {
        body['down_payment'] = downPayment;
      }
      final months = installmentMonths ?? 0;
      if (months > 0) {
        body['installment_months'] = months;
        if (firstPaymentDate != null && firstPaymentDate.isNotEmpty) {
          body['first_payment_date'] = firstPaymentDate;
        }
      }
    }

    final response = await _postRequest('/order/$orderId', body);
    final decoded = response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
    if (<int>[200, 201, 202, 203, 204].contains(response.statusCode)) {
      return {'success': true};
    }

    return {
      'success': false,
      'error': _orderErrorText(decoded) ?? 'Не удалось обновить заказ (${response.statusCode})',
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

  dynamic _apiResult(dynamic decoded) {
    if (decoded is Map && decoded.containsKey('result')) return decoded['result'];
    if (decoded is Map && decoded.containsKey('data')) return decoded['data'];
    return decoded;
  }

  List<Map<String, dynamic>> _apiMapList(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    }
    if (value is Map) {
      for (final key in ['data', 'result', 'items', 'templates', 'contracts']) {
        if (value[key] is List) return _apiMapList(value[key]);
      }
    }
    return [];
  }

  Map<String, dynamic> _apiMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  Never _throwApi(http.Response response, String fallback) {
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? json.decode(response.body) : null;
    } catch (_) {}
    throw Exception(_orderErrorText(decoded) ?? '$fallback (${response.statusCode})');
  }

  Future<List<Map<String, dynamic>>> getOrderContracts(int orderId) async {
    final response = await _getRequest('/order/$orderId/contracts');
    if (response.statusCode != 200) _throwApi(response, 'Не удалось загрузить договоры');
    final decoded = json.decode(response.body);
    return _apiMapList(_apiResult(decoded));
  }

  Future<List<Map<String, dynamic>>> getContractTemplates(int organizationId) async {
    final response = await _getRequest('/contract-templates?organization_id=$organizationId');
    if (response.statusCode != 200) _throwApi(response, 'Не удалось загрузить шаблоны');
    return _apiMapList(_apiResult(json.decode(response.body)))
        .where((item) => item['is_active'] != false && item['is_active'] != 0 && item['is_active'] != '0')
        .toList();
  }

  Future<Map<String, dynamic>> getContractRequisites(int organizationId) async {
    final response = await _getRequest('/contract-requisites?organization_id=$organizationId');
    if (response.statusCode != 200) return {};
    return _apiMap(_apiResult(json.decode(response.body)));
  }

  Future<Map<String, dynamic>> getOrderContract({
    required int orderId,
    required int contractId,
  }) async {
    final response = await _getRequest('/order/$orderId/contracts/$contractId');
    if (response.statusCode != 200) _throwApi(response, 'Не удалось открыть договор');
    return _apiMap(_apiResult(json.decode(response.body)));
  }

  Future<List<Map<String, dynamic>>> getContractDocumentTypes() async {
    final response = await _getRequest('/contract-document-types');
    if (response.statusCode != 200) _throwApi(response, 'Не удалось загрузить типы документов');
    return _apiMapList(_apiResult(json.decode(response.body)));
  }

  Future<Map<String, dynamic>> previewOrderContract({
    required int orderId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _postRequest('/order/$orderId/contracts/preview', body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось построить предпросмотр');
    }
    return _apiMap(_apiResult(json.decode(response.body)));
  }

  Future<Map<String, dynamic>> createOrderContract({
    required int orderId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _postRequest('/order/$orderId/contracts', body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось создать договор');
    }
    return _apiMap(_apiResult(json.decode(response.body)));
  }

  Future<Map<String, dynamic>> generateOrderContract({
    required int orderId,
    required int contractId,
  }) async {
    final response = await _postRequest('/order/$orderId/contracts/$contractId/generate', {});
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось сформировать договор');
    }
    return _apiMap(_apiResult(json.decode(response.body)));
  }

  Future<Map<String, dynamic>> createOrderContractVersion({
    required int orderId,
    required int contractId,
  }) async {
    final response = await _postRequest('/order/$orderId/contracts/$contractId/versions', {});
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось создать версию');
    }
    return _apiMap(_apiResult(json.decode(response.body)));
  }

  Future<void> deleteOrderContract({
    required int orderId,
    required int contractId,
  }) async {
    final response = await _deleteRequest('/order/$orderId/contracts/$contractId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      _throwApi(response, 'Не удалось удалить договор');
    }
  }

  Future<Map<String, dynamic>> uploadOrderContract({
    required int orderId,
    required int organizationId,
    required String documentType,
    required String title,
    required String filePath,
    String? number,
    String? contractDate,
    String? notes,
    int? relatedContractId,
  }) async {
    if (baseUrl == null) {
      await _initializeIfDomainExists();
    }
    final path = await _appendQueryParams('/order/$orderId/contracts/upload');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    request.fields['organization_id'] = organizationId.toString();
    request.fields['document_type'] = documentType;
    request.fields['title'] = title;
    if (number != null && number.trim().isNotEmpty) request.fields['number'] = number.trim();
    if (contractDate != null && contractDate.isNotEmpty) request.fields['contract_date'] = contractDate;
    if (notes != null && notes.trim().isNotEmpty) request.fields['notes'] = notes.trim();
    if (relatedContractId != null) request.fields['related_contract_id'] = relatedContractId.toString();
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await _multipartPostRequest('', request);
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось загрузить договор');
    }
    final decoded = response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
    return _apiMap(_apiResult(decoded));
  }

  Future<Map<String, dynamic>> changeOrderContractStatus({
    required int orderId,
    required int contractId,
    required String status,
    String? signedAt,
    String? scanPath,
  }) async {
    if (scanPath == null || scanPath.isEmpty) {
      final body = <String, dynamic>{'status': status};
      if (signedAt != null && signedAt.isNotEmpty) body['signed_at'] = signedAt;
      final response = await _postRequest('/order/$orderId/contracts/$contractId/status', body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        _throwApi(response, 'Не удалось сменить статус');
      }
      return _apiMap(_apiResult(json.decode(response.body)));
    }

    if (baseUrl == null) await _initializeIfDomainExists();
    final path = await _appendQueryParams('/order/$orderId/contracts/$contractId/status');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    request.fields['status'] = status;
    if (signedAt != null && signedAt.isNotEmpty) request.fields['signed_at'] = signedAt;
    request.files.add(await http.MultipartFile.fromPath('file', scanPath));
    final response = await _multipartPostRequest('', request);
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось подписать договор');
    }
    final decoded = response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
    return _apiMap(_apiResult(decoded));
  }

  Future<List<int>> downloadOrderContractBytes({
    required int orderId,
    required int contractId,
    bool scan = false,
  }) async {
    final suffix = scan ? '?kind=scan' : '';
    final response = await _getRequest('/order/$orderId/contracts/$contractId/file$suffix');
    if (response.statusCode != 200) _throwApi(response, 'Не удалось скачать файл');
    return response.bodyBytes;
  }

  Future<List<Map<String, dynamic>>> getOrderInstallments() async {
    final response = await _getRequest('/order/installments');
    if (response.statusCode != 200) {
      _throwApi(response, 'Не удалось загрузить платежи');
    }
    final decoded = response.body.isNotEmpty ? json.decode(response.body) : null;
    final items = _apiMapList(_apiResult(decoded));
    await _fillInstallmentBuyerNames(items);
    return items;
  }

  Future<void> _fillInstallmentBuyerNames(List<Map<String, dynamic>> items) async {
    final missingLeadIds = <int>{};
    for (final item in items) {
      final buyer = item['buyer']?.toString().trim() ?? '';
      if (buyer.isNotEmpty && buyer != 'null') continue;
      final leadId = int.tryParse(item['lead_id']?.toString() ?? '');
      if (leadId != null && leadId > 0) missingLeadIds.add(leadId);
    }
    if (missingLeadIds.isEmpty) return;

    final names = <int, String>{};
    await Future.wait(missingLeadIds.map((leadId) async {
      try {
        final response = await fetchLeadByIdResponse(leadId);
        if (response.statusCode != 200 || response.body.isEmpty) return;
        final decoded = json.decode(response.body);
        final result = decoded is Map ? decoded['result'] : null;
        if (result is! Map) return;
        final name = result['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) names[leadId] = name;
      } catch (_) {}
    }));

    for (final item in items) {
      final buyer = item['buyer']?.toString().trim() ?? '';
      if (buyer.isNotEmpty && buyer != 'null') continue;
      final leadId = int.tryParse(item['lead_id']?.toString() ?? '');
      final name = leadId == null ? null : names[leadId];
      if (name != null) item['buyer'] = name;
    }
  }

  Future<Map<String, dynamic>?> getOrderInstallment(int orderId) async {
    final response = await _getRequest('/order/$orderId/installment');
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) _throwApi(response, 'Не удалось загрузить рассрочку');
    final result = _apiResult(json.decode(response.body));
    if (result == null) return null;
    final map = _apiMap(result);
    if (map.isEmpty) return null;
    return map;
  }

  Future<Map<String, dynamic>> createInstallmentPayment({
    required int orderId,
    required Map<String, dynamic> body,
    List<String> filePaths = const [],
  }) async {
    final localFiles = filePaths.where((path) => path.isNotEmpty && !path.startsWith('http')).toList();
    if (localFiles.isNotEmpty) {
      if (baseUrl == null) await _initializeIfDomainExists();
      final path = await _appendQueryParams('/order/$orderId/installment/payments');
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
      body.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      for (final filePath in localFiles) {
        request.files.add(await http.MultipartFile.fromPath('files[]', filePath));
      }
      final response = await _multipartPostRequest('', request);
      if (response.statusCode != 200 && response.statusCode != 201) {
        _throwApi(response, 'Не удалось записать поступление');
      }
      final decoded = response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
      return _apiMap(_apiResult(decoded));
    }
    final response = await _postRequest('/order/$orderId/installment/payments', body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось записать поступление');
    }
    return _apiMap(_apiResult(json.decode(response.body)));
  }

  Future<Map<String, dynamic>> confirmInstallmentPayment({
    required int orderId,
    required int paymentId,
    required List<Map<String, dynamic>> allocations,
  }) async {
    final response = await _postRequest(
      '/order/$orderId/installment/payments/$paymentId/confirm',
      {'allocations': allocations},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось подтвердить платёж');
    }
    return _apiMap(_apiResult(json.decode(response.body)));
  }

  Future<void> reverseInstallmentPayment({
    required int orderId,
    required int paymentId,
    required String reason,
  }) async {
    final response = await _postRequest(
      '/order/$orderId/installment/payments/$paymentId/reverse',
      {'reason': reason},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось отменить платёж');
    }
  }

  Future<void> refundInstallmentPayment({
    required int orderId,
    required int paymentId,
    required double amount,
    required String reason,
  }) async {
    final response = await _postRequest(
      '/order/$orderId/installment/payments/$paymentId/refund',
      {'amount': amount, 'reason': reason},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось оформить возврат');
    }
  }

  Future<OrderPaymentsResponse> getOrderPayments({
    int page = 1,
    int perPage = 50,
    String? search,
    String? dateFrom,
    String? dateTo,
    String? status,
  }) async {
    var path = '/order/payments?page=$page&per_page=$perPage';
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      path += '&date_from=${Uri.encodeComponent(dateFrom)}';
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      path += '&date_to=${Uri.encodeComponent(dateTo)}';
    }
    if (status != null && status.isNotEmpty) {
      path += '&status=${Uri.encodeComponent(status)}';
    }
    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      _throwApi(response, 'Не удалось загрузить платежи');
    }
    final decoded = json.decode(response.body);
    return OrderPaymentsResponse.fromJson(decoded is Map<String, dynamic> ? decoded : {});
  }

  Future<void> deleteOrderPayment({
    required int orderId,
    required int paymentId,
  }) async {
    http.Response response;
    try {
      response = await _deleteRequest('/order/$orderId/installment/payments/$paymentId');
    } catch (_) {
      response = await _deleteRequest('/order/payments/$paymentId');
    }
    if (response.statusCode != 200 && response.statusCode != 204) {
      response = await _deleteRequest('/order/payments/$paymentId');
    }
    if (response.statusCode != 200 && response.statusCode != 204) {
      _throwApi(response, 'Не удалось удалить платёж');
    }
  }

  Future<Map<String, dynamic>> updateOrderPayment({
    required int orderId,
    required int paymentId,
    required Map<String, dynamic> body,
    List<String> filePaths = const [],
  }) async {
    final localFiles = filePaths.where((path) => path.isNotEmpty && !path.startsWith('http')).toList();
    if (localFiles.isNotEmpty) {
      if (baseUrl == null) await _initializeIfDomainExists();
      final path = await _appendQueryParams('/order/$orderId/installment/payments/$paymentId');
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
      body.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      for (final filePath in localFiles) {
        request.files.add(await http.MultipartFile.fromPath('files[]', filePath));
      }
      final response = await _multipartPostRequest('', request);
      if (response.statusCode != 200 && response.statusCode != 201) {
        _throwApi(response, 'Не удалось обновить платёж');
      }
      final decoded = response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
      return _apiMap(_apiResult(decoded));
    }
    final response = await _postRequest('/order/$orderId/installment/payments/$paymentId', body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwApi(response, 'Не удалось обновить платёж');
    }
    return _apiMap(_apiResult(json.decode(response.body)));
  }
}


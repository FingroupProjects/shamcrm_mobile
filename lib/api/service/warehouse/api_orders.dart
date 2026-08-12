part of '../api_service.dart';

extension ApiWarehouseOrdersX on ApiService {
  Future<List<PriceType>> getPriceType() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/priceType');
    if (kDebugMode) {
      //debugPrint('ApiService: getPriceType - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['result']['data'];
      return (data as List)
          .map((priceType) => PriceType.fromJson(priceType))
          .toList();
    } else {
      throw Exception('Ошибка загрузки типов цен');
    }
  }

  Future<Map<String, dynamic>> deleteOrderFile(int fileId) async {
    final path = await _appendQueryParams('/order/deleteFile/$fileId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteOrderFile - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete order file!');
    }
  }

  Future<List<OrderInternetStore>> getOrderInternetStores() async {
    var path = '/integrations?type=mini_app_telegram_bot';
    path = await _appendQueryParams(path);

    if (kDebugMode) {
      debugPrint('ApiService: getOrderInternetStores - Generated path: $path');
    }

    final response = await _getRequest(path);
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки интернет магазинов');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final result = data['result'];
    final rawList = <dynamic>[];

    if (result is List) {
      rawList.addAll(result);
    } else if (result is Map<String, dynamic>) {
      if (result['data'] is List) {
        rawList.addAll(result['data'] as List<dynamic>);
      } else if (result['integrations'] is List) {
        rawList.addAll(result['integrations'] as List<dynamic>);
      }
    }

    if (kDebugMode) {
      debugPrint(
          'ApiService: getOrderInternetStores - parsed items count: ${rawList.length}');
      if (rawList.isEmpty) {
        debugPrint(
            'ApiService: getOrderInternetStores - empty body: ${response.body}');
      }
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(OrderInternetStore.fromJson)
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
  }

  Future<VariantResponse> getVariants({
    int page = 1,
    int perPage = 15,
    String? search,
    Map<String, dynamic>? filters,
    bool? isService,
  }) async {
    String path = '/good/get/variant?page=$page&per_page=$perPage';

    if (isService != null) {
      path += '&is_service=${isService ? 1 : 0}';
    }

    if (search != null && search.isNotEmpty) {
      path += '&search=$search&barcode=$search';
    }

    if (filters != null) {
      // Добавляем counterparty_id
      if (filters.containsKey('counterparty_id')) {
        path += '&counterparty_id=${filters['counterparty_id']}';
      }

      // Добавляем storage_id
      if (filters.containsKey('storage_id')) {
        path += '&storage_id=${filters['storage_id']}';
      }

      if (filters.containsKey('category_id')) {
        final categoryId = filters['category_id'];
        if (categoryId is int) {
          path += '&category_id=$categoryId';
        }
      }

      if (filters.containsKey('is_active')) {
        path += '&is_active=${filters['is_active'] ? 1 : 0}';
      }
    }

    path = await _appendQueryParams(path);

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        return VariantResponse.fromJson(data['result'] as Map<String, dynamic>);
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception('Ошибка загрузки вариантов: ${response.statusCode}');
    }
  }

  Future<List<Label>> getLabels() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/label');
    if (kDebugMode) {
      //debugPrint('ApiService: getLabels - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((label) => Label.fromJson(label))
            .toList();
      } else {
        throw Exception('Ошибка: поле "result" отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка загрузки меток');
    }
  }

  Future<List<OrderStatus>> getOrderStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order-status');
    if (kDebugMode) {
      //debugPrint('ApiService: getOrderStatuses - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          await prefs.setString(
              'cachedOrderStatuses_${await getSelectedOrganization()}',
              json.encode(data['result']));
          return (data['result'] as List)
              .map((status) => OrderStatus.fromJson(status))
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка сервера');
      }
    } catch (e) {
      ////debugPrint(
      // 'Ошибка загрузки статусов заказов. Используем кэшированные данные.');
      final cachedStatuses = prefs
          .getString('cachedOrderStatuses_${await getSelectedOrganization()}');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        return (decodedData as List)
            .map((status) => OrderStatus.fromJson(status))
            .toList();
      } else {
        throw Exception(
            'Ошибка загрузки статусов заказов и нет кэшированных данных!');
      }
    }
  }

  Future<OrderResponse> getOrders({
    int page = 1,
    int perPage = 20,
    int? statusId,
    String? query,
    List<String>? managerIds,
    List<String>? regionsIds,
    List<String>? leadIds,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? paymentMethod,
    String? deliveryType,
    List<int>? reasonForRefusalIds,
    Map<String, List<String>>? customFieldFilters,
  }) async {
    String url = '/order';
    url += '?page=$page&per_page=$perPage';
    if (statusId != null) {
      url += '&order_status_id=$statusId';
    }
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (managerIds != null && managerIds.isNotEmpty) {
      for (int i = 0; i < managerIds.length; i++) {
        url += '&managers[$i]=${managerIds[i]}';
      }
    }
    if (regionsIds != null && regionsIds.isNotEmpty) {
      for (int i = 0; i < regionsIds.length; i++) {
        url += '&regions[$i]=${regionsIds[i]}';
      }
    }
    if (leadIds != null && leadIds.isNotEmpty) {
      for (int i = 0; i < leadIds.length; i++) {
        url += '&leads[$i]=${leadIds[i]}';
      }
    }
    if (fromDate != null) {
      url += '&from=${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      url += '&to=${toDate.toIso8601String()}';
    }
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      url += '&payment_type=$paymentMethod';
    }
    if (deliveryType != null && deliveryType.isNotEmpty) {
      url += '&delivery_type=${Uri.encodeComponent(deliveryType)}';
    }
    if (reasonForRefusalIds != null && reasonForRefusalIds.isNotEmpty) {
      for (int i = 0; i < reasonForRefusalIds.length; i++) {
        url += '&reason_for_refusals[$i]=${reasonForRefusalIds[i]}';
      }
    }
    if (customFieldFilters != null && customFieldFilters.isNotEmpty) {
      var index = 0;
      customFieldFilters.forEach((fieldKey, values) {
        if (values.isEmpty) return;
        final encodedKey = Uri.encodeComponent(fieldKey);
        url += '&custom_fields[$index][key]=$encodedKey';
        for (int i = 0; i < values.length; i++) {
          final encodedValue = Uri.encodeComponent(values[i]);
          url += '&custom_fields[$index][value][$i]=$encodedValue';
        }
        index++;
      });
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      //debugPrint('ApiService: getOrders - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        final data = rawData['result'];
        return OrderResponse.fromJson(data);
      } else {
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<List<String>> getOrderCustomFields() async {
    final path = await _appendQueryParams('/field-position?table=orders');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List<dynamic>?;
      return resultList
              ?.where((e) =>
                  (e['is_custom_field'] == true || e['is_custom_field'] == 1) &&
                  (e['field_name']?.toString().isNotEmpty ?? false))
              .map((e) => e['field_name'] as String)
              .toList() ??
          <String>[];
    }

    final message = _extractErrorMessageFromResponse(response);
    throw ApiException(
      message ?? 'Ошибка загрузки пользовательских полей заказов',
      response.statusCode,
    );
  }

  Future<List<String>> getOrderCustomFieldValues(String key) async {
    final path =
        await _appendQueryParams('/order/get/custom-field-values?key=$key');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultList = data['result'] as List?;
      if (resultList == null) {
        return [];
      }
      return resultList.map((value) => value.toString()).toList();
    }

    final message = _extractErrorMessageFromResponse(response);
    throw ApiException(
      message ?? 'Ошибка загрузки значений пользовательского поля заказов',
      response.statusCode,
    );
  }

  Future<Order> getOrderDetails(int orderId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order/$orderId');
    if (kDebugMode) {
      //debugPrint('ApiService: getOrderDetails - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['result'];
        final order = Order.fromJson(data);
        await prefs.setString('cachedOrder_$orderId', json.encode(data));
        return order;
      } else {
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      ////debugPrint(
      // 'Ошибка загрузки деталей заказа: . Используем кэшированные данные.');
      final cachedOrder = prefs.getString('cachedOrder_$orderId');
      if (cachedOrder != null) {
        final decodedData = json.decode(cachedOrder);
        return Order.fromJson(decodedData);
      } else {
        throw Exception(
            'Ошибка загрузки деталей заказа и нет кэширвованных данных!');
      }
    }
  }

  Future<OrderResponse> getOrdersByLead({
    required int leadId,
    String relationType = 'lead',
    int page = 1,
    int perPage = 20,
  }) async {
    final normalizedRelation = relationType == 'deal' ? 'deal' : 'lead';
    final String url = normalizedRelation == 'deal'
        ? '/order/order-by-deal/$leadId'
        : '/lead/get-orders/$leadId?page=$page&per_page=$perPage';

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      //debugPrint('ApiService: getOrdersByLead - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (kDebugMode) {
        // //debugPrint('Request URL: $path');
        // //debugPrint('Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        return OrderResponse.fromJson(rawData);
      } else if (response.statusCode == 404 ||
          response.statusCode == 204 ||
          response.body.trim().isEmpty) {
        return OrderResponse.fromJson({
          'data': [],
          'pagination': {
            'total': 0,
            'count': 0,
            'per_page': perPage,
            'current_page': page,
            'total_pages': 1,
          },
        });
      } else {
        throw Exception('Ошибка сервера при загрузке заказов!');
      }
    } catch (e) {
      if (kDebugMode) {
        // //debugPrint('Ошибка загрузки заказов по лиду: $e');
      }
      throw Exception('Ошибка загрузки заказов:');
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required String phone,
    int? leadId,
    int? dealId,
    required bool delivery,
    String? deliveryAddress,
    int? deliveryAddressId,
    required List<Map<String, dynamic>> goods,
    required int organizationId,
    required int statusId,
    int? branchId,
    String? commentToCourier,
    int? managerId,
    int? integration,
    required double sum,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, int>>? directoryValues,
    List<FileHelper>? files,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/store/from-online-shop');
      if (kDebugMode) {
        //debugPrint('ApiService: createOrder - Generated path: $path');
      }

      final uri = Uri.parse('$baseUrl$path');
      if (files != null && files.isNotEmpty) {
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Device': 'mobile',
        });

        request.fields['phone'] = phone;
        request.fields['deliveryType'] = delivery ? 'delivery' : 'pickup';
        request.fields['organization_id'] = organizationId.toString();
        request.fields['status_id'] = statusId.toString();
        request.fields['payment_type'] = 'cash';
        request.fields['sum'] = sum.toString();
        if (commentToCourier != null) {
          request.fields['comment_to_courier'] = commentToCourier;
        }
        if (managerId != null) {
          request.fields['manager_id'] = managerId.toString();
        }
        if (integration != null) {
          request.fields['integration_id'] = integration.toString();
        }
        if (leadId != null) {
          request.fields['lead_id'] = leadId.toString();
        }
        if (dealId != null) {
          request.fields['deal_id'] = dealId.toString();
        }
        if (branchId != null) {
          request.fields['branch_id'] = branchId.toString();
        }
        if (delivery && deliveryAddressId != null) {
          request.fields['delivery_address_id'] = deliveryAddressId.toString();
        }

        for (int i = 0; i < goods.length; i++) {
          final item = goods[i];
          request.fields['goods[$i][variant_id]'] =
              item['variant_id'].toString();
          request.fields['goods[$i][quantity]'] =
              (item['quantity'] ?? 1).toString();
          request.fields['goods[$i][price]'] = item['price'].toString();
        }

        if (customFields != null && customFields.isNotEmpty) {
          for (int i = 0; i < customFields.length; i++) {
            final field = customFields[i];
            request.fields['order_custom_fields[$i][key]'] =
                field['key']?.toString() ?? '';
            request.fields['order_custom_fields[$i][value]'] =
                field['value']?.toString() ?? '';
            request.fields['order_custom_fields[$i][type]'] =
                field['type']?.toString() ?? 'string';
          }
        }

        if (directoryValues != null && directoryValues.isNotEmpty) {
          for (int i = 0; i < directoryValues.length; i++) {
            final value = directoryValues[i];
            request.fields['directory_values[$i][entry_id]'] =
                value['entry_id'].toString();
            request.fields['directory_values[$i][directory_id]'] =
                value['directory_id'].toString();
          }
        }

        final newFiles = files.where((f) => f.id == 0).toList();
        for (final fileData in newFiles) {
          final file = await http.MultipartFile.fromPath(
            'files[]',
            fileData.path,
            filename: fileData.name,
          );
          request.files.add(file);
        }

        final response = await _multipartPostRequest('', request);
        if (<int>[200, 201, 202, 203, 204, 300, 301]
            .contains(response.statusCode)) {
          final jsonResponse = response.body.isNotEmpty
              ? jsonDecode(response.body)
              : <String, dynamic>{};
          if (jsonResponse['result'] == 'success' ||
              jsonResponse['result'] is Map<String, dynamic> ||
              response.statusCode == 204) {
            return {
              'success': true,
              'statusId': statusId,
              'order': jsonResponse['result'] is Map<String, dynamic>
                  ? jsonResponse['result']
                  : null,
            };
          }
        }

        final jsonResponse = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : <String, dynamic>{};
        throw (jsonResponse['message'] ?? 'Ошибка при создании заказа');
      }

      final body = {
        'phone': phone,
        'deliveryType': delivery ? 'delivery' : 'pickup',
        'goods': goods
            .map((item) => {
                  'variant_id': int.parse(item['variant_id'].toString()),
                  'quantity': item['quantity'],
                  'price': item['price'].toString(),
                })
            .toList(),
        'organization_id': organizationId,
        'status_id': statusId,
        'comment_to_courier': commentToCourier,
        'payment_type': 'cash',
        'manager_id': managerId,
        'integration_id': integration,
        'sum': sum,
      };

      if (leadId != null) {
        body['lead_id'] = leadId;
      }
      if (dealId != null) {
        body['deal_id'] = dealId;
      }

      if (delivery) {
        body['delivery_address_id'] = deliveryAddressId;
      } else {
        body['delivery_address_id'] = null;
      }

      // Всегда отправляем branch_id, если он указан
      body['branch_id'] = branchId;

      if (customFields != null && customFields.isNotEmpty) {
        body['order_custom_fields'] = customFields;
      }

      if (directoryValues != null && directoryValues.isNotEmpty) {
        body['directory_values'] = directoryValues;
      }

      ////debugPrint('ApiService: Тело запроса для создания заказа: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode(body),
      );

      ////debugPrint('ApiService: Код ответа сервера: ${response.statusCode}');
      ////debugPrint('ApiService: Тело ответа сервера: ${response.body}');

      if (<int>[200, 201, 202, 203, 204, 300, 301]
          .contains(response.statusCode)) {
        final jsonResponse = jsonDecode(response.body);
        // Проверяем, есть ли в ответе данные заказа
        if (jsonResponse['result'] == 'success') {
          return {
            'success': true,
            'statusId': statusId, // Используем входной statusId
            'order': null, // Данные заказа отсутствуют
          };
        } else if (jsonResponse['result'] is Map<String, dynamic>) {
          // Обработка случая, когда сервер возвращает полный объект
          final returnedStatusId = int.tryParse(
                  jsonResponse['result']['status_id']?.toString() ?? '') ??
              statusId;
          return {
            'success': true,
            'statusId': returnedStatusId,
            'order': jsonResponse['result'],
          };
        } else {
          throw ('Неожиданная структура ответа сервера:');
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw (jsonResponse['message'] ?? 'Ошибка при создании заказа');
      }
    } catch (e) {
      ////debugPrint('ApiService: Ошибка создания заказа: ');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateOrder({
    required int orderId,
    required String phone,
    int? leadId,
    int? dealId,
    required bool delivery,
    String? deliveryAddress,
    int? deliveryAddressId,
    required List<Map<String, dynamic>> goods,
    required int organizationId,
    int? branchId,
    String? commentToCourier,
    int? managerId, // Новое поле
    int? integration,
    required double sum,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, int>>? directoryValues,
    List<String>? filePaths,
    List<OrderFile>? existingFiles,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/$orderId');
      if (kDebugMode) {
        //debugPrint('ApiService: updateOrder - Generated path: $path');
      }

      final uri = Uri.parse('$baseUrl$path');
      if ((filePaths != null && filePaths.isNotEmpty) ||
          existingFiles != null) {
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Device': 'mobile',
        });

        request.fields['phone'] = phone;
        request.fields['deliveryType'] = delivery ? 'delivery' : 'pickup';
        request.fields['organization_id'] = organizationId.toString();
        request.fields['payment_type'] = 'cash';
        request.fields['sum'] = sum.toString();
        if (commentToCourier != null) {
          request.fields['comment_to_courier'] = commentToCourier;
        }
        if (managerId != null) {
          request.fields['manager_id'] = managerId.toString();
        }
        if (integration != null) {
          request.fields['integration_id'] = integration.toString();
        }
        if (leadId != null) {
          request.fields['lead_id'] = leadId.toString();
        }
        if (dealId != null) {
          request.fields['deal_id'] = dealId.toString();
        }
        if (branchId != null) {
          request.fields['branch_id'] = branchId.toString();
        }
        if (delivery) {
          if (deliveryAddress != null) {
            request.fields['delivery_address'] = deliveryAddress;
          }
          if (deliveryAddressId != null) {
            request.fields['delivery_address_id'] =
                deliveryAddressId.toString();
          }
        }

        for (int i = 0; i < goods.length; i++) {
          final item = goods[i];
          request.fields['goods[$i][variant_id]'] =
              item['variant_id'].toString();
          request.fields['goods[$i][quantity]'] =
              (item['quantity'] ?? 1).toString();
          request.fields['goods[$i][price]'] = item['price'].toString();
        }

        if (customFields != null && customFields.isNotEmpty) {
          for (int i = 0; i < customFields.length; i++) {
            final field = customFields[i];
            request.fields['order_custom_fields[$i][key]'] =
                field['key']?.toString() ?? '';
            request.fields['order_custom_fields[$i][value]'] =
                field['value']?.toString() ?? '';
            request.fields['order_custom_fields[$i][type]'] =
                field['type']?.toString() ?? 'string';
          }
        }

        if (directoryValues != null && directoryValues.isNotEmpty) {
          for (int i = 0; i < directoryValues.length; i++) {
            final value = directoryValues[i];
            request.fields['directory_values[$i][entry_id]'] =
                value['entry_id'].toString();
            request.fields['directory_values[$i][directory_id]'] =
                value['directory_id'].toString();
          }
        }

        if (existingFiles != null && existingFiles.isNotEmpty) {
          for (int i = 0; i < existingFiles.length; i++) {
            request.fields['existing_files[$i]'] =
                existingFiles[i].id.toString();
          }
        }

        if (filePaths != null && filePaths.isNotEmpty) {
          for (final filePath in filePaths) {
            final file = await http.MultipartFile.fromPath('files[]', filePath);
            request.files.add(file);
          }
        }

        final response = await _multipartPostRequest('', request);
        if (<int>[200, 201, 202, 203, 204, 300, 301]
            .contains(response.statusCode)) {
          final jsonResponse = response.body.isNotEmpty
              ? jsonDecode(response.body)
              : <String, dynamic>{};
          return {
            'success': true,
            'order': jsonResponse['result'] is Map<String, dynamic>
                ? jsonResponse['result']
                : null,
          };
        }

        final jsonResponse = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : <String, dynamic>{};
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при обновлении заказа');
      }

      final body = {
        'phone': phone,
        'deliveryType': delivery
            ? 'delivery'
            : 'pickup', // Исправлено: delivery=true -> "delivery"
        'goods': goods
            .map((item) => {
                  'variant_id': int.parse(item['variant_id'].toString()),
                  'quantity': item['quantity'],
                  'price': item['price'].toString(),
                })
            .toList(),
        'organization_id': organizationId.toString(),
        'comment_to_courier': commentToCourier,
        'payment_type': 'cash',
        'manager_id': managerId?.toString(),
        'integration_id': integration,
        'sum': sum,
      };

      if (leadId != null) {
        body['lead_id'] = leadId;
      }
      if (dealId != null) {
        body['deal_id'] = dealId;
      }

      if (delivery) {
        body['delivery_address'] = deliveryAddress;
        body['delivery_address_id'] = deliveryAddressId?.toString();
      } else {
        body['delivery_address'] = null;
        body['delivery_address_id'] = null;
      }

      // Всегда отправляем branch_id, если он указан
      body['branch_id'] = branchId;

      if (customFields != null && customFields.isNotEmpty) {
        body['order_custom_fields'] = customFields;
      }

      if (directoryValues != null && directoryValues.isNotEmpty) {
        body['directory_values'] = directoryValues;
      }

      ////debugPrint('ApiService: Тело запроса для обновления заказа: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode(body),
      );

      ////debugPrint('ApiService: Код ответа сервера: ${response.statusCode}');
      ////debugPrint('ApiService: Тело ответа сервера: ${response.body}');

      // Обрабатываем коды ответа 200, 201, 202, 203, 204, 300, 301 как успешные
      if (<int>[200, 201, 202, 203, 204, 300, 301]
          .contains(response.statusCode)) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['result'] == 'success') {
          return {
            'success': true,
            'order': null, // Данные заказа отсутствуют
          };
        } else if (jsonResponse['result'] is Map<String, dynamic>) {
          return {
            'success': true,
            'order': jsonResponse['result'],
          };
        } else {
          throw Exception(
              'Неожиданная структура ответа сервера: ${jsonResponse['result']}');
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при обновлении заказа');
      }
    } catch (e, stackTrace) {
      ////debugPrint('ApiService: Ошибка обновления заказа: ');
      ////debugPrint('ApiService: StackTrace: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<DeliveryAddressResponse> getDeliveryAddresses({
    int? leadId,
    int? dealId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      if (leadId == null && dealId == null) {
        throw Exception('Не указан lead_id или deal_id');
      }

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final relationQuery =
          dealId != null ? 'deal_id=$dealId' : 'lead_id=$leadId';
      final path = await _appendQueryParams('/delivery-address?$relationQuery');
      if (kDebugMode) {
        //debugPrint('ApiService: getDeliveryAddresses - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeliveryAddressResponse.fromJson(data);
      } else {
        throw Exception(
            'Ошибка при получении адресов доставки: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении адресов доставки: ');
    }
  }

  Future<http.Response> createDeliveryAddress({
    required String address,
    int? leadId,
    int? dealId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/mini-app/delivery-address');
    final organizationId = await getSelectedOrganization();
    final salesFunnelId = await getSelectedSalesFunnel();
    if (kDebugMode) {
      debugPrint('ApiService: createDeliveryAddress - Generated path: $path');
    }

    final body = <String, dynamic>{
      'address': address,
    };
    if (dealId != null) {
      body['deal_id'] = dealId;
    } else {
      body['lead_id'] = leadId;
    }
    if (organizationId != null &&
        organizationId.isNotEmpty &&
        organizationId != 'null') {
      body['organization_id'] = organizationId;
    }
    if (salesFunnelId != null &&
        salesFunnelId.isNotEmpty &&
        salesFunnelId != 'null') {
      body['sales_funnel_id'] = salesFunnelId;
    }

    final response = await _postRequest(
      path,
      body,
    );

    if (kDebugMode) {
      debugPrint(
          'ApiService: createDeliveryAddress - Response status: ${response.statusCode}');
    }

    return response;
  }

  Future<http.Response> createOrderStatus({
    required String title,
    required String notificationMessage,
    required bool isSuccess,
    required bool isFailed,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order-status');
    if (kDebugMode) {
      //debugPrint('ApiService: createOrderStatus - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        'title': title,
        'notification_message': notificationMessage,
        'is_success': isSuccess,
        'is_failed': isFailed,
        'color': '#FFFFF', // Добавляем параметр color
      },
    );
    return response;
  }

  Future<http.Response> updateOrderStatus({
    required int statusId,
    required String title,
    required String notificationMessage,
    required bool isSuccess,
    required bool isFailed,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order-status/$statusId');
    if (kDebugMode) {
      //debugPrint('ApiService: updateOrderStatus - Generated path: $path');
    }

    final response = await _patchRequest(
      path,
      {
        'title': title,
        'notification_message': notificationMessage,
        'is_success': isSuccess,
        'is_failed': isFailed,
      },
    );
    return response;
  }

  Future<bool> deleteOrderStatus(int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/order-status/$statusId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteOrderStatus - Generated path: $path');
    }

    final response = await _deleteRequest(path);
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> checkIfStatusHasOrders(int statusId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/orders?status_id=$statusId');
    if (kDebugMode) {
      //debugPrint('ApiService: checkIfStatusHasOrders - Generated path: $path');
    }

    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] != null && data['data'].isNotEmpty;
    }
    return false;
  }

  Future<bool> deleteOrder({
    required int orderId,
    required int? organizationId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/order/$orderId');
      if (kDebugMode) {
        //debugPrint('ApiService: deleteOrder - Generated path: $path');
      }

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при удалении заказа');
      }
    } catch (e) {
      ////debugPrint('Ошибка удаления заказа: ');
      return false;
    }
  }

  Future<bool> changeOrderStatus({
    required int orderId,
    required int statusId,
    required int? organizationId,
    int? reasonForRefusalId,
    String? reasonForRefusal,
  }) async {
    try {
      final path = await _appendQueryParams('/order/changeStatus/$orderId');
      if (kDebugMode) {
        debugPrint('ApiService: changeOrderStatus - Generated path: $path');
      }

      final response = await _postRequest(
        '/order/changeStatus/$orderId',
        {
          'status_id': statusId,
          if (reasonForRefusalId != null)
            'reason_for_refusal_id': reasonForRefusalId,
          if (reasonForRefusal != null && reasonForRefusal.trim().isNotEmpty)
            'reason_for_refusal': reasonForRefusal.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 422) {
        throw OrderStatusUpdateException(
          response.statusCode,
          _getOrderStatusChangeErrorMessage(response),
        );
      } else {
        throw Exception(
          _extractErrorMessageFromResponse(response) ??
              'Ошибка при смене статуса заказа',
        );
      }
    } on OrderStatusUpdateException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: changeOrderStatus error: $e');
      }
      rethrow;
    }
  }

  Future<List<Branch>> getBranches({String? search}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/storage');
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (kDebugMode) {
      //debugPrint('ApiService: getBranches - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        List<Branch> branches = List<Branch>.from(
            data['result'].map((branch) => Branch.fromJson(branch)));
        return branches;
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных: ${response.statusCode}');
    }
  }

  Future<List<LeadOrderData>> getLeadOrders() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/lead');
    if (kDebugMode) {
      //debugPrint('ApiService: getLeadOrders - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result') && data['result']['data'] is List) {
        return (data['result']['data'] as List<dynamic>)
            .map((e) => LeadOrderData.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception('Ошибка загрузки LeadOrder: ${response.statusCode}');
    }
  }

  Future<List<PriceTypeModel>> getPriceTypes({String? search}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/priceType');

    // Добавляем параметр поиска, если он передан
    if (search != null && search.isNotEmpty) {
      path =
          path.contains('?') ? '$path&search=$search' : '$path?search=$search';
    }

    if (kDebugMode) {
      //debugPrint('ApiService: getPriceTypes - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return (json.decode(response.body)['result']['data'] as List)
            .map((unit) => PriceTypeModel.fromJson(unit))
            .toList();
      } else {
        return [];
      }
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка загрузки типов цен', response.statusCode);
    }
  }

  Future<void> createPriceType(
    PriceTypeModel unit,
  ) async {
    final path = await _appendQueryParams('/priceType');
    if (kDebugMode) {
      debugPrint('ApiService: createPriceType - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': unit.name,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (kDebugMode) {
        debugPrint('createPriceType success: ${response.body}');
      }
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка создания типа цены', response.statusCode);
    }
  }

  Future<void> updatePriceType(
      {required PriceTypeModel priceType, required int id}) async {
    final path = await _appendQueryParams('/priceType/$id');
    if (kDebugMode) {
      debugPrint('ApiService: updatePriceType - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': priceType.name,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (kDebugMode) {
        debugPrint('updatePriceType success: ${response.body}');
      }
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка обновления типа цены', response.statusCode);
    }
  }

  Future<void> deletePriceType(int priceTypeId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/priceType/$priceTypeId');
    if (kDebugMode) {
      debugPrint('ApiService: deletePriceType - Generated path: $path');
    }

    final response = await _deleteRequestWithBody(path,
        {"organization_id": organizationId, "sales_funnel_id": salesFunnelId});

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (kDebugMode) {
        debugPrint('deletePriceType success: ${response.body}');
      }
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка удаления типа цены', response.statusCode);
    }
  }

  Future<OrderQuantityContent> getOrderByFilter(
    Map<String, dynamic>? filters,
    String? search,
  ) async {
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        debugPrint("ApiService: filters['date_from']: ${filters['date_from']}");
        final date_from = filters['date_from'] as DateTime;
        queryParams['date_from'] = date_from.toIso8601String();
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
        final date_to = filters['date_to'] as DateTime;
        queryParams['date_to'] = date_to.toIso8601String();
      }

      if (filters.containsKey('sum_from') && filters['sum_from'] != null) {
        debugPrint("ApiService: filters['sum_from']: ${filters['sum_from']}");
        final sumFrom = filters['sum_from'] as double;
        queryParams['sum_from'] = sumFrom.toString();
      }

      if (filters.containsKey('sum_to') && filters['sum_to'] != null) {
        debugPrint("ApiService: filters['sum_to']: ${filters['sum_to']}");
        final sumTo = filters['sum_to'] as double;
        queryParams['sum_to'] = sumTo.toString();
      }

      if (filters.containsKey('status_id') && filters['status_id'] != null) {
        debugPrint("ApiService: filters['status_id']: ${filters['status_id']}");
        final statusID = filters['status_id'] as int;
        queryParams['status_id'] = statusID.toString();
      }
    }
    // Формируем параметры запроса
    var path = await _appendQueryParams('/order/dashboard');

    // Fix: Properly encode query parameters
    if (queryParams.isNotEmpty) {
      // Check if path already has query params (contains ?)
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';
    }

    debugPrint("ApiService: getOrderByFilter path: $path");

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return OrderQuantityContent.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка',
        response.statusCode,
      );
    }
  }

  /// Получить варианты товаров
  Future<GoodVariantsResponse> getOpeningsGoodVariants({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      String path = await _appendQueryParams(
          '/good/get/variant?page=$page&per_page=$perPage');

      path += '&is_service=0';

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GoodVariantsResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка получения вариантов товаров",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<GoodVariantsResponse> getGoodVariantsForDropdown({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    String path = '/good/get/variant?page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search)}';
    }

    path += '&is_service=0';

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint(
          'ApiService: getGoodVariantsForDropdown - Generated path: $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      debugPrint(
          'ApiService: Ответ сервера: statusCode=${response.statusCode}');
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final variantsResponse = GoodVariantsResponse.fromJson(data);

      if (kDebugMode) {
        debugPrint(
            'ApiService: Успешно получено ${variantsResponse.result?.data?.length ?? 0} вариантов товаров');
        if (variantsResponse.result?.pagination != null) {
          debugPrint(
              'ApiService: Pagination - current: ${variantsResponse.result!.pagination!.currentPage}, total pages: ${variantsResponse.result!.pagination!.totalPages}');
        }
      }

      return variantsResponse;
    } else {
      if (kDebugMode) {
        debugPrint(
            'ApiService: Ошибка загрузки вариантов товаров: ${response.statusCode}');
      }
      throw Exception(
          'Ошибка загрузки вариантов товаров: ${response.statusCode}');
    }
  }
}

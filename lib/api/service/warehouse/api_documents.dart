part of '../api_service.dart';

extension ApiWarehouseDocumentsX on ApiService {
  Future<Map<String, dynamic>> getIncomingCalls({
    required int page,
    required int perPage,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/calls?incoming=1&missed=0&page=$page&per_page=$perPage';

    if (searchQuery != null && searchQuery.isNotEmpty) {
      path += '&search=${Uri.encodeQueryComponent(searchQuery)}';
    }

    if (filters != null) {
      if (filters.containsKey('startDate') && filters['startDate'] != null) {
        path += '&from=${Uri.encodeQueryComponent(filters['startDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр to: ${filters['endDate']}');
        }
      }
      if (filters.containsKey('leads') &&
          filters['leads'] is List &&
          (filters['leads'] as List).isNotEmpty) {
        final leadIds = filters['leads'] as List<int>;
        for (var leadId in leadIds) {
          path += '&leads[]=$leadId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены lead_id: $leadIds');
        }
      }
      if (filters.containsKey('operators') &&
          filters['operators'] is List &&
          (filters['operators'] as List).isNotEmpty) {
        final operatorIds = filters['operators'] as List<int>;
        for (var operatorId in operatorIds) {
          path += '&operator_id[]=$operatorId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены operator_id: $operatorIds');
        }
      }
      if (filters.containsKey('ratings') &&
          filters['ratings'] is List &&
          (filters['ratings'] as List).isNotEmpty) {
        final ratingIds = filters['ratings'] as List<int>;
        for (var ratingId in ratingIds) {
          path += '&rating[]=$ratingId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getIncomingCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //debugPrint('ApiService: Response for getIncomingCalls: $data');
      }
      if (data['result']['data'] != null) {
        final calls = (data['result']['data'] as List)
            .map((json) => CallLogEntry.fromJson(json))
            .toList();
        final pagination = data['result']['pagination'] as Map<String, dynamic>;
        return {
          'calls': calls,
          'pagination': pagination,
        };
      } else {
        throw ('Нет данных о входящих звонках в ответе');
      }
    } else {
      if (kDebugMode) {
        //debugPrint('ApiService: Error response body: ${response.body}');
      }
      throw ('Ошибка загрузки входящих звонков');
    }
  }

  Future<IncomingResponse> getIncomingDocuments({
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/income-documents?page=$page&per_page=$perPage';

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    debugPrint("Фильтры для прихода товаров: $filters");

    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        final dateFrom = filters['date_from'] as DateTime;
        path += '&date_from=${dateFrom.toIso8601String()}';
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        final dateTo = filters['date_to'] as DateTime;
        path += '&date_to=${dateTo.toIso8601String()}';
      }

      if (filters.containsKey('deleted') && filters['deleted'] != null) {
        path += '&deleted=${filters['deleted']}';
      }

      if (filters.containsKey('author_id') && filters['author_id'] != null) {
        path += '&author_id=${filters['author_id']}';
      }

      if (filters.containsKey('approved') && filters['approved'] != null) {
        path += '&approved=${filters['approved']}';
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint('ApiService: getIncomingDocuments - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body)['result'];
        debugPrint("Полученные данные по приходу товаров: $rawData");
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных прихода товаров!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocument> getIncomingDocumentById(int documentId) async {
    String url = '/income-documents/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getIncomingDocumentById - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveIncomingDocument(int documentId) async {
    const String url = '/income-documents/approve';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: approveIncomingDocument - Generated path: $path');
    }

    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint(
              'ApiService: approveIncomingDocument - Document $documentId approved successfully');
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при проведении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unApproveIncomingDocument(int documentId) async {
    const String url = '/income-documents/unApprove';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint(
          'ApiService: unApproveIncomingDocument - Generated path: $path');
    }

    try {
      final token = await getToken();
      if (token == null) 'Токен не найден';

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint(
              'ApiService: unApproveIncomingDocument - Document $documentId unapproved successfully');
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при отмене проведения документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreIncomingDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final pathWithParams =
          await _appendQueryParams('/income-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      if (kDebugMode) {
        debugPrint('ApiService: restoreIncomingDocument - Request body: $body');
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint(
              'ApiService: restoreIncomingDocument - Document $documentId restored successfully');
        }
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocumentHistoryResponse> getIncomingDocumentHistory(
      int documentId) async {
    String url = '/income-documents/history/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint(
          'ApiService: getIncomingDocumentHistory - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocumentHistoryResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createIncomingDocument({
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    bool approve = false, // Новый параметр
    double? exchangeRate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/income-documents');
      final uri = Uri.parse('$baseUrl$path');

      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        'approve': approve, // Добавляем новый параметр
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createPurchaseDocument({
    required String date,
    required int storageId,
    int? supplierId,
    required String comment,
    required double paidAmount,
    required double debtAmount,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    bool approve = false,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/rmk-income-documents');
      final uri = Uri.parse('$baseUrl$path');

      final payload = <String, dynamic>{
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': supplierId ?? 0,
        'supplier_id': supplierId ?? 0,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        'approve': approve,
        'payment_mode': debtAmount > 0 ? 'debt' : 'payment',
        'paid_amount': paidAmount,
        'debt_amount': debtAmount,
        'document_type': 'purchase',
      };

      if (kDebugMode) {
        debugPrint(
          'ApiService: createPurchaseDocument - payload: ${jsonEncode(payload)}',
        );
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateIncomingDocument({
    required int documentId,
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    double? exchangeRate,
  }) async {
    final token = await getToken();
    if (token == null) throw 'Токен не найден';

    final path = await _appendQueryParams('/income-documents/$documentId');
    final uri = Uri.parse('$baseUrl$path');
    final body = jsonEncode({
      'date': date,
      'storage_id': storageId,
      'comment': comment,
      'counterparty_id': counterpartyId,
      'document_goods': documentGoods,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
    });

    try {
      final response = await http.put(
        // Используем PATCH для обновления
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteIncomingDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams = await _appendQueryParams('/income-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      // Создаем чистый URI без параметров для DELETE запроса
      final cleanUri = Uri.parse('$baseUrl/income-documents');

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        debugPrint('ApiService: deleteIncomingDocument - Request body: $body');
      }

      final response = await http.delete(
        cleanUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при удалении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massApproveIncomingDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/income-documents/approve');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом проведении документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDisapproveIncomingDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/income-documents/unApprove');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом снятии проведения документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDeleteIncomingDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/income-documents/');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massRestoreIncomingDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/income-documents/restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом восстановлении документов прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<expense.ExpenseResponse> getClientSales({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? approved,
    int? deleted,
    int? leadId,
    int? cashRegisterId,
    int? supplierId,
    int? authorId,
    int? storageId,
  }) async {
    String url =
        '/expense-documents'; // Предполагаемый endpoint; подкорректируй если нужно
    url += '?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (dateFrom != null) {
      url += '&date_from=${dateFrom.toIso8601String()}';
    }
    if (dateTo != null) {
      url += '&date_to=${dateTo.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }
    if (deleted != null) {
      url += '&deleted=$deleted';
    }
    if (leadId != null) {
      url += '&lead_id=$leadId';
    }
    if (cashRegisterId != null) {
      url += '&cash_register_id=$cashRegisterId';
    }
    if (supplierId != null) {
      url += '&supplier_id=$supplierId';
    }
    if (authorId != null) {
      url += '&author_id=$authorId';
    }
    if (storageId != null) {
      url += '&storage_id=$storageId';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getClientSales - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result']; // Как в JSON
        return expense.ExpenseResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createClientSaleDocument({
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    required bool approve,
    double? exchangeRate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/expense-documents');
      final response = await _postRequest(path, {
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        'approve': approve,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Неизвестная ошибка при создании документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteClientSaleDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams = await _appendQueryParams('/expense-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      // Создаем чистый URI без параметров для DELETE запроса
      final cleanUri = Uri.parse('$baseUrl/expense-documents');

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        debugPrint(
            'ApiService: deleteClientSaleDocument - Request body: $body');
      }

      final response = await http.delete(
        cleanUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при удалении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateClientSaleDocument({
    required int documentId,
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    double? exchangeRate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final path = await _appendQueryParams('/expense-documents/$documentId');
      final uri = Uri.parse('$baseUrl$path');

      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка обновления документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveClientSaleDocument(int documentId) async {
    const String url = '/expense-documents/approve';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно проведен
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при проведении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unApproveClientSaleDocument(int documentId) async {
    const String url = '/expense-documents/unApprove';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно отменено
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при отмене проведения документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreClientSaleDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final pathWithParams =
          await _appendQueryParams('/expense-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massApproveClientSaleDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/expense-documents/approve');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом проведении документов реализации!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDisapproveClientSaleDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/expense-documents/unApprove');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом снятии проведения документов реализации!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDeleteClientSaleDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/expense-documents/');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов реализации!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massRestoreClientSaleDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/expense-documents/restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом восстановлении документов реализации!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<WareHouse>> getStorage({bool useAll = false}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams(useAll ? '/storage-all' : '/storage');
    if (kDebugMode) {
      //debugPrint('ApiService: getStorage - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные складов: $data');

      // Извлекаем массив из поля "result"
      final List<dynamic> resultList = data['result'] ?? [];

      return resultList.map((storage) => WareHouse.fromJson(storage)).toList();
    } else {
      throw Exception('Ошибка загрузки складов');
    }
  }

  Future<List<WareHouse>> getWareHouses({
    String? search,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    var path = await _appendQueryParams('/storage');
    if (kDebugMode) {
      //debugPrint('ApiService: getStorage - Generated path: $path');
    }

    path += search != null && search.isNotEmpty ? '&search=$search' : '';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные складов: $data');

      // Извлекаем массив из поля "result"
      final List<dynamic> resultList = data['result'] ?? [];

      return resultList.map((storage) => WareHouse.fromJson(storage)).toList();
    } else {
      throw ApiException('Ошибка загрузки складов', response.statusCode);
    }
  }

  Future<bool> createStorage(
    WareHouse unit,
    List<int> userIds,
  ) async {
    final path = await _appendQueryParams('/storage');
    if (kDebugMode) {
      debugPrint('ApiService: createStorage - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': unit.name,
      "users": userIds,
      "show_on_site": unit.showOnSite,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка создания склада', response.statusCode);
    }
  }

  Future<void> updateStorage({
    required WareHouse storage,
    required int id,
    required List<int> ids,
  }) async {
    final path = await _appendQueryParams('/storage/$id');

    if (kDebugMode) {
      debugPrint('ApiService: updateStorage - Generated path: $path');
    }

    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': storage.name,
      'users': ids,
      'show_on_site': storage.showOnSite,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        debugPrint("Склад обновлен успешно");
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        debugPrint('Ошибка обновления склада: $message');
        throw ApiException(message ?? 'Ошибка обновления', response.statusCode);
      }
    } else {
      final message = _extractErrorMessageFromResponse(response);
      debugPrint('Ошибка обновления склада2: $message');
      throw ApiException(message ?? 'Ошибка обновления', response.statusCode);
    }
  }

  Future<void> deleteStorage(int storageId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/storage/$storageId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteSupplier - Generated path: $path');
    }

    final response = await _deleteRequestWithBody(path,
        {"organization_id": organizationId, "sales_funnel_id": salesFunnelId});

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Ошибка удаления поставщика: ${response.body}');
    }
  }

  Future<List<MeasureUnitModel>> getAllMeasureUnits() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/unit');

    if (kDebugMode) {
      debugPrint("ApiService: getAllMeasureUnits - Generated path: $path");
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return (json.decode(response.body)['result'] as List)
            .map((unit) => MeasureUnitModel.fromJson(unit))
            .toList();
      } else {
        return [];
      }
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка загрузки единиц измерения', response.statusCode);
    }
  }

  Future<List<MeasureUnitModel>> getMeasureUnits({String? search}) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/unit');

    // Добавляем параметр поиска, если он передан
    if (search != null && search.isNotEmpty) {
      path =
          path.contains('?') ? '$path&search=$search' : '$path?search=$search';
    }

    if (kDebugMode) {
      //debugPrint('ApiService: getMeasureUnits - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return (json.decode(response.body)['result'] as List)
            .map((unit) => MeasureUnitModel.fromJson(unit))
            .toList();
      } else {
        return [];
      }
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка загрузки единиц измерения', response.statusCode);
    }
  }

  Future<void> createMeasureUnit(
    MeasureUnitModel unit,
  ) async {
    final path = await _appendQueryParams('/unit');
    if (kDebugMode) {
      //debugPrint('ApiService: createSupplier - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': unit.name,
      'short_name': unit.shortName,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка создания поставщика', response.statusCode);
    }
  }

  Future<void> deleteMeasureUnit(int supplierId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/unit/$supplierId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteSupplier - Generated path: $path');
    }

    final response = await _deleteRequestWithBody(path,
        {"organization_id": organizationId, "sales_funnel_id": salesFunnelId});

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
          message ?? 'Ошибка удаления поставщика', response.statusCode);
    }
  }

  Future<void> createSupplier(
      Supplier supplier, String organizationId, String salesFunnelId) async {
    final path = await _appendQueryParams('/suppliers');
    if (kDebugMode) {
      //debugPrint('ApiService: createSupplier - Generated path: $path');
    }

    final body = {
      'name': supplier.name,
      'phone': supplier.phone,
      "note": supplier.note,
      "inn": supplier.inn,
      'currency_id': supplier.currencyId,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _postRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return; //Supplier.fromJson(json.decode(response.body)['result']);
      } else {
        throw Exception('Ошибка создания поставщика: ${response.body}');
      }
    } else {
      throw Exception('Ошибка создания поставщика: ${response.body}');
    }
  }

  Future<void> updateSupplier(
      {required Supplier supplier, required int id}) async {
    final path = await _appendQueryParams('/suppliers/$id');
    if (kDebugMode) {
      //debugPrint('ApiService: updateSupplier - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': supplier.name,
      'phone': supplier.phone,
      if (supplier.note != null) 'note': supplier.note,
      if (supplier.inn != null) 'inn': supplier.inn,
      'currency_id': supplier.currencyId,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);
    debugPrint('Response body: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return;
      } else {
        debugPrint("Ошибка: Пустой ответ при обновлении поставщика");
        throw Exception('Ошибка обновления поставщика: ${response.body}');
      }
    } else {
      debugPrint("Ошибка: ${response.body}");
      throw Exception('Ошибка обновления поставщика: ${response.body}');
    }
  }

  Future<void> deleteSupplier(int supplierId) async {
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final path = await _appendQueryParams('/suppliers/$supplierId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteSupplier - Generated path: $path');
    }

    final response = await _deleteRequestWithBody(path,
        {"organization_id": organizationId, "sales_funnel_id": salesFunnelId});

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Ошибка удаления поставщика: ${response.body}');
    }
  }

  Future<List<Supplier>> getSuppliers() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/suppliers');
    if (kDebugMode) {
      //debugPrint('ApiService: getSuppliers - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return (json.decode(response.body)['result']["data"] as List)
            .map((supplier) => Supplier.fromJson(supplier))
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Ошибка создания поставщика: ${response.body}');
    }
  }

  Future<List<Supplier>> getSupplier({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path =
        await _appendQueryParams('/suppliers?page=$page&per_page=$perPage');

    // Добавляем параметр поиска, если он передан
    if (search != null && search.isNotEmpty) {
      path =
          path.contains('?') ? '$path&search=$search' : '$path?search=$search';
    }

    if (kDebugMode) {
      //debugPrint('ApiService: getSupplier - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Полученные данные поставщиков: $data');

      // Извлекаем массив из поля "result"
      final List<dynamic> resultList = data['result']["data"] ?? [];

      return resultList.map((supplier) => Supplier.fromJson(supplier)).toList();
    } else {
      throw Exception('Ошибка загрузки поставщиков');
    }
  }

  Future<IncomingResponse> getSupplierReturnDocuments({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
    int? approved, // Для будущего фильтра по статусу
  }) async {
    String url = '/supplier-return-documents'; // Замена endpoint'а
    url += '?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (fromDate != null) {
      url += '&from=${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      url += '&to=${toDate.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }

    final path = await _appendQueryParams(url);

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result']; // Как в JSON
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка получения данных возврата поставщику',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocument> getSupplierReturnDocumentById(int documentId) async {
    try {
      String url = '/supplier-return-documents/$documentId';

      final path = await _appendQueryParams(url);
      if (kDebugMode) {
        debugPrint(
            'ApiService: getSupplierReturnDocumentById - Generated path: $path');
      }

      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка получения данных документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveSupplierReturnDocument(int documentId) async {
    const String url = '/supplier-return-documents/approve';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint(
          'ApiService: approveSupplierReturnDocument - Generated path: $path');
    }

    try {
      final response = await _postRequest(path, {
        'ids': [documentId]
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при проведении документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unApproveSupplierReturnDocument(int documentId) async {
    const String url = '/supplier-return-documents/unApprove';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint(
          'ApiService: unApproveSupplierReturnDocument - Generated path: $path');
    }

    try {
      final response = await _postRequest(path, {
        'ids': [documentId]
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при отмене проведения документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createSupplierReturnDocument({
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    required bool approve,
    double? exchangeRate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/supplier-return-documents');
      final uri = Uri.parse('$baseUrl$path');
      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        'approve': approve,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? "Ошибка создании документа", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSupplierReturnDocument({
    required int documentId,
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    double? exchangeRate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path =
          await _appendQueryParams('/supplier-return-documents/$documentId');
      final uri = Uri.parse('$baseUrl$path');
      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? "Ошибка обновления документа", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteSupplierReturnDocument(
      int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams =
          await _appendQueryParams('/supplier-return-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      // Создаем чистый URI без параметров для DELETE запроса
      final cleanUri = Uri.parse('$baseUrl/supplier-return-documents');

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        debugPrint(
            'ApiService: deleteSupplierReturnDocument - Request body: $body');
      }

      final response = await http.delete(
        cleanUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? "Ошибка удалении документа", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreSupplierReturnDocument(
      int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final pathWithParams =
          await _appendQueryParams('/supplier-return-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      if (kDebugMode) {
        debugPrint(
            'ApiService: restoreSupplierReturnDocument - Request body: $body');
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint(
              'ApiService: restoreSupplierReturnDocument - Document $documentId restored successfully');
        }
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<SuppliersDataResponse> getAllSuppliers({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    String path =
        await _appendQueryParams('/suppliers?page=$page&per_page=$perPage');
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    final response = await _getRequest(path);

    late SuppliersDataResponse cashRegistersData;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        cashRegistersData = SuppliersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    return cashRegistersData;
  }

  Future<IncomingResponse> getClientReturns({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? approved,
    int? deleted,
    int? leadId,
    int? cashRegisterId,
    int? supplierId,
    int? authorId,
    int? storageId,
  }) async {
    String url = '/client-return-documents'; // Заменили endpoint
    url += '?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (dateFrom != null) {
      url += '&date_from=${dateFrom.toIso8601String()}';
    }
    if (dateTo != null) {
      url += '&date_to=${dateTo.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }
    if (deleted != null) {
      url += '&deleted=$deleted';
    }
    if (leadId != null) {
      url += '&lead_id=$leadId';
    }
    if (cashRegisterId != null) {
      url += '&cash_register_id=$cashRegisterId';
    }
    if (supplierId != null) {
      url += '&supplier_id=$supplierId';
    }
    if (authorId != null) {
      url += '&author_id=$authorId';
    }
    if (storageId != null) {
      url += '&storage_id=$storageId';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getClientReturns - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result']; // Как в JSON
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных возврата!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocument> getClientReturnById(int documentId) async {
    try {
      String url = '/client-return-documents/$documentId';

      final path = await _appendQueryParams(url);
      if (kDebugMode) {
        debugPrint('ApiService: getClientReturnById - Generated path: $path');
      }

      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных возврата!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createClientReturnDocument({
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    required bool approve,
    double? exchangeRate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/client-return-documents');

      final response = await _postRequest(path, {
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        'approve': approve,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных возврата!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteClientReturnDocument(
      int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams =
          await _appendQueryParams('/client-return-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        debugPrint(
            'ApiService: deleteClientReturnDocument - Request body: $body');
        debugPrint(
            'ApiService: deleteClientReturnDocument - Request params: $pathWithParams');
      }

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при удалении документа возврата от клиента',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateClientReturnDocument({
    required int documentId,
    required String date,
    required int storageId,
    required String comment,
    required int counterpartyId,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int salesFunnelId,
    double? exchangeRate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path =
          await _appendQueryParams('/client-return-documents/$documentId');
      final uri = Uri.parse('$baseUrl$path');

      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'counterparty_id': counterpartyId,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'sales_funnel_id': salesFunnelId,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при обновлении документа возврата!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveClientReturnDocument(int documentId) async {
    const String url = '/client-return-documents/approve';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно проведен
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при проведении документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unApproveClientReturnDocument(int documentId) async {
    const String url = '/client-return-documents/unApprove';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно отменено
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при отмене проведения документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massApproveClientReturnDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/client-return-documents/approve');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом проведении документов возврата от клиента!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDisapproveClientReturnDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/client-return-documents/unApprove');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом снятии проведения документов возврата от клиента!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDeleteClientReturnDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/client-return-documents/');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом удалении документов возврата от клиента!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massRestoreClientReturnDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/client-return-documents/restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом восстановлении документов возврата от клиента!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreClientReturnDocument(
      int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final pathWithParams =
          await _appendQueryParams('/client-return-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при восстановлении документа',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingResponse> getWriteOffDocuments({
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/write-off-documents?page=$page&per_page=$perPage';

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    debugPrint("Фильтры для списания товаров: $filters");

    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        final dateFrom = filters['date_from'] as DateTime;
        path += '&date_from=${dateFrom.toIso8601String()}';
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        final dateTo = filters['date_to'] as DateTime;
        path += '&date_to=${dateTo.toIso8601String()}';
      }

      if (filters.containsKey('deleted') && filters['deleted'] != null) {
        path += '&deleted=${filters['deleted']}';
      }

      if (filters.containsKey('author_id') && filters['author_id'] != null) {
        path += '&author_id=${filters['author_id']}';
      }

      if (filters.containsKey('approved') && filters['approved'] != null) {
        path += '&approved=${filters['approved']}';
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint('ApiService: getWriteOffDocuments - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body)['result'];
        debugPrint("Полученные данные по списанию товаров: $rawData");
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных документа списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocument> getWriteOffDocumentById(int documentId) async {
    String url = '/write-off-documents/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getWriteOffDocumentById - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при получении данных документа списания!',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createWriteOffDocument({
    required String date,
    required int storageId,
    required String comment,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required bool approve,
    required int articleId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/write-off-documents');
      final response = await _postRequest(path, {
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'approve': approve,
        'article_id': articleId,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при создании документа списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteWriteOffDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams = await _appendQueryParams('/write-off-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      // Создаем чистый URI без параметров для DELETE запроса
      final cleanUri = Uri.parse('$baseUrl/write-off-documents');

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        debugPrint('ApiService: deleteWriteOffDocument - Request body: $body');
      }

      final response = await http.delete(
        cleanUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при удалении документа списания',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateWriteOffDocument({
    required int documentId,
    required String date,
    required int storageId,
    required String comment,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required int articleId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final path = await _appendQueryParams('/write-off-documents/$documentId');
      final uri = Uri.parse('$baseUrl$path');

      final body = jsonEncode({
        'date': date,
        'storage_id': storageId,
        'comment': comment,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'article_id': articleId,
      });

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при обновлении документа списания!',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveWriteOffDocument(int documentId) async {
    const String url = '/write-off-documents/approve';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) 'Токен не найден';

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно проведен
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при проведении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unApproveWriteOffDocument(int documentId) async {
    const String url = '/write-off-documents/unApprove';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно отменено
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при отмене проведения документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreWriteOffDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) 'Токен не найден';

      final pathWithParams =
          await _appendQueryParams('/write-off-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massApproveWriteOffDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/write-off-documents/approve');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом проведении документов списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDisapproveWriteOffDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/write-off-documents/unApprove');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом снятии проведения документов списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDeleteWriteOffDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/write-off-documents/');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massRestoreWriteOffDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/write-off-documents/restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом восстановлении документов списания!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingResponse> getMovementDocuments({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
    int? approved, // Для будущего фильтра по статусу
  }) async {
    String url =
        '/movement-documents'; // Изменено с write-off-documents на movement-documents
    url += '?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (fromDate != null) {
      url += '&from=${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      url += '&to=${toDate.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getMovementDocuments - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocument> getMovementDocumentById(int documentId) async {
    String url = '/movement-documents/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getMovementDocumentById - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createMovementDocument({
    required String date,
    required int senderStorageId,
    required int recipientStorageId,
    required String comment,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required bool approve,
  }) async {
    final token = await getToken();
    if (token == null) throw 'Токен не найден';

    final path = await _appendQueryParams('/movement-documents');
    final response = await _postRequest(path, {
      'date': date,
      'sender_storage_id': senderStorageId,
      'recipient_storage_id': recipientStorageId,
      'comment': comment,
      'document_goods': documentGoods,
      'organization_id': organizationId,
      'approve': approve,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(message ?? 'Неизвестная ошибка', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> deleteMovementDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      // Используем _appendQueryParams для получения параметров, но извлекаем их для тела запроса
      final pathWithParams = await _appendQueryParams('/movement-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      // Извлекаем organization_id и sales_funnel_id из query параметров
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      // Создаем чистый URI без параметров для DELETE запроса
      final cleanUri = Uri.parse('$baseUrl/movement-documents');

      final body = jsonEncode({
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (kDebugMode) {
        debugPrint('ApiService: deleteMovementDocument - Request body: $body');
      }

      final response = await http.delete(
        cleanUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при удалении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMovementDocument({
    required int documentId,
    required String date,
    required int senderStorageId,
    required int recipientStorageId,
    required String comment,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required bool approve,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final path = await _appendQueryParams('/movement-documents/$documentId');
      final uri = Uri.parse('$baseUrl$path');

      final body = jsonEncode({
        'date': date,
        'sender_storage_id': senderStorageId,
        'recipient_storage_id': recipientStorageId,
        'comment': comment,
        'document_goods': documentGoods,
        'organization_id': organizationId,
        'approve': approve,
      });

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка обновления документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveMovementDocument(int documentId) async {
    const String url = '/movement-documents/approve';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно проведен
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? 'Ошибка при проведении документа', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unApproveMovementDocument(int documentId) async {
    const String url = '/movement-documents/unApprove';
    final path = await _appendQueryParams(url);

    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri = Uri.parse('$baseUrl$path');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'ids': [documentId]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешно отменено
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при отмене проведения документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreMovementDocument(int documentId) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final pathWithParams =
          await _appendQueryParams('/movement-documents/restore');
      final uri = Uri.parse('$baseUrl$pathWithParams');

      final body = jsonEncode({
        'ids': [documentId],
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка при восстановлении документа',
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massApproveMovementDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/movement-documents/approve');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом проведении документов перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDisapproveMovementDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/movement-documents/unApprove');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом снятии проведения документов перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massDeleteMovementDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/movement-documents/');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> massRestoreMovementDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/movement-documents/restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом восстановлении документов перемещения!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingResponse> getManufactureDocuments({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
    int? senderStorageId,
    int? recipientStorageId,
    int? status,
    int? authorId,
    int? deleted,
  }) async {
    String url = '/manufacture-documents?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (fromDate != null) {
      url += '&date_from=${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      url += '&date_to=${toDate.toIso8601String()}';
    }
    if (senderStorageId != null) {
      url += '&storage_id=$senderStorageId';
    }
    if (recipientStorageId != null) {
      url += '&recipient_storage_id=$recipientStorageId';
    }
    if (status != null) {
      url += '&status=$status';
    }
    if (authorId != null) {
      url += '&author_id=$authorId';
    }
    if (deleted != null) {
      url += '&deleted=$deleted';
    }

    final path = await _appendQueryParams(url);

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingResponse.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных производства!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<IncomingDocument> getManufactureDocumentById(int documentId) async {
    final path = await _appendQueryParams('/manufacture-documents/$documentId');

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return IncomingDocument.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении документа производства!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createManufactureDocument({
    required String date,
    required int senderStorageId,
    required int recipientStorageId,
    required String comment,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required bool approve,
  }) async {
    final path = await _appendQueryParams('/manufacture-documents');
    final response = await _postRequest(path, {
      'date': date,
      'storage_id': senderStorageId,
      'recipient_storage_id': recipientStorageId,
      'comment': comment,
      'document_goods': documentGoods,
      'organization_id': organizationId,
      'approve': approve,
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(message ?? 'Неизвестная ошибка', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> deleteManufactureDocument(int documentId) async {
    try {
      final pathWithParams = await _appendQueryParams('/manufacture-documents');
      final uri = Uri.parse('$baseUrl$pathWithParams');
      final organizationId = uri.queryParameters['organization_id'];
      final salesFunnelId = uri.queryParameters['sales_funnel_id'];

      final response = await _deleteRequestWithBody('/manufacture-documents', {
        'ids': [documentId],
        'organization_id': organizationId ?? '1',
        'sales_funnel_id': salesFunnelId ?? '1',
      });

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      }

      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка при удалении документа производства',
        response.statusCode,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateManufactureDocument({
    required int documentId,
    required String date,
    required int senderStorageId,
    required int recipientStorageId,
    required String comment,
    required List<Map<String, dynamic>> documentGoods,
    required int organizationId,
    required bool approve,
  }) async {
    final path = await _appendQueryParams('/manufacture-documents/$documentId');
    final uri = Uri.parse('$baseUrl$path');

    final body = jsonEncode({
      'date': date,
      'storage_id': senderStorageId,
      'recipient_storage_id': recipientStorageId,
      'comment': comment,
      'document_goods': documentGoods,
      'organization_id': organizationId,
      'approve': approve,
    });

    final token = await getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Device': 'mobile',
      },
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка обновления документа производства',
        response.statusCode,
      );
    }
  }

  Future<void> approveManufactureDocument(int documentId) async {
    final path = await _appendQueryParams('/manufacture-documents/approve');
    final response = await _postRequest(path, {
      'ids': [documentId],
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка при проведении документа производства',
        response.statusCode,
      );
    }
  }

  Future<void> unApproveManufactureDocument(int documentId) async {
    final path = await _appendQueryParams('/manufacture-documents/unApprove');
    final response = await _postRequest(path, {
      'ids': [documentId],
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка при отмене проведения документа производства',
        response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> restoreManufactureDocument(
      int documentId) async {
    final path = await _appendQueryParams('/manufacture-documents/restore');
    final response = await _postRequest(path, {
      'ids': [documentId],
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'result': 'Success'};
    }

    final message = _extractErrorMessageFromResponse(response);
    throw ApiException(
      message ?? 'Ошибка при восстановлении документа производства',
      response.statusCode,
    );
  }

  Future<void> massApproveManufactureDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/manufacture-documents/approve');
    final response = await _postRequest(path, {'ids': ids});

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка при массовом проведении документов производства!',
        response.statusCode,
      );
    }
  }

  Future<void> massDisapproveManufactureDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/manufacture-documents/unApprove');
    final response = await _postRequest(path, {'ids': ids});

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ??
            'Ошибка при массовом снятии проведения документов производства!',
        response.statusCode,
      );
    }
  }

  Future<void> massDeleteManufactureDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/manufacture-documents/');
    final response = await _deleteRequestWithBody(path, {'ids': ids});

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка при массовом удалении документов производства!',
        response.statusCode,
      );
    }
  }

  Future<void> massRestoreManufactureDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/manufacture-documents/restore');
    final response = await _postRequest(path, {'ids': ids});

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ??
            'Ошибка при массовом восстановлении документов производства!',
        response.statusCode,
      );
    }
  }

  Future<ManufactureReportResponse> getManufactureGoodsReport({
    int? page,
    int? perPage,
    Map<String, dynamic>? filters,
    String? search,
  }) async {
    try {
      final queryParams = _buildDetailedDashboardCommonParams(
        page: page,
        perPage: perPage,
        filters: filters,
        search: search,
      );

      var path =
          await _appendQueryParams('/dashboard/manufacture-goods-report');
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';

      final response = await _getRequest(path);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ManufactureReportResponse.fromJson(data);
      }

      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка при получении отчета производства!',
        response.statusCode,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<ManufactureMaterialsReportResponse> getManufactureMaterialsReport({
    int? page,
    int? perPage,
    Map<String, dynamic>? filters,
    String? search,
  }) async {
    try {
      final queryParams = _buildDetailedDashboardCommonParams(
        page: page,
        perPage: perPage,
        filters: filters,
        search: search,
      );

      var path =
          await _appendQueryParams('/dashboard/manufacture-materials-report');
      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';

      final response = await _getRequest(path);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ManufactureMaterialsReportResponse.fromJson(data);
      }

      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка при получении отчета расхода сырья!',
        response.statusCode,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<List<ArticleGood>> getAllExpenseArticles() async {
    final path = await _appendQueryParams('/article?type=expense');

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['result']['data'] != null) {
          List<ArticleGood> articles = [];
          for (var item in data['result']['data']) {
            articles.add(ArticleGood.fromJson(item));
          }
          return articles;
        } else {
          final message = _extractErrorMessageFromResponse(response);
          throw ApiException(
            message ?? 'Ошибка при получении данных прихода!',
            response.statusCode,
          );
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw message ?? 'Ошибка при получении данных!';
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получить первоначальные остатки по товарам
  Future<GoodsOpeningsResponse> getGoodsOpenings({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    String path = await _appendQueryParams('/good-initial-balance');

    path += '&is_service=0&page=$page&per_page=$perPage';

    // Добавляем параметр search, если он передан
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    if (kDebugMode) {
      debugPrint('ApiService: getGoodsOpenings - path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return GoodsOpeningsResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка получения первоначальных остатков по товарам',
        response.statusCode,
      );
    }
  }

  /// Удалить первоначальный остаток товара
  Future<Map<String, dynamic>> deleteGoodsOpening(int id) async {
    try {
      String path = await _appendQueryParams('/good-initial-balance/$id');
      final response = await _deleteRequest(path);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? "Ошибка удаления остатка товара", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создать первоначальный остаток товара
  Future<Map<String, dynamic>> createGoodsOpening({
    required int goodVariantId,
    required int supplierId,
    required double price,
    required double quantity,
    required int unitId,
    required int storageId,
  }) async {
    try {
      String path = await _appendQueryParams('/good-initial-balance');

      final body = {
        "data": [
          {
            "good_variant_id": goodVariantId,
            "supplier_id": supplierId,
            "price": price,
            "quantity": quantity,
            "unit_id": unitId,
            "storage_id": storageId,
          }
        ],
      };

      if (kDebugMode) {
        debugPrint('ApiService: createGoodsOpening - path: $path');
        debugPrint('ApiService: createGoodsOpening - body: $body');
      }

      final response = await _postRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка создания остатка товара",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Обновить первоначальный остаток товара
  Future<Map<String, dynamic>> updateGoodsOpening({
    required int id,
    required int goodVariantId,
    required int supplierId,
    required double price,
    required double quantity,
    required int unitId,
    required int storageId,
  }) async {
    try {
      String path = await _appendQueryParams('/good-initial-balance/$id');

      final body = {
        "good_variant_id": goodVariantId,
        "supplier_id": supplierId,
        "price": price,
        "quantity": quantity,
        "unit_id": unitId,
        "storage_id": storageId,
      };

      if (kDebugMode) {
        debugPrint('ApiService: updateGoodsOpening - path: $path');
        debugPrint('ApiService: updateGoodsOpening - body: $body');
      }

      final response = await _patchRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка обновления остатка товара",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получить первоначальные остатки по клиентам
  Future<ClientOpeningsResponse> getClientOpenings({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    String path = await _appendQueryParams('/initial-balance/lead');

    path += '&page=$page&per_page=$perPage';

    // Добавляем параметр search, если он передан
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    if (kDebugMode) {
      debugPrint('ApiService: getClientOpenings - path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ClientOpeningsResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка получения первоначальных остатков по клиентам',
        response.statusCode,
      );
    }
  }

  /// Получить список клиентов/лидов для диалога выбора
  Future<List<opening_lead.Lead>> getClientOpeningsForDialog(
      {String? search}) async {
    try {
      String path = await _appendQueryParams('/initial-balance/get/leads');
      if (search != null && search.trim().isNotEmpty) {
        path += '&search=${Uri.encodeComponent(search.trim())}';
      }
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Проверяем, является ли ответ массивом (API возвращает массив напрямую)
        if (data is List) {
          // Преобразуем массив в ожидаемую структуру
          return data
              .map<opening_lead.Lead>(
                  (item) => opening_lead.Lead.fromJson(item))
              .toList();
        } else {
          return [];
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка получения списка клиентов",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить первоначальный остаток клиента
  Future<Map<String, dynamic>> deleteClientOpening(int id) async {
    try {
      String path = await _appendQueryParams('/initial-balance/$id');
      final response = await _deleteRequest(path);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? "Ошибка удаления остатка клиента", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создать первоначальный остаток клиента
  Future<Map<String, dynamic>> createClientOpening({
    required int leadId,
    required double ourDuty,
    required double debtToUs,
  }) async {
    try {
      String path = await _appendQueryParams('/initial-balance');

      final body = {
        'data': [
          {
            "type": "lead",
            "counterparty_id": leadId,
            "our_duty": ourDuty,
            "debt_to_us": debtToUs,
          }
        ]
      };

      if (kDebugMode) {
        debugPrint('ApiService: createClientOpening - path: $path');
        debugPrint('ApiService: createClientOpening - body: $body');
      }

      final response = await _postRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка создания остатка клиента",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Создать первоначальный остаток клиента
  Future<Map<String, dynamic>> updateClientOpening({
    required int id,
    required int leadId,
    required double ourDuty,
    required double debtToUs,
  }) async {
    try {
      String path = await _appendQueryParams('/initial-balance/$id');

      final body = {
        "type": "lead",
        "counterparty_id": leadId,
        "our_duty": ourDuty,
        "debt_to_us": debtToUs,
      };

      if (kDebugMode) {
        debugPrint('ApiService: createClientOpening - path: $path');
        debugPrint('ApiService: createClientOpening - body: $body');
      }

      final response = await _patchRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка создания остатка клиента",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получить первоначальные остатки по поставщикам
  Future<SupplierOpeningsResponse> getSupplierOpenings({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    String path = await _appendQueryParams('/initial-balance/supplier');

    path += '&page=$page&per_page=$perPage';

    // Добавляем параметр search, если он передан
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    if (kDebugMode) {
      debugPrint('ApiService: getSupplierOpenings - path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SupplierOpeningsResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка получения первоначальных остатков по поставщикам',
        response.statusCode,
      );
    }
  }

  /// Создать первоначальный остаток поставщика
  Future<Map<String, dynamic>> createSupplierOpening({
    required int supplierId,
    required double ourDuty,
    required double debtToUs,
  }) async {
    try {
      String path = await _appendQueryParams('/initial-balance');

      final body = {
        'data': [
          {
            "type": "supplier",
            "counterparty_id": supplierId,
            "our_duty": ourDuty,
            "debt_to_us": debtToUs,
          }
        ]
      };

      if (kDebugMode) {
        debugPrint('ApiService: createSupplierOpening - path: $path');
        debugPrint('ApiService: createSupplierOpening - body: $body');
      }

      final response = await _postRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка создания остатка поставщика",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Редактировать начальный остаток поставщика
  Future<Map<String, dynamic>> editSupplierOpening({
    required int id,
    required int supplierId,
    required double ourDuty,
    required double debtToUs,
  }) async {
    try {
      String path = await _appendQueryParams('/initial-balance/$id');

      final body = {
        "type": "supplier",
        "counterparty_id": supplierId,
        "our_duty": ourDuty,
        "debt_to_us": debtToUs,
      };

      if (kDebugMode) {
        debugPrint('ApiService: editSupplierOpening - path: $path');
        debugPrint('ApiService: editSupplierOpening - body: $body');
      }

      final response = await _patchRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка редактирования остатка поставщика",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить первоначальный остаток поставщика
  Future<Map<String, dynamic>> deleteSupplierOpening(int id) async {
    try {
      String path = await _appendQueryParams('/initial-balance/$id');
      final response = await _deleteRequest(path);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? "Ошибка удаления остатка поставщика",
            response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получить список поставщиков для диалога выбора
  Future<opening_supplier.SuppliersForOpeningsResponse> getOpeningsSuppliers(
      {String? search}) async {
    try {
      String path = await _appendQueryParams('/initial-balance/get/suppliers');
      if (search != null && search.trim().isNotEmpty) {
        path += '&search=${Uri.encodeComponent(search.trim())}';
      }
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Проверяем, является ли ответ массивом (API возвращает массив напрямую)
        if (data is List) {
          // Преобразуем массив в ожидаемую структуру
          return opening_supplier.SuppliersForOpeningsResponse.fromJson({
            'result': data,
            'errors': null,
          });
        } else {
          // Если ответ уже в правильном формате (с полем result)
          return opening_supplier.SuppliersForOpeningsResponse.fromJson(data);
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? "Ошибка получения списка поставщиков",
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

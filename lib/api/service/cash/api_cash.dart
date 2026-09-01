part of '../api_service.dart';

extension ApiCashX on ApiService {
  Future<CashRegisterResponseModel> getCashRegister({
    int page = 1,
    int perPage = 15,
    String? query,
  }) async {
    String url = '/cashRegister?page=$page&per_page=$perPage';

    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('🔵 ApiService: getCashRegister - path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (kDebugMode) {
        debugPrint(
            '🔵 ApiService: getCashRegister - statusCode: ${response.statusCode}');
        debugPrint(
            '🔵 ApiService: getCashRegister - body length: ${response.body.length}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint('🔵 ApiService: getCashRegister - JSON decoded');
          debugPrint(
              '🔵 ApiService: getCashRegister - keys: ${data is Map ? (data as Map).keys.toList() : "not a map"}');
          if (data is Map && data['result'] != null) {
            final result = data['result'];
            debugPrint(
                '🔵 ApiService: getCashRegister - result type: ${result.runtimeType}');
            if (result is Map) {
              debugPrint(
                  '🔵 ApiService: getCashRegister - result keys: ${result.keys.toList()}');
              if (result['data'] != null) {
                debugPrint(
                    '🔵 ApiService: getCashRegister - data type: ${result['data'].runtimeType}');
                if (result['data'] is List) {
                  debugPrint(
                      '🔵 ApiService: getCashRegister - data length: ${(result['data'] as List).length}');
                  if ((result['data'] as List).isNotEmpty) {
                    final first = (result['data'] as List)[0];
                    if (first is Map) {
                      debugPrint(
                          '🔵 ApiService: getCashRegister - first item keys: ${first.keys.toList()}');
                      if (first['users'] != null) {
                        debugPrint(
                            '🔵 ApiService: getCashRegister - first item users type: ${first['users'].runtimeType}');
                        if (first['users'] is List &&
                            (first['users'] as List).isNotEmpty) {
                          final firstUser = (first['users'] as List)[0];
                          if (firstUser is Map) {
                            debugPrint(
                                '🔵 ApiService: getCashRegister - first user keys: ${firstUser.keys.toList()}');
                            debugPrint(
                                '🔵 ApiService: getCashRegister - first user job_title: ${firstUser['job_title']} (type: ${firstUser['job_title'].runtimeType})');
                          }
                        }
                      }
                    }
                  }
                }
              }
              if (result['pagination'] != null) {
                debugPrint(
                    '🔵 ApiService: getCashRegister - pagination keys: ${(result['pagination'] as Map).keys.toList()}');
              }
            }
          }
        }

        if (data['result'] != null) {
          if (kDebugMode) {
            debugPrint(
                '🔵 ApiService: getCashRegister - calling CashRegisterResponseModel.fromJson');
          }
          final parsed = CashRegisterResponseModel.fromJson(data['result']);
          if (kDebugMode) {
            debugPrint(
                '🔵 ApiService: getCashRegister - parsed successfully, count: ${parsed.data.length}');
          }
          return parsed;
        } else {
          if (kDebugMode) {
            debugPrint(
                '🔴 ApiService: getCashRegister - data["result"] is null');
          }
          throw Exception('Нет данных по кассе');
        }
      } else {
        final data = json.decode(response.body);
        if (kDebugMode) {
          debugPrint(
              '🔴 ApiService: getCashRegister - error status: ${response.statusCode}');
        }
        if (data['errors'] != null) {
          throw Exception(data['errors'] ?? 'Ошибка загрузки кассы');
        } else {
          throw Exception('Ошибка загрузки кассы: ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔴 ApiService: getCashRegister - EXCEPTION: $e');
        debugPrint('🔴 ApiService: getCashRegister - STACK: $stackTrace');
      }
      throw Exception('Ошибка получения данных кассы: $e');
    }
  }

  Future<CashRegisterDetailsResponse> getCashRegisterDetails(
    int id, {
    int page = 1,
    int perPage = 20,
  }) async {
    final path = await _appendQueryParams(
      '/cashRegister/$id?page=$page&per_page=$perPage',
    );

    if (kDebugMode) {
      debugPrint('ApiService: getCashRegisterDetails - path: $path');
    }

    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = SafeConverters.toMapOrNull(data['result']);
      if (result == null) {
        throw Exception('Нет данных по кассе');
      }
      return CashRegisterDetailsResponse.fromJson(result);
    }

    final message = _extractErrorMessageFromResponse(response);
    throw ApiException(
      message ?? 'Ошибка загрузки кассы',
      response.statusCode,
    );
  }

  Future<CashRegisterModel> postCashRegister(AddCashDeskModel value) async {
    final response = await _postRequest('/cashRegister', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return CashRegisterModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка добавления в кассу');
      } else {
        throw Exception('Ошибка добавления в кассу: ${response.body}');
      }
    }
  }
  Future<bool> deleteCashRegister(int id) async {
    final response = await _deleteRequest('/cashRegister/$id');
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      return SafeConverters.toBool(data['result']['deleted']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка удаления кассы');
      } else {
        throw Exception('Ошибка удаления кассы: ${response.body}');
      }
    }
  }

  Future<CashRegisterModel> patchCashRegister(
      int id, AddCashDeskModel value) async {
    final response = await _patchRequest('/cashRegister/$id', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return CashRegisterModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка добавления в кассу');
      } else {
        throw Exception('Ошибка добавления в кассу: ${response.body}');
      }
    }
  }

  Future<ExpenseResponseModel> getExpenses({
    int page = 1,
    int perPage = 15,
    String? query,
  }) async {
    String url = '/article?type=expense&page=$page&per_page=$perPage';

    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getExpenses - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          return ExpenseResponseModel.fromJson(data['result']);
        } else {
          throw Exception('Нет данных по расходам');
        }
      } else {
        final data = json.decode(response.body);
        if (data['errors'] != null) {
          throw Exception(data['errors'] ?? 'Ошибка загрузки расходов');
        } else {
          throw Exception('Ошибка загрузки расходов: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Ошибка получения данных расходов: $e');
    }
  }

  Future<ExpenseModel> postExpense(AddExpenseModel value) async {
    final response = await _postRequest('/article', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return ExpenseModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка добавления расхода');
      } else {
        throw Exception('Ошибка добавления расхода: ${response.body}');
      }
    }
  }

  Future<bool> deleteExpense(int id) async {
    final response = await _deleteRequest('/article/$id');
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      return SafeConverters.toBool(data['result']['deleted']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка удаления расхода');
      } else {
        throw Exception('Ошибка удаления расхода: ${response.body}');
      }
    }
  }

  Future<ExpenseModel> patchExpense(int id, AddExpenseModel value) async {
    final response = await _patchRequest('/article/$id', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return ExpenseModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка обновления расхода');
      } else {
        throw Exception('Ошибка обновления расхода: ${response.body}');
      }
    }
  }

  Future<IncomeResponseModel> getIncomes({
    int page = 1,
    int perPage = 15,
    String? query,
  }) async {
    String url = '/article?type=income&page=$page&per_page=$perPage';

    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getIncomes - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          return IncomeResponseModel.fromJson(data['result']);
        } else {
          throw Exception('Нет данных по доходам');
        }
      } else {
        final data = json.decode(response.body);
        if (data['errors'] != null) {
          throw Exception(data['errors'] ?? 'Ошибка загрузки доходов');
        } else {
          throw Exception('Ошибка загрузки доходов: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Ошибка получения данных доходов: $e');
    }
  }

  Future<IncomeModel> postIncome(AddIncomeModel value) async {
    final response = await _postRequest('/article', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return IncomeModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка добавления дохода');
      } else {
        throw Exception('Ошибка добавления дохода: ${response.body}');
      }
    }
  }

  Future<bool> deleteIncome(int id) async {
    final response = await _deleteRequest('/article/$id');
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      return SafeConverters.toBool(data['result']['deleted']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка удаления дохода');
      } else {
        throw Exception('Ошибка удаления дохода: ${response.body}');
      }
    }
  }

  Future<IncomeModel> patchIncome(int id, AddIncomeModel value) async {
    final response = await _patchRequest('/article/$id', value.toJson());
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return IncomeModel.fromJson(data['result']);
    } else {
      if (data['errors'] != null) {
        throw Exception(data['errors'] ?? 'Ошибка обновления дохода');
      } else {
        throw Exception('Ошибка обновления дохода: ${response.body}');
      }
    }
  }

  Future<CashRegistersDataResponse> getAllCashRegisters() async {
    final allRegisters = <CashRegisterData>[];
    var page = 1;
    var totalPages = 1;

    do {
      final path = await _appendQueryParams(
        '/cashRegister?page=$page&per_page=100',
      );
      final response = await _getRequest(path);
      if (response.statusCode != 200) {
        throw Exception('Ошибка при получении данных!');
      }

      final data = json.decode(response.body);
      if (data['result'] == null) {
        throw Exception('Результат отсутствует в ответе');
      }

      final pageResponse = CashRegistersDataResponse.fromJson(data);
      allRegisters.addAll(pageResponse.result ?? const []);

      final pagination = SafeConverters.toMapOrNull(
        SafeConverters.toMapOrNull(data['result'])?['pagination'],
      );
      totalPages = SafeConverters.toInt(
        pagination?['total_pages'],
        defaultValue: 1,
      );
      if (totalPages < 1) totalPages = 1;
      page++;
    } while (page <= totalPages);

    return CashRegistersDataResponse(result: allRegisters);
  }

  Future<IncomeCategoriesDataResponse> getAllIncomeCategories() async {
    final path = await _appendQueryParams('/article?type=income');

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          return IncomeCategoriesDataResponse.fromJson(data);
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

  Future<void> createMoneyIncomeDocument({
    required String date,
    required num amount,
    required String operationType,
    required String movementType,
    String? comment,
    int? leadId,
    int? articleId,
    int? senderCashRegisterId,
    int? cashRegisterId,
    int? supplierId,
    required bool approve,
    double? exchangeRate,
  }) async {
    final path = await _appendQueryParams('/checking-account');

    try {
      final resolvedOrganizationId = await resolveSelectedOrganizationId();
      final response = await _postRequest(path, {
        'date': date,
        'amount': amount,
        'operation_type': operationType,
        'movement_type': movementType,
        'lead_id': leadId,
        'article_id': articleId,
        'sender_cash_register_id': senderCashRegisterId,
        'comment': comment,
        'cash_register_id': cashRegisterId,
        'supplier_id': supplierId,
        'approved': approve,
        'organization_id': resolvedOrganizationId,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при создании документа прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MoneyIncomeDocumentModel> getMoneyIncomeDocuments({
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/checking-account?type=PKO&page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    debugPrint("Фильтры для прихода: $filters");

    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        final dateFrom = filters['date_from'] as DateTime;
        path += '&date_from=${dateFrom.toIso8601String()}';
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        final dateTo = filters['date_to'] as DateTime;
        path += "&date_to=${dateTo.toIso8601String()}";
      }

      if (filters.containsKey('deleted') && filters['deleted'] != null) {
        path += '&deleted=${filters['deleted']}';
      }

      if (filters.containsKey('lead_id') && filters['lead_id'] != null) {
        path += '&lead_id=${filters['lead_id']}';
      }

      if (filters.containsKey('cash_register_id') &&
          filters['cash_register_id'] != null) {
        path += '&cash_register_id=${filters['cash_register_id']}';
      }

      if (filters.containsKey('supplier_id') &&
          filters['supplier_id'] != null) {
        path += '&supplier_id=${filters['supplier_id']}';
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
      debugPrint('ApiService: getMoneyIncomeDocuments - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученные данные по приходу: $rawData");
        return MoneyIncomeDocumentModel.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteMoneyIncomeDocument(int documentId) async {
    final path = await _appendQueryParams('/checking-account/mass-delete');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': [documentId],
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при удалении документа прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreMoneyIncomeDocument(
      int documentId) async {
    final token = await getToken();
    if (token == null) throw Exception('Токен не найден');

    final pathWithParams =
        await _appendQueryParams('/checking-account/restore');
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
      final jsonResponse = jsonDecode(response.body);
      throw Exception(
          jsonResponse['message'] ?? 'Ошибка при восстановлении документа');
    }
  }

  Future<void> updateMoneyIncomeDocument({
    required int documentId,
    required String date,
    required num amount,
    required String operationType,
    required String movementType,
    String? comment,
    int? leadId,
    int? articleId,
    int? senderCashRegisterId,
    int? cashRegisterId,
    int? supplierId,
    double? exchangeRate,
  }) async {
    final path = await _appendQueryParams('/checking-account/$documentId');

    try {
      final resolvedOrganizationId = await resolveSelectedOrganizationId();
      final response = await _patchRequest(path, {
        'date': date,
        'amount': amount,
        'operation_type': operationType,
        'movement_type': movementType,
        'lead_id': leadId,
        'article_id': articleId,
        'sender_cash_register_id': senderCashRegisterId,
        'comment': comment,
        'cash_register_id': cashRegisterId,
        'supplier_id': supplierId,
        'organization_id': resolvedOrganizationId,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученные данные по обновлению прихода: $rawData");
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при обновлении документа прихода!',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Ошибка при обновлении документа прихода: $e");
      rethrow;
    }
  }

  Future<void> masApproveMoneyIncomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-approve');

    try {
      final response = await _patchRequest(path, {
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

  Future<void> toggleApproveOneMoneyIncomeDocument(int id, bool approve) async {
    final path = approve
        ? await _appendQueryParams('/checking-account/mass-approve')
        : await _appendQueryParams('/checking-account/mass-unapprove');

    try {
      final response = await _patchRequest(path, {
        'ids': [id],
      });

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 201) {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при изменении статуса документа прихода!',
          response.statusCode,
        );
      }

      return;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> masDisapproveMoneyIncomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-unapprove');

    try {
      final response = await _patchRequest(path, {
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

  Future<void> masDeleteMoneyIncomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-delete');

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

  Future<void> masRestoreMoneyIncomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-restore');

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

  Future<OutcomeCategoriesDataResponse> getAllOutcomeCategories() async {
    final path = await _appendQueryParams('/article?type=expense');

    final response = await _getRequest(path);
    ;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return OutcomeCategoriesDataResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw message ?? 'Ошибка при получении данных!';
      }
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw message ?? 'Ошибка при получении данных!';
    }
  }

  Future<void> createMoneyOutcomeDocument({
    required String date,
    required num amount,
    required String operationType,
    required String movementType,
    String? comment,
    int? leadId,
    int? articleId,
    int? senderCashRegisterId,
    int? cashRegisterId,
    int? supplierId,
    int? employeeId,
    String? month,
    required bool approve,
    double? exchangeRate,
  }) async {
    final path = await _appendQueryParams('/checking-account');

    try {
      final resolvedOrganizationId = await resolveSelectedOrganizationId();
      final response = await _postRequest(path, {
        'date': date,
        'amount': amount,
        'operation_type': operationType,
        'movement_type': movementType,
        'lead_id': leadId,
        'article_id': articleId,
        'sender_cash_register_id': senderCashRegisterId,
        'comment': comment,
        'cash_register_id': cashRegisterId,
        'supplier_id': supplierId,
        'employee_id': employeeId,
        'month': month,
        'approved': approve,
        'organization_id': resolvedOrganizationId,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при создании документа расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MoneyOutcomeDocumentModel> getMoneyOutcomeDocuments({
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/checking-account?type=RKO&page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    debugPrint("Фильтры для расхода: $filters");

    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        final dateFrom = filters['date_from'] as DateTime;
        path += '&date_from=${dateFrom.toIso8601String()}';
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        final dateTo = filters['date_to'] as DateTime;
        path += "&date_to=${dateTo.toIso8601String()}";
      }

      if (filters.containsKey('deleted') && filters['deleted'] != null) {
        path += '&deleted=${filters['deleted']}';
      }

      if (filters.containsKey('lead_id') && filters['lead_id'] != null) {
        path += '&lead_id=${filters['lead_id']}';
      }

      if (filters.containsKey('cash_register_id') &&
          filters['cash_register_id'] != null) {
        path += '&cash_register_id=${filters['cash_register_id']}';
      }

      if (filters.containsKey('supplier_id') &&
          filters['supplier_id'] != null) {
        path += '&supplier_id=${filters['supplier_id']}';
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
      debugPrint(
          'ApiService: getMoneyOutcomeDocuments - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученные данные по расход: $rawData");
        return MoneyOutcomeDocumentModel.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteMoneyOutcomeDocument(int documentId) async {
    final path = await _appendQueryParams('/checking-account/mass-delete');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': [documentId],
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при удалении документа расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> restoreMoneyOutcomeDocument(int documentId) async {
    final path = await _appendQueryParams('/checking-account/mass-restore');

    try {
      final response = await _postRequest(path, {
        'ids': [documentId],
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при восстановлении документа расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMoneyOutcomeDocument({
    required int documentId,
    required String date,
    required num amount,
    required String operationType,
    required String movementType,
    String? comment,
    int? leadId,
    int? articleId,
    int? senderCashRegisterId,
    int? cashRegisterId,
    int? supplierId,
    int? employeeId,
    String? month,
    double? exchangeRate,
  }) async {
    final path = await _appendQueryParams('/checking-account/$documentId');

    try {
      final resolvedOrganizationId = await resolveSelectedOrganizationId();
      final response = await _patchRequest(path, {
        'date': date,
        'amount': amount,
        'operation_type': operationType,
        'movement_type': movementType,
        'lead_id': leadId,
        'article_id': articleId,
        'sender_cash_register_id': senderCashRegisterId,
        'comment': comment,
        'cash_register_id': cashRegisterId,
        'supplier_id': supplierId,
        'employee_id': employeeId,
        'month': month,
        'organization_id': resolvedOrganizationId,
        if (exchangeRate != null) 'exchange_rate': exchangeRate,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = json.decode(response.body);
        debugPrint("Полученные данные по обновлению расхода: $rawData");
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при обновлении документа расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Ошибка при обновлении документа расхода: $e");
      rethrow;
    }
  }

  Future<void> masApproveMoneyOutcomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-approve');

    try {
      final response = await _patchRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleApproveOneMoneyOutcomeDocument(
      int id, bool approve) async {
    final path = approve
        ? await _appendQueryParams('/checking-account/mass-approve')
        : await _appendQueryParams('/checking-account/mass-unapprove');

    try {
      final response = await _patchRequest(path, {
        'ids': [id],
      });

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 201) {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при изменении статуса документа расхода!',
          response.statusCode,
        );
      }

      return;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> masDisapproveMoneyOutcomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-unapprove');

    try {
      final response = await _patchRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ??
              'Ошибка при массовом снятии проведения документов расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> masDeleteMoneyOutcomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-delete');

    try {
      final response = await _deleteRequestWithBody(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом удалении документов расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> masRestoreMoneyOutcomeDocuments(List<int> ids) async {
    final path = await _appendQueryParams('/checking-account/mass-restore');

    try {
      final response = await _postRequest(path, {
        'ids': ids,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при массовом восстановлении документов расхода!',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Получение списка должников
  Future<DebtorsResponse> getDebtorsList({
    int? page,
    int? perPage,
    Map<String, dynamic>? filters,
    String? search,
  }) async {
    try {
      // Формируем параметры запроса
      Map<String, String> queryParams = {};

      if (page != null) queryParams['page'] = page.toString();
      if (perPage != null) queryParams['per_page'] = perPage.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (filters != null) {
        if (filters.containsKey('date_from') &&
            filters['date_from'] is DateTime &&
            filters['date_from'] != null) {
          debugPrint(
              "ApiService: filters['date_from']: ${filters['date_from']}");
          final dateFrom = filters['date_from'] as DateTime;
          queryParams['date_from'] = dateFrom.toIso8601String();
        }
        if (filters.containsKey('date_to') &&
            filters['date_to'] is DateTime &&
            filters['date_to'] != null) {
          debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
          final dateTo = filters['date_to'] as DateTime;
          queryParams['date_to'] = dateTo.toIso8601String();
        }
        if (filters.containsKey('lead_id') && filters['lead_id'] != null) {
          debugPrint("ApiService: filters['lead_id']: ${filters['lead_id']}");
          queryParams['lead_id'] = filters['lead_id'].toString();
        }
        if (filters.containsKey('supplier_id') &&
            filters['supplier_id'] != null) {
          debugPrint(
              "ApiService: filters['supplier_id']: ${filters['supplier_id']}");
          queryParams['supplier_id'] = filters['supplier_id'].toString();
        }
        if (filters.containsKey('sum_from') && filters['sum_from'] != null) {
          debugPrint("ApiService: filters['sum_from']: ${filters['sum_from']}");
          queryParams['sum_from'] = filters['sum_from'].toString();
        }
        if (filters.containsKey('sum_to') && filters['sum_to'] != null) {
          debugPrint("ApiService: filters['sum_to']: ${filters['sum_to']}");
          queryParams['sum_to'] = filters['sum_to'].toString();
        }
      }

      var path = await _appendQueryParams('/fin/dashboard/debtors-list');

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
      if (kDebugMode) {
        debugPrint(
            'ApiService: getDebtorsList - Generated path: $path, filter: $filters');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DebtorsResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении списка должников!',
          response.statusCode,
        );
      }
    } catch (e) {
      throw e;
    }
  }

  /// Получение списка кредиторов
  Future<CreditorsResponse> getCreditorsList({
    int? page,
    int? perPage,
    Map<String, dynamic>? filters,
    String? search,
  }) async {
    try {
      // Формируем параметры запроса
      Map<String, String> queryParams = {};

      if (page != null) queryParams['page'] = page.toString();
      if (perPage != null) queryParams['per_page'] = perPage.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (filters != null) {
        if (filters.containsKey('date_from') &&
            filters['date_from'] is DateTime &&
            filters['date_from'] != null) {
          debugPrint(
              "ApiService: filters['date_from']: ${filters['date_from']}");
          final dateFrom = filters['date_from'] as DateTime;
          queryParams['date_from'] = dateFrom.toIso8601String();
        }
        if (filters.containsKey('date_to') &&
            filters['date_to'] is DateTime &&
            filters['date_to'] != null) {
          debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
          final dateTo = filters['date_to'] as DateTime;
          queryParams['date_to'] = dateTo.toIso8601String();
        }
        if (filters.containsKey('lead_id') && filters['lead_id'] != null) {
          debugPrint("ApiService: filters['lead_id']: ${filters['lead_id']}");
          queryParams['lead_id'] = filters['lead_id'].toString();
        }
        if (filters.containsKey('supplier_id') &&
            filters['supplier_id'] != null) {
          debugPrint(
              "ApiService: filters['supplier_id']: ${filters['supplier_id']}");
          queryParams['supplier_id'] = filters['supplier_id'].toString();
        }
        if (filters.containsKey('sum_from') && filters['sum_from'] != null) {
          debugPrint("ApiService: filters['sum_from']: ${filters['sum_from']}");
          queryParams['sum_from'] = filters['sum_from'].toString();
        }
        if (filters.containsKey('sum_to') && filters['sum_to'] != null) {
          debugPrint("ApiService: filters['sum_to']: ${filters['sum_to']}");
          queryParams['sum_to'] = filters['sum_to'].toString();
        }
      }

      var path = await _appendQueryParams('/fin/dashboard/creditors-list');

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
      if (kDebugMode) {
        debugPrint(
            'ApiService: getCreditorsList - Generated path: $path, filter: $filters');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CreditorsResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении списка кредиторов!',
          response.statusCode,
        );
      }
    } catch (e) {
      throw e;
    }
  }

  /// Получение отчета по задолженности зарплаты
  Future<SalaryReportResponse> getSalaryReport({
    int? page,
    int? perPage,
    Map<String, dynamic>? filters,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};

      queryParams['page'] = (page ?? 1).toString();
      queryParams['per_page'] = (perPage ?? 20).toString();
      queryParams['limit'] = (perPage ?? 20).toString();
      queryParams['lead_id'] = '';
      queryParams['supplier_id'] = '';
      queryParams['date_from'] = '';
      queryParams['date_to'] = '';
      queryParams['sum_from'] = '';
      queryParams['sum_to'] = '';
      queryParams['category_id'] = '';
      queryParams['days_without_movement'] = '';
      queryParams['article_id'] = '';
      queryParams['good_id'] = '';
      queryParams['status_id'] = '';
      queryParams['search'] = search?.trim() ?? '';
      queryParams['period'] = '';
      queryParams['year'] = filters?['year']?.toString() ?? '';
      queryParams['storage_id'] = '';

      var path = await _appendQueryParams('/fin/dashboard/salary-report');

      final separator = path.contains('?') ? '&' : '?';
      final encodedParams = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '$separator$encodedParams';

      if (kDebugMode) {
        debugPrint(
          'ApiService: getSalaryReport - Generated path: $path, filter: $filters',
        );
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return SalaryReportResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении отчета по задолженности зарплаты!',
          response.statusCode,
        );
      }
    } catch (e) {
      throw e;
    }
  }

  /// Получение баланса денежных средств
  Future<CashBalanceResponse> getSalesDashboardCashBalance({
    String? search,
    Map<String, dynamic>? filters,
    int? page,
    int? perPage,
  }) async {
    // try{
    // Формируем параметры запроса

    debugPrint("ApiService: getSalesDashboardCashBalance filters: $filters");

    Map<String, String> queryParams = {};
    if (page != null) queryParams['page'] = page.toString();
    if (perPage != null) queryParams['per_page'] = perPage.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filters != null) {
      if (filters.containsKey('date_from') && filters['date_from'] != null) {
        debugPrint("ApiService: filters['date_from']: ${filters['date_from']}");
        final dateFrom = filters['date_from'] as DateTime;
        queryParams['date_from'] = dateFrom.toIso8601String();
      }

      if (filters.containsKey('date_to') && filters['date_to'] != null) {
        debugPrint("ApiService: filters['date_to']: ${filters['date_to']}");
        final dateTo = filters['date_to'] as DateTime;
        queryParams['date_to'] = dateTo.toIso8601String();
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
    }

    var path = await _appendQueryParams('/fin/dashboard/cash-balance');

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

    if (kDebugMode) {
      debugPrint('ApiService: getCashBalance - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CashBalanceResponse.fromJson(data);
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Ошибка при получении баланса денежных средств!',
        response.statusCode,
      );
    }
    // } catch (e) {
    //   throw e;
    // }
  }

  Future<ActOfReconciliationResponse> getReconciliationAct({
    final String? search,
    final Map<String, dynamic>? filters,
  }) async {
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
    }

    var type = filters!['lead_id'] != null ? 'lead' : 'supplier';
    var id = filters['lead_id'] ?? filters['supplier_id'];

    var queryString = queryParams.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    var path = await _appendQueryParams(
      '/dashboard/act-of-reconciliation/$type/$id?$queryString',
    );

    debugPrint("ApiService: getReconciliationAct path: $path");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ActOfReconciliationResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении акта сверки!',
          response.statusCode,
        );
      }
    } catch (e) {
      throw e;
    }
  }
  /// Получить первоначальные остатки по кассам/складам
  Future<openings.CashRegisterOpeningsResponse> getCashRegisterOpenings({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    String path = await _appendQueryParams('/cash-register-initial-balance');

    path += '&page=$page&per_page=$perPage';

    // Добавляем параметр search, если он передан
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    if (kDebugMode) {
      debugPrint('🔵 ApiService: getCashRegisterOpenings - path: $path');
    }

    try {
      final response = await _getRequest(path);

      if (kDebugMode) {
        debugPrint(
            '🔵 ApiService: getCashRegisterOpenings - statusCode: ${response.statusCode}');
        debugPrint(
            '🔵 ApiService: getCashRegisterOpenings - body length: ${response.body.length}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint(
              '🔵 ApiService: getCashRegisterOpenings - JSON decoded successfully');
          debugPrint(
              '🔵 ApiService: getCashRegisterOpenings - JSON keys: ${data is Map ? (data as Map).keys.toList() : "not a map"}');
          if (data is Map && data["result"] != null) {
            final result = data["result"];
            debugPrint(
                '🔵 ApiService: getCashRegisterOpenings - result type: ${result.runtimeType}');
            if (result is Map) {
              debugPrint(
                  '🔵 ApiService: getCashRegisterOpenings - result keys: ${result.keys.toList()}');
              if (result["data"] != null) {
                debugPrint(
                    '🔵 ApiService: getCashRegisterOpenings - data type: ${result["data"].runtimeType}');
                if (result["data"] is List) {
                  debugPrint(
                      '🔵 ApiService: getCashRegisterOpenings - data length: ${(result["data"] as List).length}');
                  if ((result["data"] as List).isNotEmpty) {
                    debugPrint(
                        '🔵 ApiService: getCashRegisterOpenings - first item keys: ${(result["data"] as List)[0] is Map ? ((result["data"] as List)[0] as Map).keys.toList() : "not a map"}');
                  }
                }
              }
            } else if (result is List) {
              debugPrint(
                  '🔵 ApiService: getCashRegisterOpenings - result is List, length: ${result.length}');
            }
          }
        }

        final parsedResponse =
            openings.CashRegisterOpeningsResponse.fromJson(data);

        if (kDebugMode) {
          debugPrint(
              '🔵 ApiService: getCashRegisterOpenings - parsed successfully');
          debugPrint(
              '🔵 ApiService: getCashRegisterOpenings - result count: ${parsedResponse.result?.length ?? 0}');
        }

        return parsedResponse;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        if (kDebugMode) {
          debugPrint(
              '🔴 ApiService: getCashRegisterOpenings - error status: ${response.statusCode}, message: $message');
        }
        throw ApiException(
          message ??
              'Ошибка получения первоначальных остатков по кассам/складам',
          response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔴 ApiService: getCashRegisterOpenings - EXCEPTION: $e');
        debugPrint(
            '🔴 ApiService: getCashRegisterOpenings - STACK: $stackTrace');
      }
      rethrow;
    }
  }
   
  /// Получить список касс для выбора при создании остатка кассы
  Future<List<openings.CashRegister>> getCashRegisters({String? search}) async {
    try {
      String path =
          await _appendQueryParams('/initial-balance/get/cash-registers');
      if (search != null && search.trim().isNotEmpty) {
        path += '&search=${Uri.encodeComponent(search.trim())}';
      }

      if (kDebugMode) {
        debugPrint('ApiService: getCashRegisters - path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return data
              .map((json) => openings.CashRegister.fromJson(json))
              .toList();
        } else {
          throw Exception('Неожиданный формат ответа API');
        }
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка получения списка касс',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: getCashRegisters - Error: $e');
      }
      rethrow;
    }
  }

  /// Создать первоначальный остаток кассы
  Future<Map<String, dynamic>> createCashRegisterOpening({
    required int cashRegisterId,
    required String sum,
  }) async {
    try {
      String path = await _appendQueryParams('/cash-register-initial-balance');

      final body = {
        'data': [
          {
            'cash_register_id': cashRegisterId,
            'sum': sum,
          }
        ]
      };

      if (kDebugMode) {
        debugPrint(
            'ApiService: createCashRegisterOpening - path: $path, body: $body');
      }

      final response = await _postRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка создания остатка кассы',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: createCashRegisterOpening - Error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCashRegisterOpening({
    required int id,
    required int cashRegisterId,
    required String sum,
  }) async {
    try {
      String path =
          await _appendQueryParams('/cash-register-initial-balance/$id');

      final body = {
        'cash_register_id': cashRegisterId,
        'sum': sum,
      };

      if (kDebugMode) {
        debugPrint(
            'ApiService: createCashRegisterOpening - path: $path, body: $body');
      }

      final response = await _patchRequest(path, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка создания остатка кассы',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: createCashRegisterOpening - Error: $e');
      }
      rethrow;
    }
  }

  /// Удалить первоначальный остаток кассы
  Future<Map<String, dynamic>> deleteCashRegisterOpening(int id) async {
    try {
      String path =
          await _appendQueryParams('/cash-register-initial-balance/$id');
      final response = await _deleteRequest(path);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'result': 'Success'};
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
            message ?? "Ошибка удаления остатка кассы", response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }
}

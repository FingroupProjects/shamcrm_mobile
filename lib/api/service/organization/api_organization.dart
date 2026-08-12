part of '../api_service.dart';

extension ApiOrganizationX on ApiService {
  Future<List<Organization>> getOrganization() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/organization');
    if (kDebugMode) {
      //debugPrint('ApiService: getOrganization - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ////debugPrint('Тело ответа: $data'); // Для отладки

      if (data['result'] != null && data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((organization) => Organization.fromJson(organization))
            .toList();
      } else {
        throw Exception('Организация не найдено');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<String?> getSelectedOrganization() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? organizationId = prefs.getString('selectedOrganization');

      debugPrint(
          'ApiService: getSelectedOrganization - orgId: $organizationId');

      // Возвращаем null если организация не найдена или содержит 'null'
      if (organizationId == null ||
          organizationId.isEmpty ||
          organizationId == 'null') {
        debugPrint('ApiService: No valid organization found, using fallback');
        return '1'; // Дефолтная организация
      }

      return organizationId;
    } catch (e) {
      debugPrint('getSelectedOrganization error: $e');
      return '1'; // Fallback значение
    }
  }

  Future<void> saveSelectedOrganization(String organizationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedOrganization', organizationId);
    if (kDebugMode) {
      debugPrint(
          'ApiService: saveSelectedOrganization - Saved: $organizationId');
    }
  }

  Future<void> _removeOrganizationId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedOrganization');
  }

  Future<String?> getSelectedSalesFunnel() async {
    debugPrint(
        '🔍 ApiService: Getting selected sales funnel from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final funnelId = prefs.getString('selected_sales_funnel');

    if (funnelId == null || funnelId.isEmpty || funnelId == 'null') {
      debugPrint(
          '⚠️ ApiService: No valid funnel ID found in SharedPreferences');
      return null;
    }

    debugPrint('✅ ApiService: Retrieved selected funnel ID: $funnelId');
    return funnelId;
  }

  /// Гарантирует, что selected_sales_funnel сохранён до первых запросов Dashboard.
  /// Порядок: SharedPreferences -> кэш воронок -> API /sales-funnel.
  Future<String?> ensureSelectedSalesFunnelInitialized() async {
    final existing = await getSelectedSalesFunnel();
    if (existing != null && existing.isNotEmpty && existing != 'null') {
      return existing;
    }

    try {
      final cachedFunnels = await getCachedSalesFunnels();
      if (cachedFunnels.isNotEmpty) {
        final funnelId = cachedFunnels.first.id.toString();
        await saveSelectedSalesFunnel(funnelId);
        return funnelId;
      }
    } catch (e) {
      debugPrint(
          'ApiService: ensureSelectedSalesFunnelInitialized cache error: $e');
    }

    try {
      final serverFunnels = await getSalesFunnels();
      if (serverFunnels.isNotEmpty) {
        final funnelId = serverFunnels.first.id.toString();
        await saveSelectedSalesFunnel(funnelId);
        return funnelId;
      }
    } catch (e) {
      debugPrint(
          'ApiService: ensureSelectedSalesFunnelInitialized API error: $e');
    }

    return null;
  }

  Future<void> saveSelectedSalesFunnel(String funnelId) async {
    debugPrint('🔧 ApiService: Saving selected sales funnel ID: $funnelId');
    if (funnelId.isEmpty || funnelId == 'null') {
      debugPrint(
          '⚠️ ApiService: Attempting to save invalid funnelId: $funnelId');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_sales_funnel', funnelId);

    // Проверяем, что сохранилось
    final saved = prefs.getString('selected_sales_funnel');
    if (saved == funnelId) {
      debugPrint(
          '✅ ApiService: Selected sales funnel ID saved successfully: $funnelId');
    } else {
      debugPrint(
          '❌ ApiService: Failed to save funnel ID. Expected: $funnelId, Got: $saved');
    }
  }

  Future<void> saveSelectedDealSalesFunnel(String funnelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deal_selected_sales_funnel', funnelId);
    //debugPrint('ApiService: Saved deal funnel ID $funnelId to SharedPreferences');
  }

  Future<String?> getSelectedDealSalesFunnel() async {
    final prefs = await SharedPreferences.getInstance();
    final funnelId = prefs.getString('deal_selected_sales_funnel');
    //debugPrint('ApiService: Retrieved deal funnel ID $funnelId from SharedPreferences');
    return funnelId;
  }

  Future<void> saveSelectedEventSalesFunnel(String funnelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('event_selected_sales_funnel', funnelId);
    //debugPrint('ApiService: Saved event funnel ID $funnelId to SharedPreferences');
  }

  Future<String?> getSelectedEventSalesFunnel() async {
    final prefs = await SharedPreferences.getInstance();
    final funnelId = prefs.getString('event_selected_sales_funnel');
    //debugPrint('ApiService: Retrieved event funnel ID $funnelId from SharedPreferences');
    return funnelId;
  }

  Future<void> saveSelectedChatSalesFunnel(String funnelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      //debugPrint('ApiService.saveSelectedChatSalesFunnel: Saving funnelId: $funnelId');
      final success =
          await prefs.setString('selected_chat_sales_funnel', funnelId);
      //debugPrint('ApiService.saveSelectedChatSalesFunnel: Save success: $success');

      // Проверяем, что значение сохранено
      final savedFunnelId = prefs.getString('selected_chat_sales_funnel');
      //debugPrint('ApiService.saveSelectedChatSalesFunnel: Verified saved funnelId: $savedFunnelId');
      if (savedFunnelId != funnelId) {
        //debugPrint('ApiService.saveSelectedChatSalesFunnel: Warning - saved funnelId ($savedFunnelId) does not match input ($funnelId)');
      }
    } catch (e) {
      //debugPrint('ApiService.saveSelectedChatSalesFunnel: Error saving funnelId: $e');
      rethrow;
    }
  }

  Future<String?> getSelectedChatSalesFunnel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedFunnel = prefs.getString('selected_chat_sales_funnel');
      //debugPrint('ApiService.getSelectedChatSalesFunnel: Retrieved funnelId: $selectedFunnel');
      return selectedFunnel;
    } catch (e) {
      //debugPrint('ApiService.getSelectedChatSalesFunnel: Error retrieving funnelId: $e');
      return null;
    }
  }

  Future<void> cacheSalesFunnels(List<SalesFunnel> funnels) async {
    //debugPrint('ApiService: Caching sales funnels');
    final prefs = await SharedPreferences.getInstance();
    final funnelsJson = funnels.map((funnel) => funnel.toJson()).toList();
    await prefs.setString('cached_sales_funnels', json.encode(funnelsJson));
    //debugPrint('ApiService: Cached ${funnels.length} sales funnels');
  }

  Future<List<SalesFunnel>> getCachedSalesFunnels() async {
    //debugPrint('ApiService: Retrieving cached sales funnels');
    final prefs = await SharedPreferences.getInstance();
    final funnelsJson = prefs.getString('cached_sales_funnels');
    if (funnelsJson != null) {
      final List<dynamic> decoded = json.decode(funnelsJson);
      final funnels =
          decoded.map((json) => SalesFunnel.fromJson(json)).toList();
      //debugPrint(
      // 'ApiService: Retrieved ${funnels.length} cached sales funnels: $funnels');
      return funnels;
    }
    //debugPrint('ApiService: No cached sales funnels found');
    return [];
  }

  Future<void> clearCachedSalesFunnels() async {
    //debugPrint('ApiService: Clearing cached sales funnels');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_sales_funnels');
    //debugPrint('ApiService: Cached sales funnels cleared');
  }

  Future<List<SalesFunnel>> getSalesFunnels() async {
    //debugPrint('ApiService: Starting getSalesFunnels request');
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/sales-funnel');
    if (kDebugMode) {
      //debugPrint('ApiService: getSalesFunnels - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      //debugPrint(
      // 'ApiService: getSalesFunnels response status: ${response.statusCode}');
      //debugPrint('ApiService: getSalesFunnels response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        //debugPrint('ApiService: Decoded JSON data: $data');

        if (data['result'] != null && data['result'] is List) {
          List<SalesFunnel> funnels = (data['result'] as List)
              .map((funnel) => SalesFunnel.fromJson(funnel))
              .toList();
          //debugPrint('ApiService: Parsed ${funnels.length} sales funnels: $funnels');
          // Сохраняем воронки в кэш после успешной загрузки
          await cacheSalesFunnels(funnels);
          return funnels;
        } else {
          //debugPrint('ApiService: No funnels found in response');
          throw Exception('Воронки продаж не найдены');
        }
      } else {
        //debugPrint('ApiService: Failed with status code ${response.statusCode}');
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      //debugPrint('ApiService: Error in getSalesFunnels');
      rethrow;
    }
  }
}

import 'dart:convert';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderCache {
  static const String _cachedOrderStatusesKey = 'cachedOrderStatuses';
  static const String _persistentOrderCountsKey = 'persistentOrderCounts';

  // Сохранить статусы заказов в кэш
  static Future<void> cacheOrderStatuses(List<Map<String, dynamic>> orderStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedStatuses = json.encode(orderStatuses);
    await prefs.setString(_cachedOrderStatusesKey, encodedStatuses);
  }

  // Получить статусы заказов из кэша
  static Future<List<Map<String, dynamic>>> getOrderStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedOrderStatusesKey);
    if (cachedStatuses != null) {
      final List<dynamic> decodedData = json.decode(cachedStatuses);
      final statuses = decodedData.map((status) => Map<String, dynamic>.from(status)).toList();
      return statuses;
    }
    return [];
  }

  // Сохранить заказы для определенного статуса в кэш
  static Future<void> cacheOrdersForStatus(
    int? statusId, 
    List<Order> orders, {
    bool updatePersistentCount = false,
    int? actualTotalCount,
  }) async {
    if (statusId == null) return;
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedOrders_$statusId';
    final String encodedOrders = json.encode(orders.map((order) => order.toJson()).toList());
    await prefs.setString(key, encodedOrders);
    
    // КРИТИЧНО: Обновляем persistent count с РЕАЛЬНЫМ значением из API
    if (updatePersistentCount) {
      final countToSave = actualTotalCount ?? orders.length;
      await setPersistentOrderCount(statusId, countToSave);
    }
  }

  // Получить заказы для определенного статуса из кэша
  static Future<List<Order>> getOrdersForStatus(int? statusId) async {
    if (statusId == null) return [];
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedOrders_$statusId';
    final String? cachedOrders = prefs.getString(key);

    if (cachedOrders != null) {
      try {
        final List<dynamic> decodedData = json.decode(cachedOrders);
        return decodedData.map((order) => Order.fromJson(order)).toList();
      } catch (e) {
        print('Error loading orders from cache: $e');
        return [];
      }
    }
    return [];
  }

  // ======================== PERSISTENT COUNTS ========================
  
  /// Установить постоянный счётчик заказов для статуса
  static Future<void> setPersistentOrderCount(int statusId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentOrderCountsKey);
    final Map<String, int> counts = countsJson != null
        ? Map<String, int>.from(json.decode(countsJson))
        : {};
    
    counts[statusId.toString()] = count;
    await prefs.setString(_persistentOrderCountsKey, json.encode(counts));
  }
  
  /// Получить постоянный счётчик заказов для статуса
  static Future<int> getPersistentOrderCount(int statusId) async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentOrderCountsKey);
    
    if (countsJson != null) {
      try {
        final Map<String, int> counts = Map<String, int>.from(json.decode(countsJson));
        return counts[statusId.toString()] ?? 0;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
  
  /// Получить все постоянные счётчики
  static Future<Map<String, int>> getPersistentOrderCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentOrderCountsKey);
    
    if (countsJson != null) {
      try {
        return Map<String, int>.from(json.decode(countsJson));
      } catch (e) {
        return {};
      }
    }
    return {};
  }
  
  /// Очистить все постоянные счётчики
  static Future<void> clearPersistentCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_persistentOrderCountsKey);
  }
  
  /// Обновить счётчики при перемещении заказа
  static Future<void> updateOrderCountTemporary(int oldStatusId, int newStatusId) async {
    final oldCount = await getPersistentOrderCount(oldStatusId);
    final newCount = await getPersistentOrderCount(newStatusId);
    
    await setPersistentOrderCount(oldStatusId, oldCount > 0 ? oldCount - 1 : 0);
    await setPersistentOrderCount(newStatusId, newCount + 1);
  }

  /// Очистить заказы для конкретного статуса
  static Future<void> clearOrdersForStatus(int statusId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cachedOrders_$statusId');
  }

  // Очистить все кэшированные заказы
  static Future<void> clearAllOrders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final orderKeys = keys.where((key) => key.startsWith('cachedOrders_')).toList();
    for (var key in orderKeys) {
      await prefs.remove(key);
    }
  }

  // Очистить кэшированные статусы заказов и заказы
  static Future<void> clearOrderStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedOrderStatusesKey);

    List<dynamic> decodedData = [];
    if (cachedStatuses != null) {
      decodedData = json.decode(cachedStatuses);
    }

    await prefs.remove(_cachedOrderStatusesKey);

    final Set<int> statusIds = decodedData
        .where((status) => status is Map && status['id'] != null)
        .map<int>((status) => status['id'] as int)
        .toSet();
    for (var statusId in statusIds) {
      await prefs.remove('cachedOrders_$statusId');
    }
  }

  // Очистить все кэшированные данные
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedOrderStatusesKey);
  }
  
  /// РАДИКАЛЬНАЯ очистка ВСЕХ данных
  static Future<void> clearEverything() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Очищаем статусы
    await prefs.remove(_cachedOrderStatusesKey);
    
    // Очищаем все заказы
    final keys = prefs.getKeys();
    final orderKeys = keys.where((key) => key.startsWith('cachedOrders_')).toList();
    for (var key in orderKeys) {
      await prefs.remove(key);
    }
    
    // Очищаем persistent counts
    await prefs.remove(_persistentOrderCountsKey);
  }
  
  /// Очистить все данные с сохранением persistent counts
  static Future<void> clearAllData() async {
    await clearOrderStatuses();
    await clearAllOrders();
    // НЕ удаляем persistent counts!
  }
}

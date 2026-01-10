import 'dart:convert';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealCache {
  static const String _cachedDealStatusesKey = 'cachedDealStatuses';
  static const String _persistentDealCountsKey = 'persistentDealCounts';

  // Save deal statuses to cache, including deals_count
  static Future<void> cacheDealStatuses(List<Map<String, dynamic>> dealStatuses) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String encodedStatuses = json.encode(dealStatuses);
  await prefs.setString(_cachedDealStatusesKey, encodedStatuses);
  }

  // Get deal statuses from cache
 static Future<List<Map<String, dynamic>>> getDealStatuses() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? cachedStatuses = prefs.getString(_cachedDealStatusesKey);
  if (cachedStatuses != null) {
    final List<dynamic> decodedData = json.decode(cachedStatuses);
    final statuses = decodedData.map((status) => Map<String, dynamic>.from(status)).toList();
    return statuses;
  }
  return [];
}

  // Save deals for a specific status to cache
  static Future<void> cacheDealsForStatus(
    int? statusId, 
    List<Deal> deals, {
    bool updatePersistentCount = false,
    int? actualTotalCount,
  }) async {
    if (statusId == null) return;
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedDeals_$statusId';
    final String encodedDeals = json.encode(deals.map((deal) => deal.toJson()).toList());
    await prefs.setString(key, encodedDeals);
    
    // КРИТИЧНО: Обновляем persistent count с РЕАЛЬНЫМ значением из API
    if (updatePersistentCount) {
      final countToSave = actualTotalCount ?? deals.length;
      await setPersistentDealCount(statusId, countToSave);
    }
  }

  // Get deals for a specific status from cache
  static Future<List<Deal>> getDealsForStatus(int? statusId) async {
    if (statusId == null) return [];
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedDeals_$statusId';
    final String? cachedDeals = prefs.getString(key);

    if (cachedDeals != null) {
      final List<dynamic> decodedData = json.decode(cachedDeals);
      final deals = decodedData.map((deal) => Deal.fromJson(deal, statusId)).toList();
      return deals;
    }
    return [];
  }

  // ======================== PERSISTENT COUNTS ========================
  
  /// Установить постоянный счётчик сделок для статуса
  static Future<void> setPersistentDealCount(int statusId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentDealCountsKey);
    final Map<String, int> counts = countsJson != null
        ? Map<String, int>.from(json.decode(countsJson))
        : {};
    
    counts[statusId.toString()] = count;
    await prefs.setString(_persistentDealCountsKey, json.encode(counts));
  }
  
  /// Получить постоянный счётчик сделок для статуса
  static Future<int> getPersistentDealCount(int statusId) async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentDealCountsKey);
    
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
  static Future<Map<String, int>> getPersistentDealCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentDealCountsKey);
    
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
    await prefs.remove(_persistentDealCountsKey);
  }
  
  /// Обновить счётчики при перемещении сделки
  static Future<void> updateDealCountTemporary(int oldStatusId, int newStatusId) async {
    final oldCount = await getPersistentDealCount(oldStatusId);
    final newCount = await getPersistentDealCount(newStatusId);
    
    await setPersistentDealCount(oldStatusId, oldCount > 0 ? oldCount - 1 : 0);
    await setPersistentDealCount(newStatusId, newCount + 1);
  }

  /// Очистить сделки для конкретного статуса
  static Future<void> clearDealsForStatus(int? statusId) async {
    if (statusId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cachedDeals_$statusId');
  }

  // Clear all cached deals
  static Future<void> clearAllDeals() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final dealKeys = keys.where((key) => key.startsWith('cachedDeals_')).toList();
    for (var key in dealKeys) {
      await prefs.remove(key);
    }
  }

  // Clear cached deal statuses and deals
  static Future<void> clearDealStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedDealStatusesKey);

    List<dynamic> decodedData = [];
    if (cachedStatuses != null) {
      decodedData = json.decode(cachedStatuses);
    }

    await prefs.remove(_cachedDealStatusesKey);

    final Set<int> statusIds = decodedData.map<int>((status) => status['id']).toSet();
    for (var statusId in statusIds) {
      await prefs.remove('cachedDeals_$statusId');
    }
  }

  // Clear the cached data
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedDealStatusesKey);
  }
  
  /// РАДИКАЛЬНАЯ очистка ВСЕХ данных
  static Future<void> clearEverything() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Очищаем статусы
    await prefs.remove(_cachedDealStatusesKey);
    
    // Очищаем все сделки
    final keys = prefs.getKeys();
    final dealKeys = keys.where((key) => key.startsWith('cachedDeals_')).toList();
    for (var key in dealKeys) {
      await prefs.remove(key);
    }
    
    // Очищаем persistent counts
    await prefs.remove(_persistentDealCountsKey);
  }
  
  /// Очистить все данные с сохранением persistent counts
  static Future<void> clearAllData() async {
    await clearDealStatuses();
    await clearAllDeals();
    // НЕ удаляем persistent counts!
  }
}
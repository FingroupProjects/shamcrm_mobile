import 'dart:convert';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadCache {
  static const String _cachedLeadStatusesKey = 'cachedLeadStatuses';
  static const String _cachedLeadsKey = 'cachedLeads';
  static const String _persistentLeadCountsKey = 'persistentLeadCounts';

  // НОВЫЙ МЕТОД: Полная очистка всех данных (для RefreshIndicator)
  static Future<void> clearAllData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Получаем все ключи и удаляем все связанные с лидами
    final keys = prefs.getKeys();
    final leadRelatedKeys = keys.where((key) => 
      key.startsWith('cachedLeads_') || 
      key == _cachedLeadStatusesKey || 
      key == _persistentLeadCountsKey
    ).toList();

    // Удаляем все ключи
    for (var key in leadRelatedKeys) {
      await prefs.remove(key);
    }
    
    print('LeadCache: FULL DATA CLEAR - Removed ${leadRelatedKeys.length} cache keys: $leadRelatedKeys');
  }

  // Кэширование лидов для статуса БЕЗ изменения постоянного счетчика
  static Future<void> cacheLeadsForStatus(int? statusId, List<Lead> leads, {bool updatePersistentCount = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedLeads_$statusId';
    final String encodedLeads = json.encode(leads.map((lead) => lead.toJson()).toList());
    await prefs.setString(key, encodedLeads);
    
    // ВАЖНО: Обновляем постоянный счетчик ТОЛЬКО если это явно запрошено
    // Например, при первоначальной загрузке из API, но НЕ при пагинации
    if (updatePersistentCount) {
      await setPersistentLeadCount(statusId, leads.length);
      print('LeadCache: Cached leads for statusId: $statusId, count: ${leads.length} (updated persistent count)');
    } else {
      print('LeadCache: Cached leads for statusId: $statusId, count: ${leads.length} (persistent count preserved)');
    }
  }

  // Получение лидов для статуса
  static Future<List<Lead>> getLeadsForStatus(int? statusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedLeads_$statusId';
    final String? cachedLeads = prefs.getString(key);

    if (cachedLeads != null) {
      final List<dynamic> decodedData = json.decode(cachedLeads);
      return decodedData.map((lead) => Lead.fromJson(lead, statusId ?? 0)).toList();
    }
    return [];
  }

  // НОВЫЕ МЕТОДЫ ДЛЯ ПОСТОЯННЫХ СЧЕТЧИКОВ
  
  /// Устанавливает постоянный счетчик лидов для статуса
  /// Этот счетчик НЕ сбрасывается при смене статуса или перезагрузке
  static Future<void> setPersistentLeadCount(int? statusId, int count) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> counts = await getPersistentLeadCounts();
    counts['$statusId'] = count;
    await prefs.setString(_persistentLeadCountsKey, json.encode(counts));
    print('LeadCache: Set persistent count for statusId $statusId: $count');
  }

  /// Получает постоянный счетчик для конкретного статуса
  static Future<int> getPersistentLeadCount(int? statusId) async {
    final Map<String, dynamic> counts = await getPersistentLeadCounts();
    return counts['$statusId'] ?? 0;
  }

  /// Получает все постоянные счетчики
  static Future<Map<String, dynamic>> getPersistentLeadCounts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? countsJson = prefs.getString(_persistentLeadCountsKey);
    if (countsJson != null) {
      return Map<String, dynamic>.from(json.decode(countsJson));
    }
    return {};
  }

  /// Обновляет постоянные счетчики из LeadStatus объектов
  static Future<void> updatePersistentCountsFromStatuses(List<LeadStatus> leadStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> counts = {};
    
    for (var status in leadStatuses) {
      counts['${status.id}'] = status.leadsCount;
    }
    
    await prefs.setString(_persistentLeadCountsKey, json.encode(counts));
    print('LeadCache: Updated persistent counts from API: $counts');
  }

  // Временное обновление счетчика (для перемещения лидов)
  static Future<void> updateLeadCountTemporary(int oldStatusId, int newStatusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Обновляем кэшированные статусы (для совместимости)
    final String? cachedStatuses = prefs.getString(_cachedLeadStatusesKey);
    List<Map<String, dynamic>> statuses = [];

    if (cachedStatuses != null) {
      statuses = (json.decode(cachedStatuses) as List<dynamic>)
          .map((status) => Map<String, dynamic>.from(status))
          .toList();
    }

    // Обновляем счетчики в кэшированных статусах
    final oldIndex = statuses.indexWhere((status) => status['id'] == oldStatusId);
    if (oldIndex != -1 && statuses[oldIndex]['leads_count'] > 0) {
      statuses[oldIndex]['leads_count'] = statuses[oldIndex]['leads_count'] - 1;
    }

    final newIndex = statuses.indexWhere((status) => status['id'] == newStatusId);
    if (newIndex != -1) {
      statuses[newIndex]['leads_count'] = (statuses[newIndex]['leads_count'] ?? 0) + 1;
    }

    await prefs.setString(_cachedLeadStatusesKey, json.encode(statuses));

    // ВАЖНО: Также обновляем постоянные счетчики
    Map<String, dynamic> persistentCounts = await getPersistentLeadCounts();
    
    if (persistentCounts['$oldStatusId'] != null && persistentCounts['$oldStatusId'] > 0) {
      persistentCounts['$oldStatusId'] = persistentCounts['$oldStatusId'] - 1;
    }
    
    persistentCounts['$newStatusId'] = (persistentCounts['$newStatusId'] ?? 0) + 1;
    
    await prefs.setString(_persistentLeadCountsKey, json.encode(persistentCounts));
    print('LeadCache: Updated persistent counts - old: $oldStatusId (${persistentCounts['$oldStatusId']}), new: $newStatusId (${persistentCounts['$newStatusId']})');
  }

  // Перемещение лида между статусами БЕЗ автоматического обновления постоянных счетчиков
  static Future<void> moveLeadToStatus(Lead lead, int oldStatusId, int newStatusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Удаляем из старого статуса
    final String oldKey = 'cachedLeads_$oldStatusId';
    final String? oldCachedLeads = prefs.getString(oldKey);
    List<Lead> oldLeads = [];
    if (oldCachedLeads != null) {
      final List<dynamic> decodedData = json.decode(oldCachedLeads);
      oldLeads = decodedData.map((lead) => Lead.fromJson(lead, oldStatusId)).toList();
    }

    oldLeads.removeWhere((l) => l.id == lead.id);
    await prefs.setString(oldKey, json.encode(oldLeads.map((lead) => lead.toJson()).toList()));

    // Добавляем в новый статус
    final String newKey = 'cachedLeads_$newStatusId';
    final String? newCachedLeads = prefs.getString(newKey);
    List<Lead> newLeads = [];
    if (newCachedLeads != null) {
      final List<dynamic> decodedData = json.decode(newCachedLeads);
      newLeads = decodedData.map((lead) => Lead.fromJson(lead, newStatusId)).toList();
    }

    final updatedLead = Lead.fromJson(lead.toJson(), newStatusId);
    newLeads.add(updatedLead);
    await prefs.setString(newKey, json.encode(newLeads.map((lead) => lead.toJson()).toList()));

    // Обновляем счетчики только в кэшированных статусах (для совместимости)
    await updateLeadCount(oldStatusId, oldLeads.length);
    await updateLeadCount(newStatusId, newLeads.length);
    
    // КРИТИЧНО: НЕ обновляем постоянные счетчики автоматически!
    // Они должны обновляться только через специальные методы
    
    print('LeadCache: Moved lead ${lead.id}: $oldStatusId (${oldLeads.length}) -> $newStatusId (${newLeads.length}) - persistent counts preserved');
  }

  // Стандартное обновление счетчика (для совместимости)
  static Future<void> updateLeadCount(int statusId, int count) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedLeadStatusesKey);
    List<Map<String, dynamic>> statuses = [];

    if (cachedStatuses != null) {
      statuses = (json.decode(cachedStatuses) as List<dynamic>)
          .map((status) => Map<String, dynamic>.from(status))
          .toList();
    }

    final index = statuses.indexWhere((status) => status['id'] == statusId);
    if (index != -1) {
      statuses[index]['leads_count'] = count;
    } else {
      statuses.add({'id': statusId, 'title': '', 'leads_count': count});
    }

    await prefs.setString(_cachedLeadStatusesKey, json.encode(statuses));
    
    // Также обновляем постоянный счетчик
    await setPersistentLeadCount(statusId, count);
    print('LeadCache: Updated leads_count for statusId: $statusId to $count');
  }

  // Кэширование статусов с сохранением постоянных счетчиков
  static Future<void> cacheLeadStatuses(List<LeadStatus> leadStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Кэшируем статусы как обычно
    final List<Map<String, dynamic>> statusesToCache = leadStatuses.map((status) => {
      'id': status.id,
      'title': status.title,
      'leads_count': status.leadsCount,
    }).toList();
    
    await prefs.setString(_cachedLeadStatusesKey, json.encode(statusesToCache));
    
    // ВАЖНО: Обновляем постоянные счетчики из API данных
    await updatePersistentCountsFromStatuses(leadStatuses);
    
    print('LeadCache: Cached statuses and updated persistent counts: $statusesToCache');
  }

  // Получение кэшированных статусов с восстановлением постоянных счетчиков
  static Future<List<Map<String, dynamic>>> getLeadStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedLeadStatusesKey);

    if (cachedStatuses != null) {
      List<Map<String, dynamic>> statuses = (json.decode(cachedStatuses) as List<dynamic>)
          .map((status) => Map<String, dynamic>.from(status))
          .toList();
      
      // Восстанавливаем leads_count из постоянных счетчиков
      final persistentCounts = await getPersistentLeadCounts();
      for (var status in statuses) {
        final statusId = status['id'].toString();
        if (persistentCounts.containsKey(statusId)) {
          status['leads_count'] = persistentCounts[statusId];
        }
      }
      
      print('LeadCache: Retrieved statuses with persistent counts: $statuses');
      return statuses;
    }
    return [];
  }

  // Очистка всех данных
  static Future<void> clearAllLeads() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final leadKeys = keys.where((key) => key.startsWith('cachedLeads_')).toList();

    for (var key in leadKeys) {
      await prefs.remove(key);
    }
    print('LeadCache: Cleared all leads');
  }

  static Future<void> clearLeadsForStatus(int? statusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedLeads_$statusId';
    await prefs.remove(key);
    print('LeadCache: Cleared leads for statusId: $statusId');
  }

  static Future<void> clearLeadStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedLeadStatusesKey);

    List<dynamic> decodedData = [];
    if (cachedStatuses != null) {
      decodedData = json.decode(cachedStatuses);
    }

    await prefs.remove(_cachedLeadStatusesKey);

    final Set<int> statusIds = decodedData.map<int>((status) => status['id']).toSet();
    for (var statusId in statusIds) {
      await prefs.remove('cachedLeads_$statusId');
    }
    print('LeadCache: Cleared lead statuses and associated leads');
  }

  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedLeadStatusesKey);
    print('LeadCache: Cleared cache');
  }

  // ДОПОЛНИТЕЛЬНЫЙ МЕТОД: Очистка только постоянных счетчиков (если нужна полная перезагрузка)
  static Future<void> clearPersistentCounts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_persistentLeadCountsKey);
    print('LeadCache: Cleared persistent lead counts');
  }
}
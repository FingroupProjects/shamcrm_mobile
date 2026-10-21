import 'dart:convert';

import 'package:crm_task_manager/models/page_2/order_internet_store_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Кэш интеграции `mini_app_telegram_bot` для заказа.
///
/// Сервер требует `integration_id`.
/// Поле в форме скрыто, поэтому id берём заранее:
/// при входе в раздел заказов и перед сохранением заказа.
class OrderMiniAppIntegrationStore {
  static const String prefsKey = 'order_mini_app_telegram_integration';

  /// Последняя интеграция в памяти. Форма читает её без ожидания сети.
  static OrderMiniAppIntegrationSnapshot? current;

  /// Активная интеграция важнее выключенной.
  /// Пустое имя не отбрасываем: у бота `name` часто приходит пустым.
  static OrderInternetStore? pick(List<OrderInternetStore> stores) {
    final valid = stores.where((store) => store.id > 0).toList();
    if (valid.isEmpty) return null;

    for (final store in valid) {
      if (store.isActive) return store;
    }
    return valid.first;
  }

  /// Пишем id вместе с организацией и воронкой.
  /// Чужой кэш не подставим в заказ другой организации.
  static Future<void> save({
    required OrderInternetStore store,
    required String organizationId,
    required String salesFunnelId,
  }) async {
    if (store.id <= 0) return;

    final snapshot = OrderMiniAppIntegrationSnapshot(
      id: store.id,
      organizationId: organizationId,
      salesFunnelId: salesFunnelId,
      name: store.name,
      username: store.username,
      type: store.type,
      isActive: store.isActive,
    );
    current = snapshot;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, jsonEncode(snapshot.toJson()));
    } catch (error) {
      debugPrint('OrderMiniAppIntegrationStore: save error: $error');
    }
  }

  /// Id только для той же организации и воронки.
  static Future<int?> readId({
    required String organizationId,
    required String salesFunnelId,
  }) async {
    final cached = current;
    if (_matches(cached, organizationId, salesFunnelId)) {
      return cached!.id;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final snapshot = OrderMiniAppIntegrationSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (!_matches(snapshot, organizationId, salesFunnelId)) return null;

      current = snapshot;
      return snapshot.id;
    } catch (error) {
      debugPrint('OrderMiniAppIntegrationStore: read error: $error');
      return null;
    }
  }

  static bool _matches(
    OrderMiniAppIntegrationSnapshot? snapshot,
    String organizationId,
    String salesFunnelId,
  ) {
    if (snapshot == null || snapshot.id <= 0) return false;
    return snapshot.organizationId == organizationId &&
        snapshot.salesFunnelId == salesFunnelId;
  }
}

/// Сохранённый кусок ответа `/integrations`.
class OrderMiniAppIntegrationSnapshot {
  final int id;
  final String organizationId;
  final String salesFunnelId;
  final String name;
  final String username;
  final String type;
  final bool isActive;

  const OrderMiniAppIntegrationSnapshot({
    required this.id,
    required this.organizationId,
    required this.salesFunnelId,
    required this.name,
    required this.username,
    required this.type,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
      'name': name,
      'username': username,
      'type': type,
      'is_active': isActive,
    };
  }

  factory OrderMiniAppIntegrationSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderMiniAppIntegrationSnapshot(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      organizationId: (json['organization_id'] ?? '').toString(),
      salesFunnelId: (json['sales_funnel_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

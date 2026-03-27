// import 'dart:convert';
// import 'package:crm_task_manager/models/page_2/order_card.dart';
// import 'package:crm_task_manager/models/page_2/order_status_model.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class OrderCache {
//   static const String _statusesKey = 'order_statuses';
//   static const String _ordersKeyPrefix = 'orders_status_';

//   // Сохранение статусов в кэш
//   static Future<void> cacheOrderStatuses(List<Map<String, dynamic>> statuses) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_statusesKey, jsonEncode(statuses));
//     print('OrderCache: Cached statuses: $statuses');
//   }

//   // Получение статусов из кэша
//   static Future<List<Map<String, dynamic>>> getOrderStatuses() async {
//     final prefs = await SharedPreferences.getInstance();
//     final String? statusesJson = prefs.getString(_statusesKey);
//     if (statusesJson != null && statusesJson.isNotEmpty) {
//       try {
//         final List<dynamic> decoded = jsonDecode(statusesJson);
//         return decoded.cast<Map<String, dynamic>>();
//       } catch (e) {
//         print('OrderCache: Error decoding statuses: $e');
//         return [];
//       }
//     }
//     return [];
//   }

//   // Сохранение заказов для конкретного статуса
//   static Future<void> cacheOrdersForStatus(int? statusId, List<Order> orders) async {
//     final prefs = await SharedPreferences.getInstance();
//     final ordersJson = orders.map((order) => order.toJson()).toList();
//     await prefs.setString('$_ordersKeyPrefix$statusId', jsonEncode(ordersJson));
//     print('OrderCache: Cached orders for status $statusId: $ordersJson');
//   }

//   // Получение заказов из кэша для конкретного статуса
//   static Future<List<Order>> getOrdersForStatus(int? statusId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final String? ordersJson = prefs.getString('$_ordersKeyPrefix$statusId');
//     if (ordersJson != null && ordersJson.isNotEmpty) {
//       try {
//         final List<dynamic> decoded = jsonDecode(ordersJson);
//         return decoded.map((json) => Order.fromJson(json)).toList();
//       } catch (e) {
//         print('OrderCache: Error decoding orders for status $statusId: $e');
//         return [];
//       }
//     }
//     return [];
//   }

//   // Очистка кэша заказов
//   static Future<void> clearAllOrders() async {
//     final prefs = await SharedPreferences.getInstance();
//     final keys = prefs.getKeys().where((key) => key.startsWith(_ordersKeyPrefix)).toList();
//     for (var key in keys) {
//       await prefs.remove(key);
//     }
//     print('OrderCache: Cleared all orders');
//   }

//   // Очистка всего кэша
//   static Future<void> clearCache() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_statusesKey);
//     await clearAllOrders();
//     print('OrderCache: Cleared all cache');
//   }
// }
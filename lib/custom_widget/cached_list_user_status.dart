// import 'package:crm_task_manager/models/task_model.dart';
// import 'package:crm_task_manager/models/user_data_response.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// class CacheManager {
//   static const String _usersKey = 'cached_users';
//   static const String _statusesKey = 'cached_statuses';

//   // Сохранение списка пользователей
//   static Future<void> saveUsers(List<UserData> users) async {
//     final prefs = await SharedPreferences.getInstance();
//     final usersJson = users.map((user) => jsonEncode(user.toJson())).toList();
//     await prefs.setStringList(_usersKey, usersJson);
//   }

//   // Получение списка пользователей
//   static Future<List<UserData>> getUsers() async {
//     final prefs = await SharedPreferences.getInstance();
//     final usersJson = prefs.getStringList(_usersKey) ?? [];
//     return usersJson.map((userJson) => UserData.fromJson(jsonDecode(userJson))).toList();
//   }

//   // Сохранение списка статусов
//   static Future<void> saveStatuses(List<TaskStatus> statuses) async {
//     final prefs = await SharedPreferences.getInstance();
//     final statusesJson = statuses.map((status) => jsonEncode(status.toJson())).toList();
//     await prefs.setStringList(_statusesKey, statusesJson);
//   }

//   // Получение списка статусов
//   static Future<List<TaskStatus>> getStatuses() async {
//     final prefs = await SharedPreferences.getInstance();
//     final statusesJson = prefs.getStringList(_statusesKey) ?? [];
//     return statusesJson.map((statusJson) => TaskStatus.fromJson(jsonDecode(statusJson))).toList();
//   }
// }
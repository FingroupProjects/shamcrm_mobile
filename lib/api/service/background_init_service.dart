// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:app_tracking_transparency/app_tracking_transparency.dart';
// import 'package:new_version_plus/new_version_plus.dart';
// import 'package:flutter/material.dart';

// /// Сервис для ФОНОВОЙ инициализации тяжёлых компонентов
// /// НЕ блокирует показ UI
// class BackgroundInitService {
//   /// Firebase - инициализация в фоне
//   Future<void> initializeFirebase() async {
//     try {
//       if (Firebase.apps.isEmpty) {
//         await Firebase.initializeApp();
//       }
//     } catch (e) {
//       // Игнорируем ошибки - не критично
//     }
//   }

//   /// Firebase Messaging - в фоне
//   Future<void> initializeFirebaseMessaging() async {
//     try {
//       if (Firebase.apps.isEmpty) return;
      
//       await FirebaseMessaging.instance.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
      
//       final fcmToken = await FirebaseMessaging.instance.getToken();
//       if (fcmToken != null) {
//         final apiService = ApiService();
//         await apiService.sendDeviceToken(fcmToken);
//       }
//     } catch (e) {
//       // Игнорируем
//     }
//   }

//   /// Проверка обновлений - в фоне
//   Future<void> checkForUpdates(BuildContext context) async {
//     try {
//       final newVersion = NewVersionPlus();
//       final status = await newVersion.getVersionStatus();
      
//       if (status?.canUpdate == true && context.mounted) {
//         // Показываем диалог обновления
//       }
//     } catch (e) {
//       // Игнорируем
//     }
//   }

//   /// App Tracking Transparency - в фоне
//   Future<void> requestTrackingPermission() async {
//     try {
//       await AppTrackingTransparency.requestTrackingAuthorization();
//     } catch (e) {
//       // Игнорируем
//     }
//   }
// }
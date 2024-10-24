import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:crm_task_manager/main.dart';
import 'package:flutter/material.dart'; // Доступ к navigatorKey

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Инициализация уведомлений
  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission(); // Запрос разрешений

    final fCMToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fCMToken');

    // Обработчик фоновых сообщений
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    initPushNotification();
  }

  void initPushNotification() {
    // При открытии уведомления в закрытом или свернутом состоянии
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    
    // При нажатии на уведомление (foreground или background)
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    // Для уведомлений при активном приложении
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.body}');
      _showForegroundNotification(message);
    });
  }

  // Обработка уведомлений
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    navigatorKey.currentState?.pushNamed(
      '/notification_screen',
      arguments: message,
    );
  }

  // Показ уведомлений во время работы приложения
  void _showForegroundNotification(RemoteMessage message) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'Новое уведомление'),
        content: Text(message.notification?.body ?? 'Сообщение пришло'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              handleMessage(message);
            },
            child: const Text('Открыть'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }
}

// Фоновый обработчик сообщений
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

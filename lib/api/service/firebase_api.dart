import 'package:crm_task_manager/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart'; // Доступ к navigatorKey

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Запрос разрешений на уведомления
    await _firebaseMessaging.requestPermission();

    // Получение APNS токена для iOS
    final apnsToken = await _firebaseMessaging.getAPNSToken();
    print('APNS Token: ${apnsToken ?? "Не удалось получить APNS токен"}');

    // Получение FCM токена
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Настройка обработчиков уведомлений
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    initPushNotification();
  }

  void initPushNotification() {
    // При открытии через уведомление в свернутом или закрытом состоянии
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print('Получено уведомление при запуске приложения: ${message?.messageId}');
      handleMessage(message);
    });

    // При нажатии на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Пользователь нажал на уведомление: ${message.messageId}');
      handleMessage(message);
    });

    // Для уведомлений в активном приложении
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Уведомление при активном приложении: ${message.notification?.title}');
      print('Содержимое: ${message.notification?.body}');
      _showForegroundNotification(message);
    });
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    print('Обработка уведомления: ${message.messageId}');
    // Перенаправление на экран уведомлений
    navigatorKey.currentState?.pushNamed(
      '/notification_screen',
      arguments: message,
    );
  }

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
  print('Фоновое уведомление: ${message.messageId}');
  print('Заголовок: ${message.notification?.title}');
  print('Сообщение: ${message.notification?.body}');
  // Здесь можно добавить логику для работы с данными из фонового уведомления
}

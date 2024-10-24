import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> init() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Запросить разрешения на получение уведомлений (только для iOS)
    NotificationSettings settings = await messaging.requestPermission();

    // Получить токен устройства для отправки уведомлений
    String? token = await messaging.getToken();
    print("Firebase Messaging Token: $token");

    // Обработка полученных уведомлений, когда приложение в фоне или закрыто
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Обработка полученных уведомлений, когда приложение открыто
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message: ${message.messageId}');
      // Здесь можно добавить логику для отображения уведомления
    });

    // Обработка нажатий на уведомления
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Обработка перехода к конкретному чату
      if (message.data['chat_id'] != null) {
        String chatId = message.data['chat_id'];
        // Навигация к нужному чату
        // Например, вызов метода навигации из вашего основного экрана
        navigateToChat(chatId);
      }
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Здесь можно обработать фоновые уведомления
    print("Handling a background message: ${message.messageId}");
  }

  static void navigateToChat(String chatId) {
    // Здесь вы должны реализовать логику навигации к нужному чату
    // Возможно, вам нужно передать chatId в ваш ChatsScreen или создать метод в ChatsScreen для перехода к нужному чату
  }
}

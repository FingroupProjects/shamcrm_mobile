import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Запрос разрешений на уведомления
    await _firebaseMessaging.requestPermission();

    // Получение APNS токена для iOS
    // final apnsToken = await _firebaseMessaging.getAPNSToken();
    // print('APNS Token: ${apnsToken ?? "Не удалось получить APNS токен"}');

    // Получение FCM токена
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Настройка обработчиков уведомлений
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    initPushNotification();
  }

  void initPushNotification() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print(
          'Получено уведомление при запуске приложения: ${message?.messageId}');
      handleMessage(message);
      _printCustomData(message); // Печать кастомных данных
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Пользователь нажал на уведомление: ${message.messageId}');
      handleMessage(message);
      _printCustomData(message); // Печать кастомных данных
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          'Уведомление при активном приложении: ${message.notification?.title}');
      print('Содержимое: ${message.notification?.body}');
      _printCustomData(message); // Печать кастомных данных
    });
  }

  void _printCustomData(RemoteMessage? message) {
    if (message != null && message.data.isNotEmpty) {
      message.data.forEach((key, value) {
        print('Custom Data - Key: $key, Value: $value');
      });
    } else {
      print('Нет кастомных данных в уведомлении');
    }
  }

  void handleMessage(RemoteMessage? message) {
  if (message == null || message.data.isEmpty) {
    print('handleMessage: сообщение пустое или данные отсутствуют');
    return;
  }

  final type = message.data['type'];
  final id = message.data['id'];

  if (type == null || id == null) {
    print('handleMessage: отсутствуют необходимые данные (type или id)');
    return;
  }

  print('handleMessage: тип уведомления: $type, ID чата: $id');

  // if (type == 'chat') {
  //   print('Переход на экран чата с ID: $id');
  //   navigatorKey.currentState?.pushNamed(
  //     '/chats',
  //     arguments: {'id': id},
  //   );
  // } else {
  //   print('handleMessage: Неизвестный тип: $type');
  // }
}


}

// Фоновый обработчик сообщений
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Фоновое уведомление: ${message.messageId}');

  print('Message data: ${message.data}');
  if (message.data.isNotEmpty) {
    message.data.forEach((key, value) {
      print('Custom Data - Key: $key, Value: $value');
    });
  } else {
    print('Нет кастомных данных в уведомлении в фоне');
  }
  print('Заголовок: ${message.notification?.title}');
  print('Сообщение: ${message.notification?.body}');
}

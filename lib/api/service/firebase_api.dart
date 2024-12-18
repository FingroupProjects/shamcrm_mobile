import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  Future<void> handleMessage(RemoteMessage? message) async {
    if (message == null || message.data.isEmpty) {
      print('handleMessage: сообщение пустое или данные отсутствуют');
      return;
    }

    final type = message.data['type'];
    final id = message.data['id'];
    int? screenIndex;

    if (type == null) {
      print('handleMessage: отсутствует тип уведомления');
      return;
    }

    if (type == 'message') {
  print('Переход на экран чата с ID: $id');
  screenIndex = 3;
  navigatorKey.currentState?.pushReplacementNamed(
    '/home',
    arguments: {'id': id, 'screenIndex': screenIndex},
  );

  final chatId = int.tryParse(message.data['id'].toString()) ?? 0;

  if (chatId != 0) {
    // Загружаем данные профиля чата
    try {
      final getChatById = await ApiService().getChatById(chatId);


      if (getChatById.type == "lead") {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => MessagingCubit(ApiService()),
              child: ChatSmsScreen(
                chatItem: Chats(
                  id: chatId,
                  name: getChatById.name,
                  channel: "",
                  lastMessage: "",
                  messageType: "",
                  createDate: "",
                  unredMessage: 0,
                  canSendMessage: getChatById.canSendMessage, chatUsers: [],
                ).toChatItem("assets/images/AvatarChat.png"),
                chatId: chatId,
                endPointInTab: 'lead',
                canSendMessage: getChatById.canSendMessage,
              ),
            ),
          ),
        );
      } else if (getChatById.type == "task") {
        final chatProfileTask = await ApiService().getTaskProfile(chatId);
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => MessagingCubit(ApiService()),
              child: ChatSmsScreen(
                chatItem: Chats(
                  id: chatId,
                  name: chatProfileTask.name,
                  channel: "",
                  lastMessage: "",
                  messageType: "",
                  createDate: "",
                  unredMessage: 0,
                  canSendMessage: getChatById.canSendMessage, chatUsers: [],
                ).toChatItem("assets/images/AvatarChat.png"),
                chatId: chatId,
                endPointInTab: 'task',
                canSendMessage: getChatById.canSendMessage,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Закрыть индикатор загрузки в случае ошибки
      print("Ошибка загрузки данных: $e");
    }
  } else if (type == 'task' || type == 'taskFinished' || type == 'taskOutDated') {
      print('Переход на экран задачи с ID: $id');
      screenIndex = 1;
      navigatorKey.currentState?.pushReplacementNamed(
        '/home',
        arguments: {'id': id, 'screenIndex': screenIndex},
      );
      final taskId = message.data['id']; 
      if (taskId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(
              taskId: taskId,
              taskName: '',
              taskStatus: '',
              statusId: 1, taskCustomFields: [],
            ),
          ),
        );
      }
    } else if (type == 'notice') {
      print('Переход на экран лида с ID: $id');
      screenIndex = 2;
      navigatorKey.currentState?.pushReplacementNamed(
        '/home',
        arguments: {'id': id, 'screenIndex': screenIndex},
      );
      final leadId = message.data['id'];
      if (leadId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => LeadDetailsScreen(
              leadId: leadId.toString(),
              leadName: '',
              leadStatus: "",
              statusId: 1, 
              leadCustomFields: [],
            ),
          ),
        );
      }
    } else if (type == 'deal') {
      print('Переход на экран сделки с ID: $id');
      screenIndex = 4;
      navigatorKey.currentState?.pushReplacementNamed(
        '/home',
        arguments: {'id': id, 'screenIndex': screenIndex},
      );
      final dealId = message.data['id']; 
      if (dealId != null) {
        List<DealCustomField> defaultCustomFields = [
          DealCustomField(id: 1, key: '', value: ''),
          DealCustomField(id: 2, key: '', value: ''),
        ];
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DealDetailsScreen(
              dealId: dealId.toString(),
              dealName: '',
              sum: '',
              dealStatus: '',
              statusId: 1,
              dealCustomFields: defaultCustomFields,
            ),
          ),
        );
      }
    } else {
      print('handleMessage: Неизвестный тип: $type');
    }
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
}}
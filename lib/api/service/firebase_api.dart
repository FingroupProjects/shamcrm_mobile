import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Запрос разрешений на уведомления
    await _firebaseMessaging.requestPermission();

    // Получение FCM токена
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Настройка обработчиков уведомлений
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    initPushNotification();
  }

  void initPushNotification() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print('Получено уведомление при запуске приложения: ${message?.messageId}');
      handleMessage(message);
      _printCustomData(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Пользователь нажал на уведомление: ${message.messageId}');
      handleMessage(message);
      _printCustomData(message);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Уведомление при активном приложении: ${message.notification?.title}');
      _printCustomData(message);
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

    if (type == null || id == null) {
      print('handleMessage: отсутствует тип или id уведомления');
      return;
    }

    print('Обработка уведомления с типом: $type, ID: $id');

    int? screenIndex;
    switch (type) {
      case 'message':
        print('Переход на экран чата с ID: $id');
        screenIndex = 3;
        await navigateToScreen(screenIndex, id, 'message', message);
        break;

      case 'task':
      case 'taskFinished':
      case 'taskOutDated':
        print('Переход на экран задачи с ID: $id');
        screenIndex = 1;
        await navigateToScreen(screenIndex, id, 'task', message);
        break;

      case 'notice':
        print('Переход на экран лида с ID: $id');
        screenIndex = 2;
        await navigateToScreen(screenIndex, id, 'lead', message);
        break;

      case 'deal':
        print('Переход на экран сделки с ID: $id');
        screenIndex = 4;
        await navigateToScreen(screenIndex, id, 'deal', message);
        break;

      case 'lead':
        print('Переход на экран лида с ID: $id');
        screenIndex = 2;
        await navigateToScreen(screenIndex, id, 'lead', message);
        break;

      default:
        print('handleMessage: Неизвестный тип: $type');
    }
  }
  

  Future<void> navigateToScreen(int screenIndex, String id, String type, RemoteMessage message) async {
       SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('hasNewNotification', false);});
    navigatorKey.currentState?.pushReplacementNamed(
      '/home',
      arguments: {'id': id, 'screenIndex': screenIndex},
    );

    switch (type) {
      case 'message':
        await navigateToChatScreen(id, message);
        break;

      case 'task':
        await navigateToTaskScreen(id, message);
        break;

      case 'lead':
        await navigateToLeadScreen(id, message);
        break;

      case 'deal':
        await navigateToDealScreen(id, message);
        break;

      default:
        print('Не удалось перейти на экран: $type');
    }
  }

  Future<void> navigateToChatScreen(String id, RemoteMessage message) async {

  final chatId = int.tryParse(id) ?? 0;
  if (chatId != 0) {
    try {
      final getChatById = await ApiService().getChatById(chatId);
      Widget screen;
      String? chatName;

      switch (getChatById.type) {
        case 'lead':
          chatName = getChatById.name;
          break;
        case 'task':
          final chatProfileTask = await ApiService().getTaskProfile(chatId);
          chatName = chatProfileTask.name;
          break;
     case 'corporate':
         final getChatById = await ApiService().getChatById(chatId);

         chatName = getChatById.group != null 
             ? getChatById.group!.name 
             : getChatById.chatUsers.length > 1
                 ? '${getChatById.chatUsers[1].participant.name}'
                 : getChatById.chatUsers[0].participant.name;
         break;
        default:
          print('Неизвестный тип чата');
          return;
      }

      screen = ChatSmsScreen(
        chatItem: Chats(
          id: chatId,
          name: chatName ?? 'Без имени',  
          canSendMessage: getChatById.canSendMessage,
          channel: '',
          lastMessage: '',
          createDate: '',
          unredMessage: 1,
          chatUsers: [],
        ).toChatItem("assets/images/AvatarChat.png"),
        chatId: chatId,
        endPointInTab: getChatById.type.toString(),
        canSendMessage: getChatById.canSendMessage,
      );

      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => MessagingCubit(ApiService()), 
          child: screen,
        ),
      ));
    } catch (e) {
      print("Ошибка загрузки данных: $e");
    }
  }
}


  Future<void> navigateToTaskScreen(String id, RemoteMessage message) async {
    final taskId = message.data['id'];
    if (taskId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => TaskDetailsScreen(taskId: taskId, taskName: '', taskStatus: '', statusId: 1, taskCustomFields: []),
        ),
      );
    }
  }

  Future<void> navigateToLeadScreen(String id, RemoteMessage message) async {
    final leadId = message.data['id'];
    if (leadId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => LeadDetailsScreen(
            leadId: leadId.toString(),
            leadName: '',
            leadStatus: '',
            statusId: 1,
            leadCustomFields: [LeadCustomField(id: 1, key: '', value: ''), LeadCustomField(id: 2, key: '', value: '')],
          ),
        ),
      );
    }
  }

  Future<void> navigateToDealScreen(String id, RemoteMessage message) async {
    final dealId = message.data['id'];
    if (dealId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => DealDetailsScreen(
            dealId: dealId.toString(),
            dealName: '',
            sum: '',
            dealStatus: '',
            statusId: 1,
            dealCustomFields: [DealCustomField(id: 1, key: '', value: ''), DealCustomField(id: 2, key: '', value: '')],
          ),
        ),
      );
    }
  }
}

// Фоновый обработчик сообщений
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Фоновое уведомление: ${message.messageId}');
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

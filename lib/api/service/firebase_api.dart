import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/event/event_details/event_details_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_details_screen.dart';
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

void initPushNotification() async {
        final prefs = await SharedPreferences.getInstance();
        final savedPin = prefs.getString('user_pin');
        print('------------------------');
        print('-----------------SAVEPINCODE-------');
        print(savedPin);

 if (savedPin == null) {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print('Получено уведомление при запуске приложения: ${message?.messageId}');
      handleMessage(message);
      _printCustomData(message);
    });
} else {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print('Получено уведомление при закрытом сосотние приложения: ${message?.messageId}');
      _navigateToMainScreen(message); 
    });
}


  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    print('Пользователь нажал на уведомление: ${message.messageId}');
    _navigateToMainScreen(message);
  });
  
    // FirebaseMessaging.onMessageOpenedApp.listen((message) {
    //   print('Пользователь нажал на уведомление: ${message.messageId}');
    //   handleMessage(message);
    //   _printCustomData(message);
    // });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Уведомление при активном приложении: ${message.notification?.title}');
    _printCustomData(message);
  });
}

Future<void> _navigateToMainScreen(RemoteMessage? message) async {
  if (message != null) {
    await _navigateToPinScreenAndHandleNotification(message);
  }
}


  // Функция для перехода на экран PIN и потом на основной экран
Future<void> _navigateToPinScreenAndHandleNotification(RemoteMessage? message) async {
  if (message != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_notification', jsonEncode(message.data));
  }
  navigatorKey.currentState?.pushReplacementNamed('/pin_screen');
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
    final ApiService _apiService = ApiService();

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
        if (await _apiService.hasPermission('deal.read') &&
            await _apiService.hasPermission('lead.read')) {
          screenIndex = 3;
          await navigateToScreen(screenIndex, id, 'message', message);
        } else {
          screenIndex = 2;
          await navigateToScreen(screenIndex, id, 'message', message);
        }
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

      case 'dealDeadLineNotification':
        print('Переход на экран сделки с ID: $id');
        screenIndex = 4;
        await navigateToScreen(
            screenIndex, id, 'dealDeadLineNotification', message);
        break;

      case 'lead':
        print('Переход на экран лида с ID: $id');
        screenIndex = 2;
        await navigateToScreen(screenIndex, id, 'lead', message);
        break;
      case 'myTask':
        print('Переход на экран лида с ID: $id');
        screenIndex = 2;
        await navigateToScreen(screenIndex, id, 'myTask', message);
        break;
      case 'eventId':
        print('Переход на экран лида с ID: $id');
        screenIndex = 2;
        await navigateToScreen(screenIndex, id, 'eventId', message);
        break;
      default:
        print('handleMessage: Неизвестный тип: $type');
    }
  }

  Future<void> navigateToScreen(
      int screenIndex, String id, String type, RemoteMessage message) async {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('hasNewNotification', false);
    });
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
      case 'myTask':
        await navigateToMyTaskScreen(id, message);
        break;
      case 'eventId':
        await navigateToMyTaskScreen(id, message);
        break;

      case 'dealDeadLineNotification':
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
            final prefs = await SharedPreferences.getInstance();
            String userId = prefs.getString('userID').toString();

            final getChatById = await ApiService().getChatById(chatId);

            if (getChatById.group != null) {
              chatName = getChatById.group!.name;
            } else {
              int userIndex = getChatById.chatUsers.indexWhere(
                  (user) => user.participant.id.toString() == userId);
              if (userIndex != -1) {
                int otherUserIndex = (userIndex == 0) ? 1 : 0;
                chatName =
                    '${getChatById.chatUsers[otherUserIndex].participant.name}';
              } else {
                chatName = getChatById.chatUsers[0].participant.name;
              }
            }

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
            image: '',
            channel: '',
            lastMessage: '',
            createDate: '',
            unreadCount: 1,
            chatUsers: [],
          ).toChatItem(),
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
    print('Received push notification data: ${message.data}');

    final taskId = message.data['id'];
    final taskNumber =
        int.tryParse(message.data['taskNumber'] ?? ''); // Преобразуем в int

    print('taskId: $taskId');
    print('taskNumber: $taskNumber');

    if (taskId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => TaskDetailsScreen(
            taskId: taskId,
            taskName: '',
            taskStatus: '',
            statusId: 1,
            taskNumber: taskNumber, // Теперь taskNumber это int?
            taskCustomFields: [],
          ),
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
          ),
        ),
      );
    }
  }

  Future<void> navigateToMyTaskScreen(String id, RemoteMessage message) async {
    print('Received push notification data: ${message.data}');

    final myTaskId = message.data['id'];
    final taskNumber = int.tryParse(message.data['task_number'] ?? '');

    print('taskId: $myTaskId');
    print('taskNumber: $taskNumber');

    if (myTaskId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => MyTaskDetailsScreen(
            taskId: myTaskId.toString(),
            taskName: '',
            taskStatus: '',
            statusId: 1,
            taskNumber: taskNumber, // Теперь taskNumber это int?
          ),
        ),
      );
    }
  }

  Future<void> navigateToEventScreen(String id, RemoteMessage message) async {
    final eventId = message.data['id'];
    if (eventId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => EventDetailsScreen(
            noticeId: eventId,
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
            dealCustomFields: [
              DealCustomField(id: 1, key: '', value: ''),
              DealCustomField(id: 2, key: '', value: '')
            ],
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

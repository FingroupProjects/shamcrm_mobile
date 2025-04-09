import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_details_screen.dart';
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
  RemoteMessage? _initialMessage;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await initPushNotification();
  }

  Future<void> initPushNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin');

    // Сохраняем пуш, но не обрабатываем сразу
    _initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Пользователь нажал на уведомление: ${message.messageId}');
      handleMessage(message);
    });

    FirebaseMessaging.onMessage.listen((message) {
      print('Уведомление при активном приложении: ${message.notification?.title}');
      _printCustomData(message);
    });
  }

  RemoteMessage? getInitialMessage() {
    return _initialMessage;
  }
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

    bool hasDealRead = await _apiService.hasPermission('deal.read');
    bool hasDashboard = await _apiService.hasPermission('section.dashboard');
    bool hasLeadRead = await _apiService.hasPermission('lead.read');
    bool hasTaskRead = await _apiService.hasPermission('task.read');

 int permissionCount = 0;
    if (hasDealRead) permissionCount++;
    if (hasDashboard) permissionCount++;
    if (hasLeadRead) permissionCount++;
    if (hasTaskRead) permissionCount++;

    if (permissionCount == 0) {
      screenIndex = 0;
      await navigateToScreen(screenIndex, id, 'message', message);
    }
    else if (permissionCount == 2) {
      screenIndex = 2; 
      await navigateToScreen(screenIndex, id, 'message', message);
    }
    else if (permissionCount == 3) {
      screenIndex = 3; 
      await navigateToScreen(screenIndex, id, 'message', message);
    }
    else if (permissionCount == 4) {
      screenIndex = 4;
      await navigateToScreen(screenIndex, id, 'message', message);
    }
    else {
      screenIndex = 1;
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
        screenIndex = 3;
        await navigateToScreen(
            screenIndex, id, 'dealDeadLineNotification', message);
        break;

      case 'lead':
      case 'updateLeadStatus':
        print('Переход на экран лида с ID: $id');
        screenIndex = 2;
        await navigateToScreen(screenIndex, id, 'lead', message);
        break;
      case 'myTaskOutDated':
        print('Переход на экран мои задачи с ID: $id');
        screenIndex = -1;
        await navigateToScreen(screenIndex, id, 'myTask', message);
        break;
      case 'eventId':
        print('Переход на экран лида с ID: $id');
        screenIndex = 2;
        await navigateToScreen(screenIndex, id, 'eventId', message);
        break;
      
      // case 'orders':
      //   print('Переход на экран лида с ID: $id');
      //   screenIndex = 3;
      //   await navigateToScreen(screenIndex, id, 'orders', message);
      //   break;
      default:
        print('handleMessage: Неизвестный тип: $type');
    }
  }

Future<void> navigateToScreen(
    int screenIndex, String id, String type, RemoteMessage message) async {
  SharedPreferences.getInstance().then((prefs) {
    prefs.setBool('hasNewNotification', false);
  });

  int group = 1;
  if (type == 'message' || type == 'task' || type == 'lead' || type == 'dealDeadLineNotification' || type == 'eventId' || type == 'myTask') {
    group = 1;
  } else {
    group = 2;
  }

  navigatorKey.currentState?.pushReplacementNamed(
    '/home',
    arguments: {'id': id, 'screenIndex': screenIndex, 'group': group},
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

    case 'orders':
      await navigateToOrdersScreen(id, message);
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
    final taskNumber = int.tryParse(message.data['taskNumber'] ?? ''); 

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
            taskNumber: taskNumber, 
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
            statusId: 0,
          ),
        ),
      );
    }
  }

  Future<void> navigateToMyTaskScreen(String id, RemoteMessage message) async {

    final myTaskId = message.data['id'];
    final taskNumber = int.tryParse(message.data['task_number'] ?? '');
    
    if (myTaskId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => MyTaskDetailsScreen(
            taskId: myTaskId.toString(),
            taskName: '',
            taskStatus: '',
            statusId: 1,
            taskNumber: taskNumber, 
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

 Future<void> navigateToOrdersScreen(String id, RemoteMessage message) async {
  final orderId = int.tryParse(message.data['id'] ?? '');
  if (orderId != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          orderId: orderId,
          order: Order(id: orderId,phone: '',orderNumber: '', delivery: false,
            lead: OrderLead( id: 0, name: '', phone: '', channels: [] ),
            orderStatus: OrderStatusName(id: 0, name: ''),
            goods: [],
          ),
          categoryName: '',
        ),
      ),
    );
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


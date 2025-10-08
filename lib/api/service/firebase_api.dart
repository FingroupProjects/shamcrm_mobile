import 'dart:io';
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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ВАЖНО: Эта функция должна быть top-level, не методом класса
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    
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
  } catch (e) {
    print('Ошибка обработки фонового сообщения: $e');
  }
}

class FirebaseApi {
  static final FirebaseApi _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();
  
  final _firebaseMessaging = FirebaseMessaging.instance;
  RemoteMessage? _initialMessage;
  bool _isInitialized = false;

  Future<void> initNotifications() async {
    try {
      // КРИТИЧЕСКАЯ ПРОВЕРКА: Firebase должен быть инициализирован
      if (Firebase.apps.isEmpty) {
        print('FirebaseApi: Firebase не инициализирован, пропускаем настройку уведомлений');
        return;
      }

      // ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Проверяем доступность default app
      try {
        Firebase.app();
      } catch (e) {
        print('FirebaseApi: Default Firebase app недоступен: $e');
        return;
      }

      if (_isInitialized) {
        print('FirebaseApi уже инициализирован');
        return;
      }

      // Запрашиваем разрешение на уведомления
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('User declined or has not accepted notification permission');
        return;
      }

      // Проверяем APNS-токен (только для iOS/iPadOS)
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          print('APNS token is not available yet. Skipping FCM token retrieval.');
          return;
        }
      }

      // Получаем FCM-токен
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        print('FCM Token: $fcmToken');
      } else {
        print('Failed to get FCM token');
      }

      // Безопасная регистрация background handler
      try {
        if (Firebase.apps.isNotEmpty) {
          FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
          print('Background message handler зарегистрирован');
        }
      } catch (e) {
        if (e.toString().contains('already')) {
          print('Background handler уже зарегистрирован');
        } else {
          print('Ошибка регистрации background handler: $e');
        }
      }

      await initPushNotification();
      _isInitialized = true;
      print('FirebaseApi успешно инициализирован');

    } catch (e) {
      print('Error initializing notifications: $e');
      // НЕ пробрасываем ошибку дальше
    }
  }

  Future<void> initPushNotification() async {
    try {
      _initialMessage = await FirebaseMessaging.instance.getInitialMessage();

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print('Пользователь нажал на уведомление: ${message.messageId}');
        handleMessage(message);
      });

      FirebaseMessaging.onMessage.listen((message) {
        print('Уведомление при активном приложении: ${message.notification?.title}');
        _printCustomData(message);
      });
    } catch (e) {
      print('Ошибка инициализации push уведомлений: $e');
    }
  }

  RemoteMessage? getInitialMessage() {
    return _initialMessage;
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
    try {
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
          } else if (permissionCount == 2) {
            screenIndex = 2;
            await navigateToScreen(screenIndex, id, 'message', message);
          } else if (permissionCount == 3) {
            screenIndex = 3;
            await navigateToScreen(screenIndex, id, 'message', message);
          } else if (permissionCount == 4) {
            screenIndex = 4;
            await navigateToScreen(screenIndex, id, 'message', message);
          } else {
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
          await navigateToScreen(screenIndex, id, 'dealDeadLineNotification', message);
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

        case 'orders':
          print('Переход на экран заказов с ID: $id');
          screenIndex = 3;
          await navigateToScreen(screenIndex, id, 'orders', message);
          break;
        default:
          print('handleMessage: Неизвестный тип: $type');
      }
    } catch (e) {
      print('Ошибка обработки сообщения: $e');
    }
  }

  Future<void> navigateToScreen(
      int screenIndex, String id, String type, RemoteMessage message) async {
    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('hasNewNotification', false);
      });

      int group = 1;
      if (type == 'message' ||
          type == 'task' ||
          type == 'lead' ||
          type == 'dealDeadLineNotification' ||
          type == 'eventId' ||
          type == 'myTask') {
        group = 1;
      } else {
        group = 2;
      }

      // Проверяем, что навигатор доступен
      if (navigatorKey.currentState != null) {
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
            await navigateToEventScreen(id, message);
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
      } else {
        print('Navigator не доступен');
      }
    } catch (e) {
      print('Ошибка навигации к экрану: $e');
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

        if (navigatorKey.currentState != null) {
          navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => MessagingCubit(ApiService()),
              child: screen,
            ),
          ));
        }
      } catch (e) {
        print("Ошибка загрузки данных чата: $e");
      }
    }
  }

  Future<void> navigateToTaskScreen(String id, RemoteMessage message) async {
    try {
      print('Received push notification data: ${message.data}');

      final taskId = message.data['id'];
      final taskNumber = int.tryParse(message.data['taskNumber'] ?? '');

      print('taskId: $taskId');
      print('taskNumber: $taskNumber');

      if (taskId != null && navigatorKey.currentState != null) {
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
    } catch (e) {
      print('Ошибка навигации к экрану задачи: $e');
    }
  }

  Future<void> navigateToLeadScreen(String id, RemoteMessage message) async {
    try {
      final leadId = message.data['id'];
      if (leadId != null && navigatorKey.currentState != null) {
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
    } catch (e) {
      print('Ошибка навигации к экрану лида: $e');
    }
  }

  Future<void> navigateToMyTaskScreen(String id, RemoteMessage message) async {
    try {
      final myTaskId = message.data['id'];
      final taskNumber = int.tryParse(message.data['task_number'] ?? '');

      if (myTaskId != null && navigatorKey.currentState != null) {
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
    } catch (e) {
      print('Ошибка навигации к экрану моих задач: $e');
    }
  }

  Future<void> navigateToEventScreen(String id, RemoteMessage message) async {
    try {
      final eventId = message.data['id'];
      if (eventId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              noticeId: eventId,
            ),
          ),
        );
      }
    } catch (e) {
      print('Ошибка навигации к экрану событий: $e');
    }
  }

  Future<void> navigateToDealScreen(String id, RemoteMessage message) async {
    try {
      final dealId = message.data['id'];
      if (dealId != null && navigatorKey.currentState != null) {
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
    } catch (e) {
      print('Ошибка навигации к экрану сделки: $e');
    }
  }

  Future<void> navigateToOrdersScreen(String id, RemoteMessage message) async {
    try {
      final orderId = int.tryParse(message.data['id'] ?? '');
      if (orderId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(
              orderId: orderId,
              order: Order(
                  id: orderId,
                  phone: '',
                  orderNumber: '',
                  delivery: false,
                  lead: OrderLead(id: 0, name: '', phone: '', channels: []),
                  orderStatus: OrderStatusName(id: 0, name: ''),
                  goods: []),
              categoryName: '',
            ),
          ),
        );
      }
    } catch (e) {
      print('Ошибка навигации к экрану заказов: $e');
    }
  }

  // Получение FCM токена с безопасной обработкой
  Future<String?> getFCMToken() async {
    try {
      if (Firebase.apps.isEmpty) {
        print('Firebase не инициализирован');
        return null;
      }

      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token получен: ${token.substring(0, 20)}...');
      }
      return token;
    } catch (e) {
      print('Ошибка получения FCM токена: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      if (Firebase.apps.isEmpty) {
        print('Firebase не инициализирован, не можем подписаться на топик');
        return;
      }
      
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Подписались на топик: $topic');
    } catch (e) {
      print('Ошибка подписки на топик $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (Firebase.apps.isEmpty) {
        print('Firebase не инициализирован, не можем отписаться от топика');
        return;
      }
      
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Отписались от топика: $topic');
    } catch (e) {
      print('Ошибка отписки от топика $topic: $e');
    }
  }

  void dispose() {
    _isInitialized = false;
    _initialMessage = null;
  }
}
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
      debugPrint("Firebase не инициализирован, инициализируем... FirebaseApi.Line.26");
      await Firebase.initializeApp();
    }
    
    debugPrint('Фоновое уведомление: ${message.messageId}');
    if (message.data.isNotEmpty) {
      message.data.forEach((key, value) {
        debugPrint('Custom Data - Key: $key, Value: $value');
      });
    } else {
      debugPrint('Нет кастомных данных в уведомлении в фоне');
    }
    debugPrint('Заголовок: ${message.notification?.title}');
    debugPrint('Сообщение: ${message.notification?.body}');
  } catch (e) {
    debugPrint('Ошибка обработки фонового сообщения: $e');
  }
}

class FirebaseApi {
  static final FirebaseApi _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();
  
  final _firebaseMessaging = FirebaseMessaging.instance;
  RemoteMessage? _initialMessage;
  bool _isInitialized = false;

  // ✅ КРИТИЧНО: Единственный экземпляр ApiService
  late final ApiService _apiService;

  Future<void> initNotifications() async {
    try {
      // КРИТИЧЕСКАЯ ПРОВЕРКА: Firebase должен быть инициализирован
      if (Firebase.apps.isEmpty) {
        debugPrint('FirebaseApi: Firebase не инициализирован, пропускаем настройку уведомлений');
        return;
      }

      // ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Проверяем доступность default app
      try {
        Firebase.app();
      } catch (e) {
        debugPrint('FirebaseApi: Default Firebase app недоступен: $e');
        return;
      }

      if (_isInitialized) {
        debugPrint('FirebaseApi уже инициализирован');
        return;
      }

      // ✅ КРИТИЧНО: Инициализируем ApiService ОДИН РАЗ
      _apiService = ApiService();
      await _apiService.initialize();
      debugPrint('FirebaseApi: ApiService initialized with baseUrl: ${_apiService.baseUrl}');

      // Запрашиваем разрешение на уведомления
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('User declined or has not accepted notification permission');
        return;
      }

      // Проверяем APNS-токен (только для iOS/iPadOS)
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('APNS token is not available yet. Skipping FCM token retrieval.');
          return;
        }
      }

      // Получаем FCM-токен
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        debugPrint('FCM Token: $fcmToken');
      } else {
        debugPrint('Failed to get FCM token');
      }

      // Безопасная регистрация background handler
      try {
        if (Firebase.apps.isNotEmpty) {
          FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
          debugPrint('Background message handler зарегистрирован');
        }
      } catch (e) {
        if (e.toString().contains('already')) {
          debugPrint('Background handler уже зарегистрирован');
        } else {
          debugPrint('Ошибка регистрации background handler: $e');
        }
      }

      await initPushNotification();
      _isInitialized = true;
      debugPrint('FirebaseApi успешно инициализирован');

    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      // НЕ пробрасываем ошибку дальше
    }
  }

  Future<void> initPushNotification() async {
    try {
      _initialMessage = await FirebaseMessaging.instance.getInitialMessage();

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('Пользователь нажал на уведомление: ${message.messageId}');
        handleMessage(message);
      });

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Уведомление при активном приложении: ${message.notification?.title}');
        _printCustomData(message);
      });
    } catch (e) {
      debugPrint('Ошибка инициализации push уведомлений: $e');
    }
  }

  RemoteMessage? getInitialMessage() {
    return _initialMessage;
  }

  void _printCustomData(RemoteMessage? message) {
    if (message != null && message.data.isNotEmpty) {
      message.data.forEach((key, value) {
        debugPrint('Custom Data - Key: $key, Value: $value');
      });
    } else {
      debugPrint('Нет кастомных данных в уведомлении');
    }
  }

 Future<void> handleMessage(RemoteMessage? message) async {
  try {
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('🔔 PUSH NOTIFICATION RECEIVED');
    debugPrint('════════════════════════════════════════════════════════');

    if (message == null) {
      debugPrint('❌ Message is NULL');
      return;
    }

    debugPrint('📦 Message Data: ${message.data}');
    debugPrint('📦 Message ID: ${message.messageId}');
    debugPrint('📦 Notification Title: ${message.notification?.title}');
    debugPrint('📦 Notification Body: ${message.notification?.body}');

    if (message.data.isEmpty) {
      debugPrint('❌ Message data is EMPTY');
      return;
    }

    final type = message.data['type'];
    final id = message.data['id'];

    debugPrint('🎯 Notification Type: $type');
    debugPrint('🎯 Notification ID: $id');
    debugPrint('🎯 All Data Keys: ${message.data.keys.toList()}');
    debugPrint('🎯 All Data Values: ${message.data.values.toList()}');

    if (type == null || id == null) {
      debugPrint('❌ Type or ID is NULL - type: $type, id: $id');
      return;
    }

    // ✅ Ждем инициализацию навигатора
    debugPrint('⏳ Waiting for Navigator to be ready...');
    int attempts = 0;
    while (navigatorKey.currentState == null && attempts < 10) {
      debugPrint('⏳ Navigator attempt ${attempts + 1}/10');
      await Future.delayed(Duration(milliseconds: 500));
      attempts++;
    }

    if (navigatorKey.currentState == null) {
      debugPrint('❌ Navigator STILL NULL after 10 attempts');
      return;
    }
    debugPrint('✅ Navigator is READY');

    // ✅ Проверяем домены
    debugPrint('🌐 Checking domain configuration...');
    await _ensureDomainsConfigured();

    // ✅ Проверка ApiService
    if (!_isInitialized) {
      debugPrint('⚙️ ApiService not initialized, initializing...');
      await _apiService.initialize();
      debugPrint('✅ ApiService initialized with baseUrl: ${_apiService.baseUrl}');
    } else {
      debugPrint('✅ ApiService already initialized with baseUrl: ${_apiService.baseUrl}');
    }

    int? screenIndex;
    switch (type) {
      case 'message':
        debugPrint('💬 Processing MESSAGE notification');
        
        bool hasDealRead = await _apiService.hasPermission('deal.read');
        bool hasDashboard = await _apiService.hasPermission('section.dashboard');
        bool hasLeadRead = await _apiService.hasPermission('lead.read');
        bool hasTaskRead = await _apiService.hasPermission('task.read');

        debugPrint('🔐 Permissions: deal.read=$hasDealRead, dashboard=$hasDashboard, lead.read=$hasLeadRead, task.read=$hasTaskRead');

        int permissionCount = 0;
        if (hasDealRead) permissionCount++;
        if (hasDashboard) permissionCount++;
        if (hasLeadRead) permissionCount++;
        if (hasTaskRead) permissionCount++;

        debugPrint('🔐 Total permissions: $permissionCount');

        if (permissionCount == 0) {
          screenIndex = 0;
        } else if (permissionCount == 2) {
          screenIndex = 2;
        } else if (permissionCount == 3) {
          screenIndex = 3;
        } else if (permissionCount == 4) {
          screenIndex = 4;
        } else {
          screenIndex = 1;
        }
        
        debugPrint('📍 Calculated screenIndex: $screenIndex');
        await navigateToScreen(screenIndex, id, 'message', message);
        break;

      case 'task':
      case 'taskFinished':
      case 'taskOutDated':
        debugPrint('📋 Processing TASK notification');
        screenIndex = 1;
        await navigateToScreen(screenIndex, id, 'task', message);
        break;

      case 'notice':
        debugPrint('📢 Processing NOTICE notification');
        screenIndex = 2;
        await navigateToScreen(screenIndex, id, 'lead', message);
        break;

      case 'dealDeadLineNotification':
        debugPrint('💼 Processing DEAL notification');
        screenIndex = 3;
        await navigateToScreen(screenIndex, id, 'dealDeadLineNotification', message);
        break;

      case 'lead':
      case 'updateLeadStatus':
        debugPrint('👤 Processing LEAD notification');
        screenIndex = 2;
        await navigateToScreen(screenIndex, id, 'lead', message);
        break;

      case 'myTaskOutDated':
        debugPrint('✅ Processing MY TASK notification');
        screenIndex = -1;
        await navigateToScreen(screenIndex, id, 'myTask', message);
        break;

      case 'eventId':
        debugPrint('📅 Processing EVENT notification');
        screenIndex = 2;
        await navigateToScreen(screenIndex, id, 'eventId', message);
        break;

      case 'orders':
        debugPrint('🛒 Processing ORDER notification');
        screenIndex = 3;
        await navigateToScreen(screenIndex, id, 'orders', message);
        break;
        
      default:
        debugPrint('❓ Unknown notification type: $type');
    }
    
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('✅ PUSH NOTIFICATION HANDLED SUCCESSFULLY');
    debugPrint('════════════════════════════════════════════════════════');
  } catch (e, stackTrace) {
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('❌ CRITICAL ERROR IN handleMessage');
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('Error: $e');
    debugPrint('StackTrace: $stackTrace');
    debugPrint('════════════════════════════════════════════════════════');
  }
}

Future<void> navigateToChatScreen(String id, RemoteMessage message) async {
  debugPrint('════════════════════════════════════════════════════════');
  debugPrint('💬 NAVIGATE TO CHAT SCREEN');
  debugPrint('════════════════════════════════════════════════════════');
  debugPrint('Chat ID (string): $id');
  
  final chatId = int.tryParse(id) ?? 0;
  debugPrint('Chat ID (parsed): $chatId');
  
  if (chatId == 0) {
    debugPrint('❌ Invalid chatId: $chatId');
    return;
  }

  try {
    debugPrint('🔍 Loading chat data for chatId: $chatId');
    
    if (navigatorKey.currentState == null) {
      debugPrint('❌ Navigator not ready');
      return;
    }

    debugPrint('📡 Calling _apiService.getChatById($chatId)...');
    final getChatById = await _apiService.getChatById(chatId);
    
    debugPrint('✅ Chat data received:');
    debugPrint('  - Chat Type: ${getChatById.type}');
    debugPrint('  - Chat Name: ${getChatById.name}');
    debugPrint('  - Can Send Message: ${getChatById.canSendMessage}');
    debugPrint('  - Chat Users Count: ${getChatById.chatUsers.length}');
    debugPrint('  - Has Group: ${getChatById.group != null}');
    if (getChatById.group != null) {
      debugPrint('  - Group Name: ${getChatById.group!.name}');
    }
    
    Widget screen;
    String? chatName;

    switch (getChatById.type) {
      case 'lead':
        debugPrint('🎯 Chat type: LEAD');
        chatName = getChatById.name;
        debugPrint('  - Chat Name: $chatName');
        break;
        
      case 'task':
        debugPrint('🎯 Chat type: TASK');
        debugPrint('📡 Calling _apiService.getTaskProfile($chatId)...');
        final chatProfileTask = await _apiService.getTaskProfile(chatId);
        chatName = chatProfileTask.name;
        debugPrint('  - Task Name: $chatName');
        break;
        
      case 'corporate':
        debugPrint('🎯 Chat type: CORPORATE');
        final prefs = await SharedPreferences.getInstance();
        String userId = prefs.getString('userID').toString();
        debugPrint('  - Current User ID: $userId');

        if (getChatById.group != null) {
          debugPrint('  - This is a GROUP chat');
          chatName = getChatById.group!.name;
          debugPrint('  - Group Name: $chatName');
        } else {
          debugPrint('  - This is a DIRECT chat (1-on-1)');
          debugPrint('  - Chat Users from getChatById: ${getChatById.chatUsers.length}');
          
          // ✅ КРИТИЧЕСКИЙ FIX: Если chatUsers пустой, пробуем альтернативный способ
          if (getChatById.chatUsers.isEmpty) {
            debugPrint('⚠️ chatUsers is EMPTY - trying alternative method');
            
            // ВАРИАНТ 1: Используем message.data если там есть информация
            if (message.data.containsKey('sender_name')) {
              chatName = message.data['sender_name'];
              debugPrint('  - Got name from push notification: $chatName');
            } 
            // ВАРИАНТ 2: Пробуем получить список чатов и найти этот чат там
           else {
  try {
    debugPrint('  - Trying to fetch chat list to find chat name...');
    
    // ✅ ИСПРАВЛЕНО: Правильная сигнатура getAllChats
    final allChatsResponse = await _apiService.getAllChats('corporate', 1);
    
    // ✅ ИСПРАВЛЕНО: PaginationDTO имеет поле data, а не result
    final allChats = allChatsResponse.data ?? [];
    debugPrint('  - Fetched ${allChats.length} corporate chats');
    
    // ✅ ИСПРАВЛЕНО: Используем firstWhere на списке
    final targetChat = allChats.firstWhere(
      (chat) => chat.id == chatId,
      orElse: () => throw Exception('Chat not found in list')
    );
    
    chatName = targetChat.name;
    debugPrint('  - Found chat name in list: $chatName');
  } catch (e) {
    debugPrint('  - Failed to get name from chat list: $e');
    
    // ВАРИАНТ 3: Пробуем использовать имя из самого getChatById
    if (getChatById.name != null && getChatById.name!.isNotEmpty) {
      chatName = getChatById.name;
      debugPrint('  - Using name from getChatById: $chatName');
    } else {
      // FALLBACK: Используем ID чата
      chatName = 'Чат #$chatId';
      debugPrint('  - Using fallback name: $chatName');
    }
  }
}
          } else if (getChatById.chatUsers.length == 1) {
            debugPrint('⚠️ WARNING: Only 1 user in chatUsers');
            chatName = getChatById.chatUsers[0].participant.name;
            debugPrint('  - Using single user name: $chatName');
          } else {
            // Обычная логика для 2+ пользователей
            int userIndex = getChatById.chatUsers.indexWhere(
                (user) => user.participant.id.toString() == userId);
            debugPrint('  - Current user index: $userIndex');
            
            if (userIndex != -1) {
              int otherUserIndex = (userIndex == 0) ? 1 : 0;
              debugPrint('  - Other user index: $otherUserIndex');
              chatName = getChatById.chatUsers[otherUserIndex].participant.name;
              debugPrint('  - Other user name: $chatName');
            } else {
              debugPrint('  - Current user not found, using first user');
              chatName = getChatById.chatUsers[0].participant.name;
              debugPrint('  - First user name: $chatName');
            }
          }
        }
        break;
        
      default:
        debugPrint('❌ Unknown chat type: ${getChatById.type}');
        return;
    }

    debugPrint('📱 Creating ChatSmsScreen with:');
    debugPrint('  - chatId: $chatId');
    debugPrint('  - chatName: $chatName');
    debugPrint('  - chatType: ${getChatById.type}');
    debugPrint('  - canSendMessage: ${getChatById.canSendMessage}');

    screen = ChatSmsScreen(
      chatItem: Chats(
        id: chatId,
        name: chatName ?? 'Чат #$chatId',
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

    debugPrint('🚀 Pushing chat screen to navigator...');
    await navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => MessagingCubit(ApiService()),
          child: screen,
        ),
      ),
    );
    
    debugPrint('✅ Chat screen pushed successfully');
    debugPrint('════════════════════════════════════════════════════════');
  } catch (e, stackTrace) {
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('❌ ERROR in navigateToChatScreen');
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('Error: $e');
    debugPrint('StackTrace: $stackTrace');
    debugPrint('════════════════════════════════════════════════════════');
  }
}
  // ✅ НОВЫЙ МЕТОД: Проверка и настройка доменов
  Future<void> _ensureDomainsConfigured() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Проверяем текущие домены
      final enteredDomainMap = await _apiService.getEnteredDomain();
      String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      String? enteredDomain = enteredDomainMap['enteredDomain'];
      
      // Проверяем email верификацию
      String? verifiedDomain = await _apiService.getVerifiedDomain();
      
      debugPrint('_ensureDomainsConfigured: enteredMainDomain=$enteredMainDomain, enteredDomain=$enteredDomain, verifiedDomain=$verifiedDomain');
      
      // Если домены не настроены, используем verifiedDomain
      if ((enteredMainDomain == null || enteredDomain == null) && verifiedDomain != null) {
        if (verifiedDomain.contains('-back.')) {
          final parts = verifiedDomain.split('-back.');
          enteredDomain = parts[0];
          enteredMainDomain = parts[1];
          
          await prefs.setString('enteredMainDomain', enteredMainDomain);
          await prefs.setString('enteredDomain', enteredDomain);
          
          debugPrint('_ensureDomainsConfigured: Configured from verifiedDomain');
        }
      }
      
      // Если все еще нет доменов, пробуем QR данные
      if (enteredMainDomain == null || enteredDomain == null) {
        final qrData = await _apiService.getQrData();
        if (qrData['domain'] != null && qrData['mainDomain'] != null) {
          await prefs.setString('enteredDomain', qrData['domain']!);
          await prefs.setString('enteredMainDomain', qrData['mainDomain']!);
          
          debugPrint('_ensureDomainsConfigured: Configured from QR data');
        }
      }
    } catch (e) {
      debugPrint('_ensureDomainsConfigured: Error: $e');
    }
  }

  Future<void> navigateToScreen(
      int screenIndex, String id, String type, RemoteMessage message) async {
    try {
      debugPrint('=== START navigateToScreen ===');
      debugPrint('navigateToScreen: screenIndex=$screenIndex, id=$id, type=$type');
      
      // ✅ Сбрасываем флаг уведомлений
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

      // ✅ КРИТИЧНО: Двойная проверка навигатора
      if (navigatorKey.currentState == null) {
        debugPrint('navigateToScreen: Navigator is null, waiting...');
        await Future.delayed(Duration(seconds: 1));
        
        if (navigatorKey.currentState == null) {
          debugPrint('navigateToScreen: Navigator still null after delay, aborting');
          return;
        }
      }

      debugPrint('navigateToScreen: Navigator is ready, pushing route');

      // ✅ Сначала переходим на главный экран
      await navigatorKey.currentState!.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {'id': id, 'screenIndex': screenIndex, 'group': group},
      );

      // ✅ Небольшая задержка для завершения перехода
      await Future.delayed(Duration(milliseconds: 300));

      // ✅ Теперь переходим на конкретный экран
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
          debugPrint('navigateToScreen: Unknown type: $type');
      }
      
      debugPrint('=== END navigateToScreen ===');
    } catch (e, stackTrace) {
      debugPrint('navigateToScreen: ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

//   Future<void> navigateToChatScreen(String id, RemoteMessage message) async {
//   debugPrint('════════════════════════════════════════════════════════');
//   debugPrint('💬 NAVIGATE TO CHAT SCREEN');
//   debugPrint('════════════════════════════════════════════════════════');
//   debugPrint('Chat ID (string): $id');
  
//   final chatId = int.tryParse(id) ?? 0;
//   debugPrint('Chat ID (parsed): $chatId');
  
//   if (chatId == 0) {
//     debugPrint('❌ Invalid chatId: $chatId');
//     return;
//   }

//   try {
//     debugPrint('🔍 Loading chat data for chatId: $chatId');
    
//     if (navigatorKey.currentState == null) {
//       debugPrint('❌ Navigator not ready');
//       return;
//     }

//     debugPrint('📡 Calling _apiService.getChatById($chatId)...');
//     final getChatById = await _apiService.getChatById(chatId);
    
//     debugPrint('✅ Chat data received:');
//     debugPrint('  - Chat Type: ${getChatById.type}');
//     debugPrint('  - Chat Name: ${getChatById.name}');
//     debugPrint('  - Can Send Message: ${getChatById.canSendMessage}');
//     debugPrint('  - Chat Users Count: ${getChatById.chatUsers.length}');
//     debugPrint('  - Has Group: ${getChatById.group != null}');
//     if (getChatById.group != null) {
//       debugPrint('  - Group Name: ${getChatById.group!.name}');
//     }
    
//     Widget screen;
//     String? chatName;

//     switch (getChatById.type) {
//       case 'lead':
//         debugPrint('🎯 Chat type: LEAD');
//         chatName = getChatById.name;
//         debugPrint('  - Chat Name: $chatName');
//         break;
        
//       case 'task':
//         debugPrint('🎯 Chat type: TASK');
//         debugPrint('📡 Calling _apiService.getTaskProfile($chatId)...');
//         final chatProfileTask = await _apiService.getTaskProfile(chatId);
//         chatName = chatProfileTask.name;
//         debugPrint('  - Task Name: $chatName');
//         break;
        
//       case 'corporate':
//         debugPrint('🎯 Chat type: CORPORATE');
//         final prefs = await SharedPreferences.getInstance();
//         String userId = prefs.getString('userID').toString();
//         debugPrint('  - Current User ID: $userId');

//         if (getChatById.group != null) {
//           debugPrint('  - This is a GROUP chat');
//           chatName = getChatById.group!.name;
//           debugPrint('  - Group Name: $chatName');
//         } else {
//           debugPrint('  - This is a DIRECT chat (1-on-1)');
//           debugPrint('  - Chat Users: ${getChatById.chatUsers.length}');
          
//           // ✅ КРИТИЧЕСКАЯ ПРОВЕРКА
//           if (getChatById.chatUsers.isEmpty) {
//             debugPrint('❌ ERROR: chatUsers list is EMPTY!');
//             debugPrint('❌ Cannot determine chat name - using fallback');
//             chatName = 'Неизвестный пользователь';
//           } else if (getChatById.chatUsers.length == 1) {
//             debugPrint('⚠️ WARNING: Only 1 user in chatUsers');
//             chatName = getChatById.chatUsers[0].participant.name;
//             debugPrint('  - Using single user name: $chatName');
//           } else {
//             // Обычная логика для 2+ пользователей
//             int userIndex = getChatById.chatUsers.indexWhere(
//                 (user) => user.participant.id.toString() == userId);
//             debugPrint('  - Current user index: $userIndex');
            
//             if (userIndex != -1) {
//               int otherUserIndex = (userIndex == 0) ? 1 : 0;
//               debugPrint('  - Other user index: $otherUserIndex');
//               chatName = getChatById.chatUsers[otherUserIndex].participant.name;
//               debugPrint('  - Other user name: $chatName');
//             } else {
//               debugPrint('  - Current user not found, using first user');
//               chatName = getChatById.chatUsers[0].participant.name;
//               debugPrint('  - First user name: $chatName');
//             }
//           }
//         }
//         break;
        
//       default:
//         debugPrint('❌ Unknown chat type: ${getChatById.type}');
//         return;
//     }

//     debugPrint('📱 Creating ChatSmsScreen with:');
//     debugPrint('  - chatId: $chatId');
//     debugPrint('  - chatName: $chatName');
//     debugPrint('  - chatType: ${getChatById.type}');
//     debugPrint('  - canSendMessage: ${getChatById.canSendMessage}');

//     screen = ChatSmsScreen(
//       chatItem: Chats(
//         id: chatId,
//         name: chatName ?? 'Без имени',
//         canSendMessage: getChatById.canSendMessage,
//         image: '',
//         channel: '',
//         lastMessage: '',
//         createDate: '',
//         unreadCount: 1,
//         chatUsers: [],
//       ).toChatItem(),
//       chatId: chatId,
//       endPointInTab: getChatById.type.toString(),
//       canSendMessage: getChatById.canSendMessage,
//     );

//     debugPrint('🚀 Pushing chat screen to navigator...');
//     await navigatorKey.currentState!.push(
//       MaterialPageRoute(
//         builder: (context) => BlocProvider(
//           create: (context) => MessagingCubit(ApiService()),
//           child: screen,
//         ),
//       ),
//     );
    
//     debugPrint('✅ Chat screen pushed successfully');
//     debugPrint('════════════════════════════════════════════════════════');
//   } catch (e, stackTrace) {
//     debugPrint('════════════════════════════════════════════════════════');
//     debugPrint('❌ ERROR in navigateToChatScreen');
//     debugPrint('════════════════════════════════════════════════════════');
//     debugPrint('Error: $e');
//     debugPrint('StackTrace: $stackTrace');
//     debugPrint('════════════════════════════════════════════════════════');
//   }
// }

  // ✅ АНАЛОГИЧНО для остальных методов навигации - используем _apiService

  Future<void> navigateToTaskScreen(String id, RemoteMessage message) async {
    try {
      debugPrint('Received push notification data: ${message.data}');

      final taskId = message.data['id'];
      final taskNumber = int.tryParse(message.data['taskNumber'] ?? '');

      debugPrint('taskId: $taskId');
      debugPrint('taskNumber: $taskNumber');

      if (taskId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
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
    } catch (e, stackTrace) {
      debugPrint('navigateToTaskScreen: ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> navigateToLeadScreen(String id, RemoteMessage message) async {
    try {
      final leadId = message.data['id'];
      if (leadId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
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
    } catch (e, stackTrace) {
      debugPrint('navigateToLeadScreen: ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> navigateToMyTaskScreen(String id, RemoteMessage message) async {
    try {
      final myTaskId = message.data['id'];
      final taskNumber = int.tryParse(message.data['task_number'] ?? '');

      if (myTaskId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
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
    } catch (e, stackTrace) {
      debugPrint('navigateToMyTaskScreen: ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> navigateToEventScreen(String id, RemoteMessage message) async {
    try {
      final eventId = message.data['id'];
      if (eventId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              noticeId: eventId,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('navigateToEventScreen: ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> navigateToDealScreen(String id, RemoteMessage message) async {
    try {
      final dealId = message.data['id'];
      if (dealId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
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
    } catch (e, stackTrace) {
      debugPrint('navigateToDealScreen: ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> navigateToOrdersScreen(String id, RemoteMessage message) async {
    try {
      final orderId = int.tryParse(message.data['id'] ?? '');
      if (orderId != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
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
    } catch (e, stackTrace) {
      debugPrint('navigateToOrdersScreen: ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  // Получение FCM токена с безопасной обработкой
  Future<String?> getFCMToken() async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase не инициализирован');
        return null;
      }

      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token получен: ${token.substring(0, 20)}...');
      }
      return token;
    } catch (e) {
      debugPrint('Ошибка получения FCM токена: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase не инициализирован, не можем подписаться на топик');
        return;
      }
      
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Подписались на топик: $topic');
    } catch (e) {
      debugPrint('Ошибка подписки на топик $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase не инициализирован, не можем отписаться от топика');
        return;
      }
      
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Отписались от топика: $topic');
    } catch (e) {
      debugPrint('Ошибка отписки от топика $topic: $e');
    }
  }

  void dispose() {
    _isInitialized = false;
    _initialMessage = null;
  }
}
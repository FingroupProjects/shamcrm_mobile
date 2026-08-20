import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/app/app_feature_flags.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_details_screen.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chat_title_resolver.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/event/event_details/event_details_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_details_screen.dart';
import 'package:crm_task_manager/screens/sip/sip_screen.dart';
import 'package:crm_task_manager/screens/sip/sip_service.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _pendingIncomingCallPushPayloadKey =
    'sip_pending_incoming_call_push_payload_v1';

bool _isIncomingCallPushData(Map<String, dynamic> data) {
  return data['type']?.toString().trim() == 'incoming_call';
}

bool _isIncomingCallTerminationPushData(Map<String, dynamic> data) {
  switch (data['type']?.toString().trim().toLowerCase()) {
    case 'call_cancelled':
    case 'call_canceled':
    case 'call_ended':
    case 'call_end':
      return true;
    default:
      return false;
  }
}

Map<String, dynamic>? _normalizeIncomingCallPushData(
  Map<String, dynamic> rawData, {
  required String source,
}) {
  String? pickString(List<String> keys) {
    for (final key in keys) {
      final value = rawData[key];
      if (value == null) {
        continue;
      }
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return null;
  }

  int? pickInt(List<String> keys) {
    final value = pickString(keys);
    return value == null ? null : int.tryParse(value);
  }

  if (!_isIncomingCallPushData(rawData)) {
    return null;
  }

  final callId = pickString(<String>['call_id', 'id']);
  final callerName = pickString(<String>[
    'caller_name',
    'lead_name',
    'phone',
    'from',
  ]);
  final remoteIdentity = pickString(<String>[
        'remote_identity',
        'phone',
        'lead_name',
        'caller_name',
        'from',
      ]) ??
      callerName;

  if ((callId == null || callId.isEmpty) &&
      (remoteIdentity == null || remoteIdentity.isEmpty)) {
    return null;
  }

  return <String, dynamic>{
    'type': 'incoming_call',
    'call_id': callId,
    'lead_id': pickInt(<String>['lead_id']),
    'lead_name': pickString(<String>['lead_name']),
    'caller_name': callerName,
    'remote_identity': remoteIdentity,
    'issued_at_ms': _incomingPushIssuedAtMs(rawData),
    'source': source,
    'received_at_ms': DateTime.now().millisecondsSinceEpoch,
  };
}

int? _incomingPushIssuedAtMs(Map<String, dynamic> data) {
  const keys = <String>[
    'call_started_at_ms', 'created_at_ms', 'sent_at_ms', 'issued_at_ms',
    'timestamp_ms', 'call_started_at', 'created_at', 'sent_at', 'issued_at',
    'timestamp', 'google.sent_time',
  ];
  for (final key in keys) {
    final value = data[key];
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString().trim() ?? '');
    if (parsed != null && parsed > 0) {
      return parsed < 10000000000 ? parsed * 1000 : parsed;
    }
  }
  return null;
}

Future<void> _persistIncomingCallPushData(
  Map<String, dynamic> rawData, {
  required String source,
}) async {
  final normalized = _normalizeIncomingCallPushData(rawData, source: source);
  if (normalized == null) {
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _pendingIncomingCallPushPayloadKey,
    jsonEncode(normalized),
  );
}

// ВАЖНО: Эта функция должна быть top-level, не методом класса
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      debugPrint(
          "Firebase не инициализирован, инициализируем... FirebaseApi.Line.26");
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
    if (_isIncomingCallPushData(message.data)) {
      await _persistIncomingCallPushData(
        Map<String, dynamic>.from(message.data),
        source: 'fcm_background',
      );
    }
  } catch (e) {
    debugPrint('Ошибка обработки фонового сообщения: $e');
  }
}

class FirebaseApi {
  static final FirebaseApi _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();

  static const MethodChannel _pushChannel =
      MethodChannel('com.softtech.crm_task_manager/widget');

  final _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  RemoteMessage? _initialMessage;
  bool _isInitialized = false;
  bool _backgroundHandlerRegistered = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  static void ensureBackgroundHandlerRegistered() {
    _instance._registerBackgroundHandler();
  }

  Future<void> initNotifications() async {
    try {
      // КРИТИЧЕСКАЯ ПРОВЕРКА: Firebase должен быть инициализирован
      if (Firebase.apps.isEmpty) {
        debugPrint(
            'FirebaseApi: Firebase не инициализирован, пропускаем настройку уведомлений');
        return;
      }

      // ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Проверяем доступность default app
      try {
        Firebase.app();
      } catch (e) {
        debugPrint('FirebaseApi: Default Firebase app недоступен: $e');
        return;
      }

      // Запрашиваем разрешение только после того, как основной экран уже
      // показан. Если делать это во время старта MyApp, системный диалог
      // может потеряться при переходе с PIN/авторизации.
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('User declined or has not accepted notification permission');
        return;
      }

      await _apiService.initialize();
      debugPrint(
          'FirebaseApi: ApiService initialized with baseUrl: ${_apiService.baseUrl}');

      await syncCurrentTokenWithServer();
      if (_isInitialized) {
        debugPrint(
            'FirebaseApi уже инициализирован, токен пересинхронизирован');
        return;
      }

      _registerBackgroundHandler();
      _registerTokenRefreshListener();
      await initPushNotification();
      _isInitialized = true;
      debugPrint('FirebaseApi успешно инициализирован');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      // НЕ пробрасываем ошибку дальше
    }
  }

  Future<void> syncCurrentTokenWithServer() async {
    try {
      final fcmToken = await _getCurrentFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint(
            'FirebaseApi: Не удалось получить актуальный FCM токен для синхронизации');
        return;
      }

      await _syncTokenWithBackend(fcmToken, source: 'manual-sync');
    } catch (e) {
      debugPrint('FirebaseApi: Ошибка ручной синхронизации FCM токена: $e');
    }
  }

  Future<String?> _getCurrentFcmToken() async {
    if (Platform.isIOS) {
      final apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken == null) {
        debugPrint(
            'FirebaseApi: APNS token is not available yet. Skipping FCM token retrieval.');
        return null;
      }
    }

    return _firebaseMessaging.getToken();
  }

  Future<void> _syncTokenWithBackend(
    String fcmToken, {
    required String source,
  }) async {
    final preview =
        fcmToken.length > 20 ? '${fcmToken.substring(0, 20)}...' : fcmToken;
    debugPrint('FirebaseApi: [$source] FCM token: $preview');
    await _apiService.sendDeviceToken(fcmToken);
  }

  void _registerBackgroundHandler() {
    if (_backgroundHandlerRegistered) {
      return;
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler);
        _backgroundHandlerRegistered = true;
        debugPrint('Background message handler зарегистрирован');
      }
    } catch (e) {
      if (e.toString().contains('already')) {
        _backgroundHandlerRegistered = true;
        debugPrint('Background handler уже зарегистрирован');
      } else {
        debugPrint('Ошибка регистрации background handler: $e');
      }
    }
  }

  void _registerTokenRefreshListener() {
    if (_tokenRefreshSubscription != null) {
      return;
    }

    _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen(
      (newToken) {
        unawaited(_syncTokenWithBackend(newToken, source: 'token-refresh'));
      },
      onError: (Object error) {
        debugPrint('FirebaseApi: Ошибка onTokenRefresh: $error');
      },
    );
  }

  Future<void> initPushNotification() async {
    try {
      _initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      await _recoverPendingIncomingCallPushIfNeeded();

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('Пользователь нажал на уведомление: ${message.messageId}');
        if (_isIncomingCallTerminationPushData(message.data)) {
          unawaited(SipService().handleIncomingCallTerminationPushPayload(
            Map<String, dynamic>.from(message.data),
            source: 'opened_app',
          ));
          return;
        }
        if (_isIncomingCallPushData(message.data)) {
          unawaited(
            _handleIncomingCallPushMessage(
              message,
              source: 'opened_app',
              openSipScreen: true,
            ),
          );
          return;
        }
        handleMessage(message);
      });

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
            'Уведомление при активном приложении: ${message.notification?.title}');
        if (_isIncomingCallTerminationPushData(message.data)) {
          unawaited(SipService().handleIncomingCallTerminationPushPayload(
            Map<String, dynamic>.from(message.data),
            source: 'foreground',
          ));
          return;
        }
        if (_isIncomingCallPushData(message.data)) {
          unawaited(
            _handleIncomingCallPushMessage(
              message,
              source: 'foreground',
            ),
          );
          return;
        }
        _printCustomData(message);
        unawaited(_showForegroundPushNotification(message));
      });
    } catch (e) {
      debugPrint('Ошибка инициализации push уведомлений: $e');
    }
  }

  RemoteMessage? getInitialMessage() {
    return _initialMessage;
  }

  Future<void> _showForegroundPushNotification(RemoteMessage message) async {
    if (_isIncomingCallPushData(message.data) ||
        _isIncomingCallTerminationPushData(message.data)) {
      return;
    }

    final type = message.data['type']?.toString();
    // Android chat already posts a native heads-up from ChatQuickReplyManager.
    if (Platform.isAndroid &&
        (type == 'message' || type == 'chat_message' || type == 'new_message')) {
      return;
    }

    final title = (message.notification?.title ??
            message.data['title'] ??
            message.data['sender_name'] ??
            'shamCRM')
        .toString()
        .trim();
    final body = (message.notification?.body ??
            message.data['body'] ??
            message.data['message_text'] ??
            message.data['message'] ??
            '')
        .toString()
        .trim();
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    // iOS notification-payload messages are presented by the system once
    // foreground presentation options / willPresent allow banners.
    if (Platform.isIOS && message.notification != null) {
      return;
    }

    try {
      await _pushChannel.invokeMethod<void>('showForegroundPush', <String, dynamic>{
        'title': title.isEmpty ? 'shamCRM' : title,
        'body': body,
        'type': type,
        'id': message.data['id']?.toString() ??
            message.data['chat_id']?.toString(),
      });
    } catch (error) {
      debugPrint('FirebaseApi: failed to show foreground push: $error');
    }
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

  Future<void> _recoverPendingIncomingCallPushIfNeeded() async {
    try {
      await SipService().recoverPendingIncomingCallPush();
    } catch (error) {
      debugPrint(
        'FirebaseApi: failed to recover pending incoming_call push: $error',
      );
    }
  }

  Future<void> _handleIncomingCallPushMessage(
    RemoteMessage message, {
    required String source,
    bool openSipScreen = false,
  }) async {
    if (!kShowSip) {
      return;
    }
    final payload = Map<String, dynamic>.from(message.data);
    await _persistIncomingCallPushData(payload, source: source);
    await SipService().handleIncomingCallPushPayload(
      payload,
      source: source,
      persist: false,
    );

    if (!openSipScreen) {
      return;
    }

    int attempts = 0;
    while (navigatorKey.currentState == null && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 250));
      attempts++;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const SipScreen(
          initialTab: SipScreenInitialTab.journal,
        ),
      ),
    );
  }

  Future<void> handleMessage(RemoteMessage? message) async {
    try {
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('🔔 FIREBASE API: PUSH NOTIFICATION RECEIVED');
      debugPrint('════════════════════════════════════════════════════════');

      if (message == null) {
        debugPrint('❌ Message is NULL');
        return;
      }

      debugPrint('📦 Message Data: ${message.data}');

      if (message.data.isEmpty) {
        debugPrint('❌ Message data is EMPTY');
        return;
      }

      if (_isIncomingCallPushData(message.data)) {
        await _handleIncomingCallPushMessage(
          message,
          source: 'handle_message',
          openSipScreen: true,
        );
        return;
      }

      final type = message.data['type'];
      final id = message.data['id'];

      debugPrint('🎯 Notification Type: $type');
      debugPrint('🎯 Notification ID: $id');

      if (type == null || id == null) {
        debugPrint('❌ Type or ID is NULL');
        return;
      }

      // ✅ КРИТИЧНО: Ждем готовность навигатора
      debugPrint('⏳ Waiting for Navigator...');
      int attempts = 0;
      while (navigatorKey.currentState == null && attempts < 20) {
        await Future.delayed(Duration(milliseconds: 300));
        attempts++;
      }

      if (navigatorKey.currentState == null) {
        debugPrint('❌ Navigator STILL NULL after waiting');
        return;
      }
      debugPrint('✅ Navigator is READY');

      // ✅ Проверяем домены и ApiService
      await _ensureDomainsConfigured();

      if (!_isInitialized) {
        await _apiService.initialize();
      }

      // ✅ ИСПРАВЛЕНИЕ: СРАЗУ открываем нужный экран, БЕЗ перехода на /home
      debugPrint('🎯 Opening specific screen directly for type: $type');
      await navigateToSpecificScreen(type, id, message);

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

// ✅ ИСПРАВЛЕНИЕ: Упрощенная навигация - СРАЗУ на нужный экран
  Future<void> navigateToSpecificScreen(
      String type, String id, RemoteMessage message) async {
    try {
      debugPrint('🚀 navigateToSpecificScreen: type=$type, id=$id');

      switch (type) {
        case 'message':
          await navigateToChatScreen(id, message);
          break;
        case 'task':
        case 'taskFinished':
        case 'taskOutDated':
          await navigateToTaskScreen(id, message);
          break;
        case 'lead':
        case 'notice':
        case 'updateLeadStatus':
          await navigateToLeadScreen(id, message);
          break;
        case 'myTaskOutDated':
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
          debugPrint('❓ Unknown type: $type');
      }
    } catch (e, stackTrace) {
      debugPrint('navigateToSpecificScreen: ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> navigateToChatScreen(String id, RemoteMessage message) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('💬 NAVIGATE TO CHAT SCREEN');
    debugPrint('═══════════════════════════════════════════════════════');

    final chatId = int.tryParse(id) ?? 0;

    if (chatId == 0 || navigatorKey.currentState == null) {
      debugPrint('❌ Invalid chatId or navigator');
      return;
    }

    // ✅ ПОКАЗЫВАЕМ ОДИН ЛОАДЕР
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CircularProgressIndicator(
            color: Color(0xff1E2E52),
          ),
        ),
      ),
    );

    try {
      debugPrint('📡 Loading chat data...');
      final getChatById = await _apiService.getChatById(chatId);

      debugPrint('✅ Chat loaded: ${getChatById.type}');

      if (getChatById.type != 'lead' &&
          getChatById.type != 'task' &&
          getChatById.type != 'corporate') {
        debugPrint('❌ Unknown chat type: ${getChatById.type}');
        Navigator.of(navigatorKey.currentContext!).pop();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final chatName = await ChatTitleResolver.resolve(
        apiService: _apiService,
        chat: getChatById,
        currentUserId: prefs.getString('userID'),
        pushFallback: ChatTitleResolver.fromPush(
          data: message.data,
          notificationTitle: message.notification?.title,
        ),
      );
      debugPrint('🎯 Resolved push chat title: "$chatName"');

      final screen = ChatSmsScreen(
        chatItem: Chats(
          id: chatId,
          uniqueId: getChatById.uniqueId,
          name: ChatTitleResolver.clean(chatName) ?? 'Чат #$chatId',
          canSendMessage: getChatById.canSendMessage,
          image: '',
          channel: getChatById.channelName,
          lastMessage: '',
          createDate: '',
          unreadCount: 1,
          chatUsers: const [],
          type: getChatById.type,
          group: getChatById.group,
        ).toChatItem(),
        chatId: chatId,
        chatUniqueId: getChatById.uniqueId,
        endPointInTab: getChatById.type.toString(),
        canSendMessage: getChatById.canSendMessage,
      );

      // ✅ ЗАКРЫВАЕМ ЛОАДЕР
      Navigator.of(navigatorKey.currentContext!).pop();

      // ✅ ОТКРЫВАЕМ ЭКРАН
      await navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => MessagingCubit(ApiService()),
            child: screen,
          ),
        ),
      );

      debugPrint('✅ Chat screen opened');
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      // ✅ ЗАКРЫВАЕМ ЛОАДЕР при ошибке
      try {
        Navigator.of(navigatorKey.currentContext!).pop();
      } catch (_) {}

      debugPrint('❌ ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
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

      debugPrint(
          '_ensureDomainsConfigured: enteredMainDomain=$enteredMainDomain, enteredDomain=$enteredDomain, verifiedDomain=$verifiedDomain');

      // Если домены не настроены, используем verifiedDomain
      if ((enteredMainDomain == null || enteredDomain == null) &&
          verifiedDomain != null) {
        if (verifiedDomain.contains('-back.')) {
          final parts = verifiedDomain.split('-back.');
          enteredDomain = parts[0];
          enteredMainDomain = parts[1];

          await prefs.setString('enteredMainDomain', enteredMainDomain);
          await prefs.setString('enteredDomain', enteredDomain);

          debugPrint(
              '_ensureDomainsConfigured: Configured from verifiedDomain');
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

  // Future<void> navigateToScreen(
  //     int screenIndex, String id, String type, RemoteMessage message) async {
  //   try {
  //     debugPrint('=== START navigateToScreen ===');
  //     debugPrint('navigateToScreen: screenIndex=$screenIndex, id=$id, type=$type');

  //     // ✅ Сбрасываем флаг уведомлений
  //     SharedPreferences.getInstance().then((prefs) {
  //       prefs.setBool('hasNewNotification', false);
  //     });

  //     int group = 1;
  //     if (type == 'message' ||
  //         type == 'task' ||
  //         type == 'lead' ||
  //         type == 'dealDeadLineNotification' ||
  //         type == 'eventId' ||
  //         type == 'myTask') {
  //       group = 1;
  //     } else {
  //       group = 2;
  //     }

  //     // ✅ КРИТИЧНО: Двойная проверка навигатора
  //     if (navigatorKey.currentState == null) {
  //       debugPrint('navigateToScreen: Navigator is null, waiting...');
  //       await Future.delayed(Duration(seconds: 1));

  //       if (navigatorKey.currentState == null) {
  //         debugPrint('navigateToScreen: Navigator still null after delay, aborting');
  //         return;
  //       }
  //     }

  //     debugPrint('navigateToScreen: Navigator is ready, pushing route');

  //     // ✅ Сначала переходим на главный экран
  //     await navigatorKey.currentState!.pushNamedAndRemoveUntil(
  //       '/home',
  //       (route) => false,
  //       arguments: {'id': id, 'screenIndex': screenIndex, 'group': group},
  //     );

  //     // ✅ Небольшая задержка для завершения перехода
  //     await Future.delayed(Duration(milliseconds: 300));

  //     // ✅ Теперь переходим на конкретный экран
  //     switch (type) {
  //       case 'message':
  //         await navigateToChatScreen(id, message);
  //         break;
  //       case 'task':
  //         await navigateToTaskScreen(id, message);
  //         break;
  //       case 'lead':
  //         await navigateToLeadScreen(id, message);
  //         break;
  //       case 'myTask':
  //         await navigateToMyTaskScreen(id, message);
  //         break;
  //       case 'eventId':
  //         await navigateToEventScreen(id, message);
  //         break;
  //       case 'dealDeadLineNotification':
  //         await navigateToDealScreen(id, message);
  //         break;
  //       case 'orders':
  //         await navigateToOrdersScreen(id, message);
  //         break;
  //       default:
  //         debugPrint('navigateToScreen: Unknown type: $type');
  //     }

  //     debugPrint('=== END navigateToScreen ===');
  //   } catch (e, stackTrace) {
  //     debugPrint('navigateToScreen: ERROR: $e');
  //     debugPrint('StackTrace: $stackTrace');
  //   }
  // }

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
      debugPrint('📋 NAVIGATE TO TASK SCREEN: id=$id');

      final taskId = message.data['id'];
      final taskNumber = int.tryParse(message.data['taskNumber'] ?? '');

      if (taskId == null || navigatorKey.currentState == null) {
        debugPrint('❌ Invalid taskId or navigator');
        return;
      }

      // ✅ ПОКАЗЫВАЕМ ОДИН ЛОАДЕР
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        barrierColor: Colors.black26,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CircularProgressIndicator(
              color: Color(0xff1E2E52),
            ),
          ),
        ),
      );

      try {
        debugPrint('📡 Loading task details...');
        final taskDetails = await _apiService.getTaskById(int.parse(taskId));

        // ✅ ЗАКРЫВАЕМ ЛОАДЕР
        Navigator.of(navigatorKey.currentContext!).pop();

        // ✅ ОТКРЫВАЕМ ЭКРАН
        await navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(
              taskId: taskId,
              taskName: taskDetails.name,
              taskStatus: '',
              statusId: 1,
              taskNumber: taskNumber,
              customFields: [],
            ),
          ),
        );

        debugPrint('✅ Task screen opened');
      } catch (e) {
        // ✅ ЗАКРЫВАЕМ ЛОАДЕР при ошибке
        try {
          Navigator.of(navigatorKey.currentContext!).pop();
        } catch (_) {}
        debugPrint('❌ Error loading task: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> navigateToLeadScreen(String id, RemoteMessage message) async {
    try {
      debugPrint('👤 NAVIGATE TO LEAD SCREEN: id=$id');

      final leadId = message.data['id'];

      if (leadId == null || navigatorKey.currentState == null) {
        debugPrint('❌ Invalid leadId or navigator');
        return;
      }

      // ✅ БЕЗ ЛОАДЕРА - Lead экран быстро загружается
      await navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => LeadDetailsScreen(
            leadId: leadId.toString(),
            leadName: '',
            leadStatus: '',
            statusId: 0,
          ),
        ),
      );

      debugPrint('✅ Lead screen opened');
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> navigateToMyTaskScreen(String id, RemoteMessage message) async {
    try {
      final myTaskId = message.data['id'];
      final taskNumber = int.tryParse(message.data['task_number'] ?? '');

      if (myTaskId != null && navigatorKey.currentState != null) {
        await navigatorKey.currentState!.push(
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
        debugPrint('✅ MyTask screen opened');
      }
    } catch (e) {
      debugPrint('❌ ERROR: $e');
    }
  }

  Future<void> navigateToEventScreen(String id, RemoteMessage message) async {
    try {
      final eventId = message.data['id'];
      if (eventId != null && navigatorKey.currentState != null) {
        await navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              noticeId: eventId,
            ),
          ),
        );
        debugPrint('✅ Event screen opened');
      }
    } catch (e) {
      debugPrint('❌ ERROR: $e');
    }
  }

  Future<void> navigateToDealScreen(String id, RemoteMessage message) async {
    try {
      final dealId = message.data['id'];
      if (dealId != null && navigatorKey.currentState != null) {
        await navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => DealDetailsScreen(
              dealId: dealId.toString(),
              dealName: '',
              sum: '',
              dealStatus: '',
              statusId: 1,
            ),
          ),
        );
        debugPrint('✅ Deal screen opened');
      }
    } catch (e) {
      debugPrint('❌ ERROR: $e');
    }
  }

  Future<void> navigateToOrdersScreen(String id, RemoteMessage message) async {
    try {
      final orderId = int.tryParse(message.data['id'] ?? '');
      if (orderId != null && navigatorKey.currentState != null) {
        await navigatorKey.currentState!.push(
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
        debugPrint('✅ Order screen opened');
      }
    } catch (e) {
      debugPrint('❌ ERROR: $e');
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
        debugPrint(
            'Firebase не инициализирован, не можем подписаться на топик');
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
        debugPrint(
            'Firebase не инициализирован, не можем отписаться от топика');
        return;
      }

      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Отписались от топика: $topic');
    } catch (e) {
      debugPrint('Ошибка отписки от топика $topic: $e');
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _isInitialized = false;
    _initialMessage = null;
    _backgroundHandlerRegistered = false;
  }
}

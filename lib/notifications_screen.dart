import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_bloc.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_event.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationBloc notificationBloc;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  // ✅ КРИТИЧНО: Один экземпляр ApiService для всего экрана
  late final ApiService _apiService;
  bool _isApiServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    notificationBloc = BlocProvider.of<NotificationBloc>(context);
    notificationBloc.add(FetchNotifications());

    // ✅ КРИТИЧНО: Инициализируем ApiService один раз
    _initializeApiService();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          !notificationBloc.allNotificationsFetched) {
        _isLoadingMore = true;
        debugPrint('📄 [PAGINATION] Загрузка следующей страницы');

        notificationBloc.add(FetchMoreNotifications(
            notificationBloc.state is NotificationDataLoaded
                ? (notificationBloc.state as NotificationDataLoaded).currentPage
                : 1));
      }
    });
  }

// ✅ НОВЫЙ МЕТОД: Получаем имя из socket presence
  Future<String?> _getChatNameFromSocket(int chatId) async {
    try {
      debugPrint('🔌 Getting chat name from socket for chatId: $chatId');

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String userId = prefs.getString('userID').toString();

      if (token == null) {
        debugPrint('❌ No token available');
        return null;
      }

      final enteredDomainMap = await ApiService().getEnteredDomain();
      String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      String? enteredDomain = enteredDomainMap['enteredDomain'];
      String? verifiedDomain = await ApiService().getVerifiedDomain();

      if (enteredMainDomain == null || enteredDomain == null) {
        if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
          enteredMainDomain = verifiedDomain.split('-back.').last;
          enteredDomain = verifiedDomain.split('-back.').first;
        } else {
          debugPrint('❌ No domain configuration');
          return null;
        }
      }

      final customOptions = PusherChannelsOptions.custom(
        uriResolver: (metadata) =>
            Uri.parse('wss://soketi.$enteredMainDomain/app/app-key'),
        metadata: PusherChannelsOptionsMetadata.byDefault(),
      );

      final tempSocketClient = PusherChannelsClient.websocket(
          options: customOptions,
          connectionErrorHandler:
              (exception, StackTrace trace, void Function() refresh) {});

      final presenceChannel = tempSocketClient.presenceChannel(
        'presence-chat.$chatId',
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPresenceChannel(
          authorizationEndpoint: Uri.parse(
              'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth'),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Tenant': '$enteredDomain-back',
          },
        ),
      );

      String? otherUserName;
      final completer = Completer<String?>();

      // Слушаем событие успешной подписки
      final subscription =
          presenceChannel.bind('pusher:subscription_succeeded').listen((event) {
        try {
          debugPrint('✅ Socket subscription succeeded: ${event.data}');
          final data = json.decode(event.data);

          // Пример данных: {"presence":{"ids":["11","8"],"hash":{"8":{"id":8,"name":"Дилшодчон"},"11":{"id":11,"name":"Баховаддинхон"}},"count":2}}
          final presence = data['presence'];

          if (presence != null && presence['hash'] != null) {
            final hash = presence['hash'] as Map<String, dynamic>;
            debugPrint('📊 Socket presence hash: $hash');
            debugPrint('📊 Current userId: $userId');

            // Находим ДРУГОГО участника (не текущего пользователя)
            for (var entry in hash.entries) {
              final participantId = entry.key;
              final participantData = entry.value;

              debugPrint(
                  '   Checking participant ID: $participantId, name: ${participantData['name']}');

              if (participantId != userId) {
                otherUserName = participantData['name'];
                debugPrint(
                    '✅ Found OTHER user: $otherUserName (ID: $participantId)');
                completer.complete(otherUserName);
                return;
              }
            }

            // Если не нашли другого пользователя, берем первого
            if (otherUserName == null && hash.isNotEmpty) {
              final firstUser = hash.values.first;
              otherUserName = firstUser['name'];
              debugPrint('⚠️ Taking first user as fallback: $otherUserName');
              completer.complete(otherUserName);
            } else {
              completer.complete(null);
            }
          } else {
            debugPrint('❌ No presence hash in socket data');
            completer.complete(null);
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing socket presence: $e');
          debugPrint('StackTrace: $stackTrace');
          completer.complete(null);
        }
      });

      // Обработка ошибок подключения
      tempSocketClient.onConnectionEstablished.listen((_) {
        debugPrint('🔌 Socket connected for presence check');
        presenceChannel.subscribeIfNotUnsubscribed();
      });

      await tempSocketClient.connect();

      // Ждем максимум 3 секунды
      final result = await completer.future.timeout(
        Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏱️ Socket presence timeout');
          return null;
        },
      );

      // Очистка
      subscription.cancel();
      tempSocketClient.dispose();

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Socket error: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  // ✅ НОВЫЙ МЕТОД: Инициализация ApiService
  Future<void> _initializeApiService() async {
    try {
      debugPrint('🔧 Initializing ApiService for NotificationsScreen...');
      _apiService = ApiService();
      await _apiService.initialize();
      _isApiServiceInitialized = true;
      debugPrint('✅ ApiService initialized: baseUrl = ${_apiService.baseUrl}');
    } catch (e) {
      debugPrint('❌ Failed to initialize ApiService: $e');
      _isApiServiceInitialized = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    debugPrint('🔄 [REFRESH] Обновление списка уведомлений');
    notificationBloc.add(FetchNotifications());
    return Future.delayed(Duration(milliseconds: 1500));
  }

void _clearAllNotifications() async {
  debugPrint('🗑️ [DELETE ALL] Запрос на удаление всех уведомлений');

  // Проверяем, есть ли уведомления
  if (notificationBloc.state is NotificationDataLoaded) {
    final currentState = notificationBloc.state as NotificationDataLoaded;
    if (currentState.notifications.isEmpty) {
      debugPrint('⚠️ Нет уведомлений для удаления');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('no_notifications_to_delete') ?? 
              'Нет уведомлений для удаления',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Color(0xff5A6B87),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
  }
final bool? confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.translate('confirm_delete') ?? 
                'Подтверждение',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                  fontFamily: 'Gilroy',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('delete_all_notifications_message') ?? 
          'Вы уверены, что хотите удалить все уведомления? Это действие нельзя отменить.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xff5A6B87),
            fontFamily: 'Gilroy',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(
              AppLocalizations.of(context)!.translate('cancel') ?? 'Отмена',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff5A6B87),
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('delete') ?? 'Удалить',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
        ],
      );
    },
  );

  // ✅ ЕСЛИ ПОЛЬЗОВАТЕЛЬ ПОДТВЕРДИЛ - УДАЛЯЕМ
  if (confirmed == true) {
    debugPrint('✅ Пользователь подтвердил удаление');
    
    notificationBloc.add(DeleteAllNotification());

    // Обновляем флаг в SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('hasNewNotification', false);
    });
  } else {
    debugPrint('❌ Пользователь отменил удаление');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FD),
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.translate('notifications'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xff1E2E52)),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Color(0xff1E2E52),
              ),
              onPressed: _clearAllNotifications,
            ),
          ),
        ],
      ),
      body: BlocListener<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationDataLoaded) {
            _isLoadingMore = false;
            debugPrint(
                '✅ [STATE] Данные загружены, всего: ${state.notifications.length}');
            debugPrint(
                '📊 [STATE] Все загружено: ${notificationBloc.allNotificationsFetched}');
          } else if (state is NotificationError) {
            _isLoadingMore = false;
            debugPrint('❌ [STATE] Ошибка: ${state.message}');
          }

          final successCodes = [200, 201, 204, 429];

          if (state is NotificationSuccess) {
            if (state.statusCode != null &&
                successCodes.contains(state.statusCode)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.green,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else if (state is NotificationDeleted) {
            if (state.statusCode != null &&
                successCodes.contains(state.statusCode)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!
                        .translate('all_notifications_deleted_successfully'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.green,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else if (state is NotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.red,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            debugPrint("🔄 [BUILD] Состояние BLoC: ${state.runtimeType}");

            if (state is NotificationLoading) {
              debugPrint("🔄 [BUILD] Показываем начальную загрузку");
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xff1E2E52)));
            } else if (state is NotificationError) {
              debugPrint("❌ [BUILD] Ошибка: ${state.message}");
              return Center(child: Text(state.message));
            } else if (state is NotificationDeleted) {
              return RefreshIndicator(
                color: Color(0xff1E2E52),
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                    Center(
                        child: Text(AppLocalizations.of(context)!
                            .translate('no_notifications_yet'))),
                  ],
                ),
              );
            } else if (state is NotificationDataLoaded) {
              final notifications = state.notifications;
              final isAllLoaded = notificationBloc.allNotificationsFetched;

              debugPrint(
                  "✅ [BUILD] Уведомлений: ${notifications.length}, все загружено: $isAllLoaded");

              return RefreshIndicator(
                color: Color(0xff1E2E52),
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: notifications.isEmpty
                    ? ListView(
                        physics: AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4),
                          Center(
                              child: Text(AppLocalizations.of(context)!
                                  .translate('no_notifications_yet'))),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: notifications.length + (isAllLoaded ? 0 : 1),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        itemBuilder: (context, index) {
                          if (index == notifications.length) {
                            if (!isAllLoaded && _isLoadingMore) {
                              debugPrint(
                                  "🔄 [BUILD] Показываем индикатор пагинации");
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                    child: CircularProgressIndicator(
                                  color: Color(0xff1E2E52),
                                  strokeWidth: 2,
                                )),
                              );
                            } else if (!isAllLoaded) {
                              return const SizedBox(height: 50);
                            } else {
                              return const SizedBox.shrink();
                            }
                          }

                          final notification = notifications[index];

                          return Dismissible(
                            key: Key(notification.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.centerRight,
                              child: const Icon(Icons.delete,
                                  color: Colors.white, size: 24),
                            ),
                            onDismissed: (direction) {
                              debugPrint(
                                  "🗑️ [DELETE] Удаление уведомления ID: ${notification.id}");
                              setState(() {
                                notifications.removeAt(index);
                              });
                              notificationBloc
                                  .add(DeleteNotification(notification.id));
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.notifications,
                                    color: Color(0xff1E2E52), size: 24),
                                title: Text(
                                  _getNotificationTitle(
                                      context, notification.type),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.message,
                                      maxLines: 2,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xff5A6B87),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          DateFormat('dd.MM.yyyy HH:mm').format(
                                              notification.createdAt
                                                  .add(Duration(hours: 5))),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Gilroy',
                                            color: Color(0xff1E2E52),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  debugPrint(
                                      "🔔 [TAP] Нажатие на уведомление ID: ${notification.id}, тип: ${notification.type}");
                                  navigateToScreen(notification.type,
                                      notification.id, notification.modelId);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              );
            }

            debugPrint("⚠️ [BUILD] Неизвестное состояние");
            return Container();
          },
        ),
      ),
    );
  }

  String _getNotificationTitle(BuildContext context, String type) {
    final localizations = AppLocalizations.of(context)!;

    switch (type) {
      case 'message':
        return localizations.translate('new_message');
      case 'dealDeadLineNotification':
        return localizations.translate('deal_reminder');
      case 'notice':
        return localizations.translate('note_reminder');
      case 'task':
        return localizations.translate('task_new');
      case 'taskFinished':
        return localizations.translate('task_closed');
      case 'taskOutDated':
        return localizations.translate('task_deadline_reminder');
      case 'lead':
        return localizations.translate('task_deadline_reminder');
      case 'myTaskOutDated':
        return localizations.translate('Напоминание о просрочке мои задачи');
      case 'updateLeadStatus':
        return localizations.translate('Статус лида изменен!');
      default:
        return type;
    }
  }

  Future<void> navigateToScreen(
      String type, int notificationId, int chatId) async {
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('🔔 navigateToScreen STARTED');
    debugPrint('type: $type, notificationId: $notificationId, chatId: $chatId');
    debugPrint('════════════════════════════════════════════════════════');

    // ✅ КРИТИЧНО: Проверяем инициализацию ApiService
    if (!_isApiServiceInitialized) {
      debugPrint('⚠️ ApiService not initialized, initializing now...');
      await _initializeApiService();

      if (!_isApiServiceInitialized) {
        debugPrint('❌ Failed to initialize ApiService, aborting navigation');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка инициализации. Попробуйте снова.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    try {
     if (type == 'message') {
  debugPrint('📱 Processing MESSAGE type notification');

  // ✅ ПОКАЗЫВАЕМ LOADER
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black26,
    builder: (context) {
      return Center(
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
      );
    },
  );

  try {
    debugPrint('📡 Calling getChatById($chatId)...');
    debugPrint('📡 Using ApiService with baseUrl: ${_apiService.baseUrl}');

    final getChatById = await _apiService.getChatById(chatId);
    debugPrint('✅ getChatById completed: type=${getChatById.type}');

    // ✅ НЕ ЗАКРЫВАЕМ LOADER ЗДЕСЬ, если это corporate без данных
    bool shouldCloseLoader = true;

    Widget? chatScreen;
    String chatName = '';
    String endPointInTab = '';

    if (getChatById.type == "lead") {
      debugPrint('🎯 Creating LEAD chat screen');
      endPointInTab = 'lead';
      chatName = getChatById.name.isNotEmpty
          ? getChatById.name
          : 'Лид #$chatId';

      chatScreen = ChatSmsScreen(
        chatItem: Chats(
          id: chatId,
          name: chatName,
          image: '',
          channel: "",
          lastMessage: "",
          messageType: "",
          createDate: "",
          unreadCount: 0,
          canSendMessage: getChatById.canSendMessage,
          chatUsers: [],
        ).toChatItem(),
        chatId: chatId,
        endPointInTab: endPointInTab,
        canSendMessage: getChatById.canSendMessage,
      );
    } else if (getChatById.type == "task") {
      debugPrint('🎯 Creating TASK chat screen');
      debugPrint('📡 Calling getTaskProfile($chatId)...');
      endPointInTab = 'task';

      final chatProfileTask = await _apiService.getTaskProfile(chatId);
      debugPrint('✅ getTaskProfile completed: name=${chatProfileTask.name}');

      chatName = chatProfileTask.name.isNotEmpty
          ? chatProfileTask.name
          : 'Задача #$chatId';

      chatScreen = ChatSmsScreen(
        chatItem: Chats(
          id: chatId,
          name: chatName,
          image: '',
          channel: "",
          lastMessage: "",
          messageType: "",
          createDate: "",
          unreadCount: 0,
          canSendMessage: getChatById.canSendMessage,
          chatUsers: [],
        ).toChatItem(),
        chatId: chatId,
        endPointInTab: endPointInTab,
        canSendMessage: getChatById.canSendMessage,
      );
    } else if (getChatById.type == "corporate") {
      debugPrint('🎯 Creating CORPORATE chat screen');
      endPointInTab = 'corporate';

      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID').toString();

      debugPrint('📊 Server data: name="${getChatById.name}", chatUsers.length=${getChatById.chatUsers.length}, group=${getChatById.group?.name}');

      if (getChatById.group != null) {
        chatName = getChatById.group!.name;
        debugPrint('✅ [1] Using GROUP name: $chatName');
      }
      else if (getChatById.name.isNotEmpty && getChatById.name != 'null') {
        chatName = getChatById.name;
        debugPrint('✅ [2] Using server name: $chatName');
      }
      else if (getChatById.chatUsers.isNotEmpty && getChatById.chatUsers.length >= 2) {
        int userIndex = getChatById.chatUsers.indexWhere(
          (user) => user.participant.id.toString() == userId
        );

        if (userIndex != -1) {
          int otherUserIndex = (userIndex == 0) ? 1 : 0;
          chatName = getChatById.chatUsers[otherUserIndex].participant.name;
          debugPrint('✅ [3] Using OTHER user from chatUsers: $chatName');
        } else {
          chatName = getChatById.chatUsers[0].participant.name;
          debugPrint('✅ [4] Using first chatUser: $chatName');
        }
      }
      else {
        // ✅ НЕ ЗАКРЫВАЕМ LOADER - продолжаем крутить, пока грузим из socket
        debugPrint('⚠️ Server returned NO data, getting from socket...');
        shouldCloseLoader = false; // ✅ Оставляем loader крутиться

        try {
          final socketName = await _getChatNameFromSocket(chatId);

          if (socketName != null && socketName.isNotEmpty) {
            chatName = socketName;
            debugPrint('✅ [5] Got name from socket: $chatName');
          } else {
            chatName = 'Корпоративный чат';
            debugPrint('⚠️ [6] Socket returned nothing, using fallback');
          }
        } catch (e) {
          debugPrint('❌ Error getting socket name: $e');
          chatName = 'Корпоративный чат';
        }

        // ✅ ТЕПЕРЬ можно закрыть loader
        shouldCloseLoader = true;
      }

      debugPrint('🎯 FINAL chatName: "$chatName"');

      chatScreen = ChatSmsScreen(
        chatItem: Chats(
          id: chatId,
          image: '',
          name: chatName,
          channel: "",
          lastMessage: "",
          messageType: "",
          createDate: "",
          unreadCount: 0,
          canSendMessage: getChatById.canSendMessage,
          chatUsers: [],
        ).toChatItem(),
        chatId: chatId,
        endPointInTab: endPointInTab,
        canSendMessage: getChatById.canSendMessage,
      );
    }

    // ✅ ЗАКРЫВАЕМ LOADER только если нужно
    if (shouldCloseLoader && mounted) {
      Navigator.of(context).pop();
      debugPrint('✅ Loader closed');
    }

    if (chatScreen != null) {
      debugPrint('🚀 Pushing chat screen to navigator...');
      debugPrint('📋 Chat details: name="$chatName", endPoint="$endPointInTab"');

      await navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => MessagingCubit(ApiService()),
            child: chatScreen!,
          ),
        ),
      );

      debugPrint('✅ Navigation completed successfully');

      if (mounted) {
        debugPrint('🗑️ Removing notification from list');
        setState(() {
          (notificationBloc.state as NotificationDataLoaded)
              .notifications
              .removeWhere((notification) => notification.id == notificationId);
        });
        notificationBloc.add(DeleteNotification(notificationId));
        debugPrint('✅ Notification removed');
      }
    } else {
      debugPrint('❌ chatScreen is NULL - unknown chat type: ${getChatById.type}');
    }

  } catch (e, stackTrace) {
    debugPrint('❌ ERROR in message navigation: $e');
    debugPrint('StackTrace: $stackTrace');

    if (mounted) {
      try {
        Navigator.of(context).pop(); // Закрываем loader при ошибке
      } catch (_) {}
    }

    if (e.toString().contains('404')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ресурс не найден.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}else if (type == 'task' ||
          type == 'taskFinished' ||
          type == 'taskOutDated') {
        debugPrint('📋 Processing TASK type notification');

        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black26,
          builder: (context) {
            return Center(
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
            );
          },
        );

        try {
          debugPrint('📡 Calling getTaskById($chatId)...');
          final taskDetails = await _apiService.getTaskById(chatId);
          debugPrint('✅ getTaskById completed: name=${taskDetails.name}');

          if (mounted) {
            Navigator.of(context).pop();
          }

          debugPrint('🚀 Pushing task screen to navigator...');
          await navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(
                taskId: chatId.toString(),
                taskName: taskDetails.name,
                taskStatus: '',
                statusId: 1,
                taskNumber: 0,
                customFields: [],
              ),
            ),
          );

          debugPrint('✅ Task navigation completed');

          if (mounted) {
            debugPrint('🗑️ Removing notification from list');
            setState(() {
              (notificationBloc.state as NotificationDataLoaded)
                  .notifications
                  .removeWhere(
                      (notification) => notification.id == notificationId);
            });
            notificationBloc.add(DeleteNotification(notificationId));
            debugPrint('✅ Notification removed');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ ERROR in task navigation: $e');
          debugPrint('StackTrace: $stackTrace');

          if (mounted) {
            try {
              Navigator.of(context).pop();
            } catch (_) {}
          }
        }
      } else if (type == 'notice') {
        debugPrint('📝 Processing NOTICE type notification');

        debugPrint('🚀 Pushing lead screen to navigator...');
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => LeadDetailsScreen(
              leadId: chatId.toString(),
              leadName: '',
              leadStatus: "",
              statusId: 1,
            ),
          ),
        );

        debugPrint('✅ Notice navigation completed');

        if (mounted) {
          debugPrint('🗑️ Removing notification from list');
          setState(() {
            (notificationBloc.state as NotificationDataLoaded)
                .notifications
                .removeWhere(
                    (notification) => notification.id == notificationId);
          });
          notificationBloc.add(DeleteNotification(notificationId));
          debugPrint('✅ Notification removed');
        }
      } else if (type == 'dealDeadLineNotification') {
        debugPrint('💼 Processing DEAL type notification');

        List<DealCustomField> defaultCustomFields = [
          DealCustomField(id: 1, key: '', value: ''),
          DealCustomField(id: 2, key: '', value: ''),
        ];

        debugPrint('🚀 Pushing deal screen to navigator...');
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DealDetailsScreen(
              dealId: chatId.toString(),
              dealName: '',
              sum: '',
              dealStatus: '',
              statusId: 1,
            ),
          ),
        );

        debugPrint('✅ Deal navigation completed');

        if (mounted) {
          debugPrint('🗑️ Removing notification from list');
          setState(() {
            (notificationBloc.state as NotificationDataLoaded)
                .notifications
                .removeWhere(
                    (notification) => notification.id == notificationId);
          });
          notificationBloc.add(DeleteNotification(notificationId));
          debugPrint('✅ Notification removed');
        }
      } else if (type == 'lead' || type == 'updateLeadStatus') {
        debugPrint('👤 Processing LEAD type notification');

        debugPrint('🚀 Pushing lead screen to navigator...');
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => LeadDetailsScreen(
              leadId: chatId.toString(),
              leadName: '',
              leadStatus: '',
              statusId: 1,
            ),
          ),
        );

        debugPrint('✅ Lead navigation completed');

        if (mounted) {
          debugPrint('🗑️ Removing notification from list');
          setState(() {
            (notificationBloc.state as NotificationDataLoaded)
                .notifications
                .removeWhere(
                    (notification) => notification.id == notificationId);
          });
          notificationBloc.add(DeleteNotification(notificationId));
          debugPrint('✅ Notification removed');
        }
      } else if (type == 'myTaskOutDated') {
        debugPrint('📋 Processing MY TASK type notification');

        debugPrint('🚀 Pushing my task screen to navigator...');
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => MyTaskDetailsScreen(
              taskId: chatId.toString(),
              taskName: '',
              taskStatus: '',
              statusId: 1,
              taskNumber: 0,
            ),
          ),
        );

        debugPrint('✅ MyTask navigation completed');

        if (mounted) {
          debugPrint('🗑️ Removing notification from list');
          setState(() {
            (notificationBloc.state as NotificationDataLoaded)
                .notifications
                .removeWhere(
                    (notification) => notification.id == notificationId);
          });
          notificationBloc.add(DeleteNotification(notificationId));
          debugPrint('✅ Notification removed');
        }
      } else {
        debugPrint('❓ Unknown notification type: $type');
      }

      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('✅ navigateToScreen COMPLETED');
      debugPrint('════════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('❌ CRITICAL ERROR in navigateToScreen');
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('════════════════════════════════════════════════════════');
    }
  }
}

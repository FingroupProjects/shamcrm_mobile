import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:html/parser.dart' show parse;
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_bloc.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_event.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_state.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/notifications_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/home_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:crm_task_manager/widgets/app_overlay_dialogs.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Функция для удаления HTML тегов и получения чистого текста
String _stripHtmlTags(String html) {
  if (!html.contains('<') || !html.contains('>')) {
    return html; // Если нет HTML тегов, возвращаем как есть
  }

  try {
    final document = parse(html);
    return document.body?.text ?? html.replaceAll(RegExp(r'<[^>]*>'), '');
  } catch (e) {
    // Если парсинг не удался, используем регулярное выражение
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
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
  Future<String?> _getChatNameFromSocket(int chatId,
      {String? chatUniqueId}) async {
    try {
      // Используем uniqueId если доступен, иначе chatId
      final chatIdentifier = chatUniqueId ?? chatId.toString();
      debugPrint(
          '🔌 Getting chat name from socket for chatIdentifier: $chatIdentifier (uniqueId: $chatUniqueId, chatId: $chatId)');

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

      final channelName = 'presence-chat.$chatIdentifier';
      final presenceChannel = tempSocketClient.presenceChannel(
        channelName,
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

  String _tr(String key, String fallback) {
    return AppLocalizations.of(context)?.translate(key) ?? fallback;
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    showCustomSnackBar(
      context: context,
      message: message,
      isSuccess: isSuccess,
    );
  }

  void _closeLoaderIfNeeded() {
    if (!mounted) return;
    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {}
  }

  void _removeNotificationFromCurrentState(int notificationId) {
    if (!mounted || notificationBloc.state is! NotificationDataLoaded) {
      return;
    }

    setState(() {
      (notificationBloc.state as NotificationDataLoaded)
          .notifications
          .removeWhere((notification) => notification.id == notificationId);
    });
    notificationBloc.add(DeleteNotification(notificationId));
  }

  Widget _buildEmptyNotificationsState(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.2,
        left: 24,
        right: 24,
      ),
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.surfaceInteractive,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            size: 34,
            color: colors.iconBrand,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _tr('no_notifications_yet', 'У вас пока нет уведомлений.'),
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _tr(
            'notifications_empty_hint',
            'Новые уведомления появятся здесь.',
          ),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(Notifications notification) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.buttonDangerBackground,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.delete_outline_rounded,
          color: colors.buttonDangerForeground,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        debugPrint("🗑️ [DELETE] Удаление уведомления ID: ${notification.id}");
        setState(() {
          (notificationBloc.state as NotificationDataLoaded)
              .notifications
              .removeWhere((item) => item.id == notification.id);
        });
        notificationBloc.add(DeleteNotification(notification.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.borderSecondary),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.surfaceInteractive,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: colors.iconBrand,
              size: 24,
            ),
          ),
          title: Text(
            _getNotificationTitle(context, notification.type),
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                _stripHtmlTags(notification.message),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: colors.iconSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(
                      notification.createdAt.add(const Duration(hours: 5)),
                    ),
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            debugPrint(
              "🔔 [TAP] Нажатие на уведомление ID: ${notification.id}, тип: ${notification.type}",
            );
            navigateToScreen(
              notification.type,
              notification.id,
              notification.modelId,
            );
          },
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    debugPrint('🔄 [REFRESH] Обновление списка уведомлений');
    notificationBloc.add(FetchNotifications());
    return Future.delayed(const Duration(milliseconds: 1500));
  }

  void _navigateToHomeScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen()),
      (route) => false,
    );
  }

  void _clearAllNotifications() async {
    debugPrint('🗑️ [DELETE ALL] Запрос на удаление всех уведомлений');

    if (notificationBloc.state is NotificationDataLoaded) {
      final currentState = notificationBloc.state as NotificationDataLoaded;
      if (currentState.notifications.isEmpty) {
        debugPrint('⚠️ Нет уведомлений для удаления');
        _showMessage(
          _tr('no_notifications_to_delete', 'Нет уведомлений для удаления'),
        );
        return;
      }
    }
    final bool? confirmed = await showAppConfirmDialog(
      context: context,
      title: _tr('confirm_delete', 'Подтверждение'),
      message: _tr(
        'delete_all_notifications_message',
        'Вы уверены, что хотите удалить все уведомления? Это действие нельзя отменить.',
      ),
      confirmLabel: _tr('delete', 'Удалить'),
      cancelLabel: _tr('cancel', 'Отмена'),
      isDestructive: true,
    );

    if (confirmed == true) {
      debugPrint('✅ Пользователь подтвердил удаление');

      notificationBloc.add(DeleteAllNotification());

      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('hasNewNotification', false);
      });
    } else {
      debugPrint('❌ Пользователь отменил удаление');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _tr('notifications', 'Уведомления'),
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: colors.iconPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 16,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.error,
                      size: 24,
                    ),
                    onPressed: _clearAllNotifications,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 16,
                    icon: Icon(
                      Icons.home_rounded,
                      color: colors.iconPrimary,
                      size: 22,
                    ),
                    onPressed: _navigateToHomeScreen,
                  ),
                ),
              ],
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
            _showMessage(
              state.message,
              isSuccess: state.statusCode != null &&
                  successCodes.contains(state.statusCode),
            );
          } else if (state is NotificationDeleted) {
            _showMessage(
              state.statusCode != null &&
                      successCodes.contains(state.statusCode)
                  ? _tr(
                      'all_notifications_deleted_successfully',
                      'Все уведомления успешно удалены!',
                    )
                  : state.message,
              isSuccess: state.statusCode != null &&
                  successCodes.contains(state.statusCode),
            );
          } else if (state is NotificationError) {
            _showMessage(state.message);
          }
        },
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            debugPrint("🔄 [BUILD] Состояние BLoC: ${state.runtimeType}");

            if (state is NotificationLoading) {
              debugPrint("🔄 [BUILD] Показываем начальную загрузку");
              return const Center(child: CircularProgressIndicator());
            } else if (state is NotificationError) {
              debugPrint("❌ [BUILD] Ошибка: ${state.message}");
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              );
            } else if (state is NotificationDeleted) {
              return RefreshIndicator(
                color: colors.selectionBackground,
                backgroundColor: colors.surfacePrimary,
                onRefresh: _onRefresh,
                child: _buildEmptyNotificationsState(context),
              );
            } else if (state is NotificationDataLoaded) {
              final notifications = state.notifications;
              final isAllLoaded = notificationBloc.allNotificationsFetched;

              debugPrint(
                  "✅ [BUILD] Уведомлений: ${notifications.length}, все загружено: $isAllLoaded");

              return RefreshIndicator(
                color: colors.selectionBackground,
                backgroundColor: colors.surfacePrimary,
                onRefresh: _onRefresh,
                child: notifications.isEmpty
                    ? _buildEmptyNotificationsState(context)
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: notifications.length + (isAllLoaded ? 0 : 1),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        itemBuilder: (context, index) {
                          if (index == notifications.length) {
                            if (!isAllLoaded && _isLoadingMore) {
                              debugPrint(
                                  "🔄 [BUILD] Показываем индикатор пагинации");
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                    child: CircularProgressIndicator(
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

                          return _buildNotificationTile(notification);
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
        _showMessage('Ошибка инициализации. Попробуйте снова.');
        return;
      }
    }

    try {
      if (type == 'message') {
        debugPrint('📱 Processing MESSAGE type notification');
        showAppLoadingDialog(context);

        try {
          debugPrint('📡 Calling getChatById($chatId)...');
          debugPrint(
              '📡 Using ApiService with baseUrl: ${_apiService.baseUrl}');

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
            chatName =
                getChatById.name.isNotEmpty ? getChatById.name : 'Лид #$chatId';

            chatScreen = ChatSmsScreen(
              chatItem: Chats(
                id: chatId,
                uniqueId: getChatById.uniqueId,
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
              chatUniqueId: getChatById.uniqueId,
              endPointInTab: endPointInTab,
              canSendMessage: getChatById.canSendMessage,
            );
          } else if (getChatById.type == "task") {
            debugPrint('🎯 Creating TASK chat screen');
            debugPrint('📡 Calling getTaskProfile($chatId)...');
            endPointInTab = 'task';

            final chatProfileTask = await _apiService.getTaskProfile(chatId);
            debugPrint(
                '✅ getTaskProfile completed: name=${chatProfileTask.name}');

            chatName = chatProfileTask.name.isNotEmpty
                ? chatProfileTask.name
                : 'Задача #$chatId';

            chatScreen = ChatSmsScreen(
              chatItem: Chats(
                id: chatId,
                uniqueId: getChatById.uniqueId,
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
              chatUniqueId: getChatById.uniqueId,
              endPointInTab: endPointInTab,
              canSendMessage: getChatById.canSendMessage,
            );
          } else if (getChatById.type == "corporate") {
            debugPrint('🎯 Creating CORPORATE chat screen');
            endPointInTab = 'corporate';

            final prefs = await SharedPreferences.getInstance();
            String userId = prefs.getString('userID').toString();

            debugPrint(
                '📊 Server data: name="${getChatById.name}", chatUsers.length=${getChatById.chatUsers.length}, group=${getChatById.group?.name}');

            if (getChatById.group != null) {
              chatName = getChatById.group!.name;
              debugPrint('✅ [1] Using GROUP name: $chatName');
            } else if (getChatById.name.isNotEmpty &&
                getChatById.name != 'null') {
              chatName = getChatById.name;
              debugPrint('✅ [2] Using server name: $chatName');
            } else if (getChatById.chatUsers.isNotEmpty &&
                getChatById.chatUsers.length >= 2) {
              int userIndex = getChatById.chatUsers.indexWhere(
                  (user) => user.participant.id.toString() == userId);

              if (userIndex != -1) {
                int otherUserIndex = (userIndex == 0) ? 1 : 0;
                chatName =
                    getChatById.chatUsers[otherUserIndex].participant.name;
                debugPrint('✅ [3] Using OTHER user from chatUsers: $chatName');
              } else {
                chatName = getChatById.chatUsers[0].participant.name;
                debugPrint('✅ [4] Using first chatUser: $chatName');
              }
            } else {
              // ✅ НЕ ЗАКРЫВАЕМ LOADER - продолжаем крутить, пока грузим из socket
              debugPrint('⚠️ Server returned NO data, getting from socket...');
              shouldCloseLoader = false; // ✅ Оставляем loader крутиться

              try {
                final socketName = await _getChatNameFromSocket(chatId,
                    chatUniqueId: getChatById.uniqueId);

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
                uniqueId: getChatById.uniqueId,
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
              chatUniqueId: getChatById.uniqueId,
              endPointInTab: endPointInTab,
              canSendMessage: getChatById.canSendMessage,
            );
          }

          if (shouldCloseLoader && mounted) {
            _closeLoaderIfNeeded();
            debugPrint('✅ Loader closed');
          }

          if (chatScreen != null) {
            debugPrint('🚀 Pushing chat screen to navigator...');
            debugPrint(
                '📋 Chat details: name="$chatName", endPoint="$endPointInTab"');

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
              _removeNotificationFromCurrentState(notificationId);
              debugPrint('✅ Notification removed');
            }
          } else {
            debugPrint(
                '❌ chatScreen is NULL - unknown chat type: ${getChatById.type}');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ ERROR in message navigation: $e');
          debugPrint('StackTrace: $stackTrace');

          _closeLoaderIfNeeded();

          if (e.toString().contains('404')) {
            _showMessage('Ресурс не найден.');
          }
        }
      } else if (type == 'task' ||
          type == 'taskFinished' ||
          type == 'taskOutDated') {
        debugPrint('📋 Processing TASK type notification');
        showAppLoadingDialog(context);

        try {
          debugPrint('📡 Calling getTaskById($chatId)...');
          final taskDetails = await _apiService.getTaskById(chatId);
          debugPrint('✅ getTaskById completed: name=${taskDetails.name}');

          if (mounted) {
            _closeLoaderIfNeeded();
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
            _removeNotificationFromCurrentState(notificationId);
            debugPrint('✅ Notification removed');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ ERROR in task navigation: $e');
          debugPrint('StackTrace: $stackTrace');

          _closeLoaderIfNeeded();
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
          _removeNotificationFromCurrentState(notificationId);
          debugPrint('✅ Notification removed');
        }
      } else if (type == 'dealDeadLineNotification') {
        debugPrint('💼 Processing DEAL type notification');

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
          _removeNotificationFromCurrentState(notificationId);
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
          _removeNotificationFromCurrentState(notificationId);
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
          _removeNotificationFromCurrentState(notificationId);
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

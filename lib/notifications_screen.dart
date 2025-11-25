import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_bloc.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_event.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_state.dart';
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
  bool _isLoadingMore = false; // ✅ НОВОЕ: Флаг для отслеживания загрузки

  @override
  void initState() {
    super.initState();
    notificationBloc = BlocProvider.of<NotificationBloc>(context);
    notificationBloc.add(FetchNotifications());

    _scrollController.addListener(() {
      // ✅ ИСПРАВЛЕНИЕ: Проверяем флаг загрузки
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 && // ✅ Загружаем за 200px до конца
          !_isLoadingMore &&
          !notificationBloc.allNotificationsFetched) {

        _isLoadingMore = true;
        debugPrint('📄 [PAGINATION] Загрузка следующей страницы');

        notificationBloc.add(FetchMoreNotifications(
            notificationBloc.state is NotificationDataLoaded
                ? (notificationBloc.state as NotificationDataLoaded).currentPage
                : 1
        ));
      }
    });
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
    debugPrint('🗑️ [DELETE ALL] Удаление всех уведомлений');
    notificationBloc.add(DeleteAllNotification());
    setState(() {
      if (notificationBloc.state is NotificationDataLoaded) {
        (notificationBloc.state as NotificationDataLoaded).notifications.clear();
      }
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('hasNewNotification', false);
    });
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
          // ✅ ИСПРАВЛЕНИЕ: Сбрасываем флаг загрузки после завершения
          if (state is NotificationDataLoaded) {
            _isLoadingMore = false;
            debugPrint('✅ [STATE] Данные загружены, всего: ${state.notifications.length}');
            debugPrint('📊 [STATE] Все загружено: ${notificationBloc.allNotificationsFetched}');
          } else if (state is NotificationError) {
            _isLoadingMore = false;
            debugPrint('❌ [STATE] Ошибка: ${state.message}');
          }

          // Обработка снекбаров
          final successCodes = [200, 201, 204, 429];

          if (state is NotificationSuccess) {
            if (state.statusCode != null && successCodes.contains(state.statusCode)) {
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else if (state is NotificationDeleted) {
            if (state.statusCode != null && successCodes.contains(state.statusCode)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate('all_notifications_deleted_successfully'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: CircularProgressIndicator(color: Color(0xff1E2E52))
              );
            } else if (state is NotificationError) {
              debugPrint("❌ [BUILD] Ошибка: ${state.message}");
              return Center(child: Text(state.message));
            } else if (state is NotificationDeleted) {
              // После удаления всех уведомлений показываем пустой список
              return RefreshIndicator(
                color: Color(0xff1E2E52),
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                    Center(
                        child: Text(
                            AppLocalizations.of(context)!.translate('no_notifications_yet')
                        )
                    ),
                  ],
                ),
              );
            } else if (state is NotificationDataLoaded) {
              final notifications = state.notifications;
              final isAllLoaded = notificationBloc.allNotificationsFetched;

              debugPrint("✅ [BUILD] Уведомлений: ${notifications.length}, все загружено: $isAllLoaded");

              return RefreshIndicator(
                color: Color(0xff1E2E52),
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: notifications.isEmpty
                    ? ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                    Center(
                        child: Text(
                            AppLocalizations.of(context)!.translate('no_notifications_yet')
                        )
                    ),
                  ],
                )
                    : ListView.builder(
                  controller: _scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  // ✅ ИСПРАВЛЕНИЕ: Показываем лоадер только если НЕ все загружено
                  itemCount: notifications.length + (isAllLoaded ? 0 : 1),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  itemBuilder: (context, index) {
                    // ✅ ИСПРАВЛЕНИЕ: Показываем лоадер только если идет загрузка
                    if (index == notifications.length) {
                      if (!isAllLoaded && _isLoadingMore) {
                        debugPrint("🔄 [BUILD] Показываем индикатор пагинации");
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff1E2E52),
                                strokeWidth: 2,
                              )
                          ),
                        );
                      } else if (!isAllLoaded) {
                        // Показываем заглушку для инициации загрузки
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
                        child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 24
                        ),
                      ),
                      onDismissed: (direction) {
                        debugPrint("🗑️ [DELETE] Удаление уведомления ID: ${notification.id}");
                        setState(() {
                          notifications.removeAt(index);
                        });
                        notificationBloc.add(DeleteNotification(notification.id));
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
                          leading: const Icon(
                              Icons.notifications,
                              color: Color(0xff1E2E52),
                              size: 24
                          ),
                          title: Text(
                            _getNotificationTitle(context, notification.type),
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
                                        notification.createdAt.add(Duration(hours: 5))
                                    ),
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
                            debugPrint("🔔 [TAP] Нажатие на уведомление ID: ${notification.id}, тип: ${notification.type}");
                            navigateToScreen(
                                notification.type,
                                notification.id,
                                notification.modelId
                            );
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

  // ✅ НОВОЕ: Вынесли логику определения заголовка в отдельный метод
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
    setState(() {
      (notificationBloc.state as NotificationDataLoaded)
          .notifications
          .removeWhere((notification) => notification.id == notificationId);
    });

    notificationBloc.add(DeleteNotification(notificationId));

    if (type == 'message') {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xff1E2E52)),
          );
        },
      );

      try {
        final getChatById = await ApiService().getChatById(chatId);
        Navigator.of(context).pop();

        if (getChatById.type == "lead") {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => MessagingCubit(ApiService()),
                child: ChatSmsScreen(
                  chatItem: Chats(
                    id: chatId,
                    name: getChatById.name,
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
                  endPointInTab: 'task',
                  canSendMessage: getChatById.canSendMessage,
                ),
              ),
            ),
          );
        } else if (getChatById.type == "corporate") {
          String? chatName;
          final prefs = await SharedPreferences.getInstance();
          String userId = prefs.getString('userID').toString();

          if (getChatById.group != null) {
            chatName = getChatById.group!.name;
          } else {
            int userIndex = getChatById.chatUsers.indexWhere(
                    (user) => user.participant.id.toString() == userId);
            if (userIndex != -1) {
              int otherUserIndex = (userIndex == 0) ? 1 : 0;
              chatName = '${getChatById.chatUsers[otherUserIndex].participant.name}';
            } else {
              chatName = getChatById.chatUsers[0].participant.name;
            }
          }

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => MessagingCubit(ApiService()),
                child: ChatSmsScreen(
                  chatItem: Chats(
                    id: chatId,
                    image: '',
                    name: chatName.toString(),
                    channel: "",
                    lastMessage: "",
                    messageType: "",
                    createDate: "",
                    unreadCount: 0,
                    canSendMessage: getChatById.canSendMessage,
                    chatUsers: [],
                  ).toChatItem(),
                  chatId: chatId,
                  endPointInTab: 'corporate',
                  canSendMessage: getChatById.canSendMessage,
                ),
              ),
            ),
          );

          if (mounted) {
            notificationBloc.add(FetchNotifications());
          }
        }
      } catch (e) {
        Navigator.of(context).pop();
        if (e.toString().contains('404')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ресурс не найден для задачи.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (type == 'task' || type == 'taskFinished' || type == 'taskOutDated') {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xff1E2E52)),
          );
        },
      );

      try {
        final taskDetails = await ApiService().getTaskById(chatId);
        Navigator.of(context).pop();

        navigatorKey.currentState?.push(
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
      } catch (e) {
        Navigator.of(context).pop();
      }
    } else if (type == 'notice') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => LeadDetailsScreen(
            leadId: chatId.toString(),
            leadName: '',
            leadStatus: "",
            statusId: 1,
          ),
        ),
      );
    } else if (type == 'dealDeadLineNotification') {
      List<DealCustomField> defaultCustomFields = [
        DealCustomField(id: 1, key: '', value: ''),
        DealCustomField(id: 2, key: '', value: ''),
      ];
      navigatorKey.currentState?.push(
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
    } else if (type == 'lead' || type == 'updateLeadStatus') {
      List<LeadCustomField> defaultCustomFields = [
        LeadCustomField(id: 1, key: '', value: ''),
        LeadCustomField(id: 2, key: '', value: ''),
      ];
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => LeadDetailsScreen(
            leadId: chatId.toString(),
            leadName: '',
            leadStatus: '',
            statusId: 1,
          ),
        ),
      );
    } else if (type == 'myTaskOutDated') {
      navigatorKey.currentState?.push(
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
    }
  }
}
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_bloc.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_event.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_state.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationBloc notificationBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    notificationBloc = BlocProvider.of<NotificationBloc>(context);
    notificationBloc.add(FetchNotifications());

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (!notificationBloc.allNotificationsFetched) {
          notificationBloc.add(FetchMoreNotifications(notificationBloc.state
                  is NotificationDataLoaded
              ? (notificationBloc.state as NotificationDataLoaded).currentPage
              : 1));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FD),
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Уведомления',
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
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center( child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          } else if (state is NotificationError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${state.message}',
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
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 2),
                ),
              );
            });
          } else if (state is NotificationDataLoaded) {
            final notifications = state.notifications;

            return notifications.isEmpty
                ? Center(child: const Text('У вас пока нет уведомлений.'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: notifications.length +
                        (notificationBloc.allNotificationsFetched ? 0 : 1),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemBuilder: (context, index) {
                      if (index == notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        );
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
                            size: 28,
                          ),
                        ),
                        onDismissed: (direction) {
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.notifications,
                                color: Color(0xff1E2E52), size: 28),
                            title: Text(
                              notification.type == 'message'
                                  ? 'Новое сообщение'
                                  : notification.type == 'deal'
                                      ? 'Сделка'
                                      : notification.type == 'notice'
                                          ? 'Новая заметка'
                                          : notification.type == 'task'
                                              ? 'Новая задача'
                                              : notification.type,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff1E2E52)),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(notification.message,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff5A6B87))),
                            ),
                            trailing: Text(
                              DateFormat('dd.MM.yyyy HH:mm')
                                  .format(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              ),
                            ),
                            onTap: () {
                              navigateToScreen(
                                  notification.type,
                                  notification.id,
                                  notification.modelId.toString());
                            },
                          ),
                        ),
                      );
                    },
                  );
          }
          return Container();
        },
      ),
    );
  }

  void navigateToScreen(String type, int notificationId, String id) {
    setState(() {
      (notificationBloc.state as NotificationDataLoaded)
          .notifications
          .removeWhere((notification) => notification.id == notificationId);
    });

    notificationBloc.add(DeleteNotification(notificationId));

    if (type == 'message') {
      print('Переход на экран чата с ID: $id');
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => MessagingCubit(ApiService()),
            child: ChatSmsScreen(
              chatItem: Chats(
                id: int.tryParse(id ?? '0') ?? 0,
                name: "",
                taskFrom: "",
                taskTo: "",
                description: "",
                channel: "",
                lastMessage: "",
                messageType: "",
                createDate: "",
                unredMessage: 0,
              ).toChatItem("assets/images/AvatarChat.png"),
              chatId: int.tryParse(id ?? '0') ?? 0,
              endPointInTab: 'lead',
            ),
          ),
        ),
      );
    } else if (type == 'task') {
      print('Переход на экран задачи с ID: $id');
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => TaskDetailsScreen(
            taskId: id ?? '',
            taskName: '',
            taskStatus: '',
            statusId: 1,
          ),
        ),
      );
    } else if (type == 'notice') {
      print('Переход на экран лида с ID: $id');
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => LeadDetailsScreen(
            leadId: id ?? '',
            leadName: '',
            leadStatus: "",
            statusId: 1,
          ),
        ),
      );
    } else if (type == 'deal') {
      print('Переход на экран сделки с ID: $id');
      List<DealCustomField> defaultCustomFields = [
        DealCustomField(id: 1, key: '', value: ''),
        DealCustomField(id: 2, key: '', value: ''),
      ];
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => DealDetailsScreen(
            dealId: id ?? '',
            dealName: '',
            sum: '',
            dealStatus: '',
            statusId: 1,
            dealCustomFields: defaultCustomFields,
          ),
        ),
      );
    } else {
      print('navigateToScreen: Неизвестный тип: $type');
    }
  }
}






// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_bloc.dart';
// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_event.dart';
// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_state.dart';
// import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
// import 'package:crm_task_manager/bloc/notifications/notifications_bloc.dart';
// import 'package:crm_task_manager/bloc/notifications/notifications_event.dart';
// import 'package:crm_task_manager/bloc/notifications/notifications_state.dart';
// import 'package:crm_task_manager/main.dart';
// import 'package:crm_task_manager/models/chats_model.dart';
// import 'package:crm_task_manager/models/deal_model.dart';
// import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
// import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
// import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
// import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';

// class NotificationsScreen extends StatefulWidget {
//   @override
//   _NotificationsScreenState createState() => _NotificationsScreenState();
// }

// class _NotificationsScreenState extends State<NotificationsScreen> {
//   late NotificationBloc notificationBloc;
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     notificationBloc = BlocProvider.of<NotificationBloc>(context);
//     notificationBloc.add(FetchNotifications());

//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels ==
//           _scrollController.position.maxScrollExtent) {
//         if (!notificationBloc.allNotificationsFetched) {
//           notificationBloc.add(FetchMoreNotifications(notificationBloc.state
//                   is NotificationDataLoaded
//               ? (notificationBloc.state as NotificationDataLoaded).currentPage
//               : 1));
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffF4F7FD),
//       appBar: AppBar(
//         forceMaterialTransparency: true,
//         backgroundColor: Colors.white,
//         elevation: 1,
//         centerTitle: true,
//         title: const Text(
//           'Уведомления',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//             color: Color(0xff1E2E52),
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Color(0xff1E2E52)),
//         leading: IconButton(
//           icon: Image.asset(
//             'assets/icons/arrow-left.png',
//             width: 24,
//             height: 24,
//           ),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),
//       ),
//       body: BlocBuilder<NotificationBloc, NotificationState>(
//         builder: (context, state) {
//           if (state is NotificationLoading) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (state is NotificationError) {
//             return Center(child: Text('Ошибка: ${state.message}'));
//           } else if (state is NotificationDataLoaded) {
//             final notifications = state.notifications;

//             return notifications.isEmpty
//                 ? Center(child: const Text('У вас пока нет уведомлений.'))
//                 : ListView.builder(
//                     controller: _scrollController,
//                     itemCount: notifications.length +
//                         (notificationBloc.allNotificationsFetched ? 0 : 1),
//                     padding:
//                         const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                     itemBuilder: (context, index) {
//                       if (index == notifications.length) {
//                         return const Padding(
//                           padding: EdgeInsets.symmetric(vertical: 16),
//                         );
//                       }

//                       final notification = notifications[index];

//                       return Dismissible(
//                         key: Key(notification.id.toString()),
//                         direction: DismissDirection.endToStart,
//                         background: Container(
//                           margin: const EdgeInsets.only(bottom: 12),
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.red,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           alignment: Alignment.centerRight,
//                           child: const Icon(
//                             Icons.delete,
//                             color: Colors.white,
//                             size: 28,
//                           ),
//                         ),
//                         onDismissed: (direction) {
//                           setState(() {
//                             notifications.removeAt(index);
//                           });

//                           notificationBloc
//                               .add(DeleteNotification(notification.id));
//                         },
//                         child: Container(
//                           margin: const EdgeInsets.only(bottom: 12),
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: ListTile(
//                             contentPadding: EdgeInsets.zero,
//                             leading: const Icon(Icons.notifications,
//                                 color: Color(0xff1E2E52), size: 28),
//                             title: Text(
//                               notification.type == 'message'
//                                   ? 'Новое сообщение'
//                                   : notification.type == 'deal'
//                                       ? 'Сделка'
//                                       : notification.type == 'notice'
//                                           ? 'Новая заметка'
//                                           : notification.type == 'task'
//                                               ? 'Новая задача'
//                                               : notification.type,
//                               style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                   color: Color(0xff1E2E52)),
//                             ),
//                             subtitle: Padding(
//                               padding: const EdgeInsets.only(top: 4),
//                               child: Text(notification.message,
//                                   style: const TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w400,
//                                       color: Color(0xff5A6B87))),
//                             ),
//                             trailing: Text(
//                               DateFormat('dd.MM.yyyy HH:mm')
//                                   .format(notification.createdAt),
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 fontFamily: 'Gilroy',
//                                 color: Color(0xff1E2E52),
//                               ),
//                             ),
//                             onTap: () {
//                               navigateToScreen(
//                                   notification.type,
//                                   notification.id,
//                                   notification.modelId.toString());
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   );
//           }
//           return Container();
//         },
//       ),
//     );
//   }

// void printChatProfile(int chatId) {
//   final chatProfileBloc = BlocProvider.of<ChatProfileBloc>(context);

//   chatProfileBloc.add(FetchChatProfile(chatId));

//   chatProfileBloc.stream.listen((state) {
//     if (state is ChatProfileLoaded) {
//       final profile = state.profile;
//       print('Chat Profile:');
//       print('ID: ${profile.id}');
//       print('Name: ${profile.name}');
//       print('Facebook Login: ${profile.facebookLogin}');
//       print('Instagram Login: ${profile.instaLogin}');
//       print('Telegram Nick: ${profile.tgNick}');
//       print('WhatsApp Name: ${profile.waName}');
//       print('WhatsApp Phone: ${profile.waPhone}');
//       print('Phone: ${profile.phone}');
//       print('Message Amount: ${profile.messageAmount}');
//       print('Address: ${profile.address}');
//       print('Description: ${profile.description}');
//       print('Created At: ${profile.createdAt}');
//       print('Manager: ${profile.manager}');
//       print('Lead Status: ${profile.leadStatus}');
//     } else if (state is ChatProfileError) {
//       // print('Error fetching chat profile: ${state.message}');
//     }
//   });
// }

//   void navigateToScreen(String type, int notificationId, String id) {
//     // setState(() {
//     //   (notificationBloc.state as NotificationDataLoaded)
//     //       .notifications
//     //       .removeWhere((notification) => notification.id == notificationId);
//     // });
    
//     // notificationBloc.add(DeleteNotification(notificationId));
//    int chatId = int.tryParse(id) ?? 0;
//     printChatProfile(chatId);
    
//     if (type == 'message') {
//       print('Переход на экран чата с ID: $id');
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (context) => BlocProvider(
//             create: (context) => MessagingCubit(ApiService()),
//             child: ChatSmsScreen(
//               chatItem: 
//               Chats(
//                 id: int.tryParse(id) ?? 0,
//                 name: "",
//                 taskFrom: "",
//                 taskTo: "",
//                 description: "",
//                 channel: "",
//                 lastMessage: "",
//                 messageType: "",
//                 createDate: "",
//                 unredMessage: 0,
//               ).toChatItem("assets/images/AvatarChat.png"),
//               chatId: int.tryParse(id ) ?? 0, 
//               endPointInTab: 'lead',
//             ),
//           ),
//         ),
//       );
//     } else if (type == 'task') {
//       print('Переход на экран задачи с ID: $id');
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (context) => TaskDetailsScreen(
//             taskId: id ?? '',
//             taskName: '',
//             taskStatus: '',
//             statusId: 1,
//           ),
//         ),
//       );
//     } else if (type == 'notice') {
//       print('Переход на экран лида с ID: $id');
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (context) => LeadDetailsScreen(
//             leadId: id ?? '',
//             leadName: '',
//             leadStatus: "",
//             statusId: 1,
//           ),
//         ),
//       );
//     } else if (type == 'deal') {
//       print('Переход на экран сделки с ID: $id');
//       List<DealCustomField> defaultCustomFields = [
//         DealCustomField(id: 1, key: '', value: ''),
//         DealCustomField(id: 2, key: '', value: ''),
//       ];
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (context) => DealDetailsScreen(
//             dealId: id ?? '',
//             dealName: '',
//             sum: '',
//             dealStatus: '',
//             statusId: 1,
//             dealCustomFields: defaultCustomFields,
//           ),
//         ),
//       );
//     } else {
//       print('navigateToScreen: Неизвестный тип: $type');
//     }
//   }
// }

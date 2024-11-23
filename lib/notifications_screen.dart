import 'package:crm_task_manager/bloc/notifications/notifications_bloc.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_event.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        is NotificationDataLoaded ? (notificationBloc.state as NotificationDataLoaded).currentPage : 1));
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
        title: const Text('Уведомления',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52))),
        iconTheme: const IconThemeData(color: Color(0xff1E2E52)),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationError) {
            return Center(child: Text('Ошибка: ${state.message}'));
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
                          // child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final notification = notifications[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.notifications,
                              color: Color(0xff1E2E52), size: 28),
                          title: Text(notification.type,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff1E2E52))),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(notification.message,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff5A6B87))),
                          ),
                          trailing: Text(
                            '${notification.createdAt.hour}:${notification.createdAt.minute}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff5A6B87)),
                          ),
                          // onTap: () {
                          //   showDialog(
                          //     context: context,
                          //     builder: (_) => AlertDialog(
                          //       title: Text(notification.message),
                          //       content: Text(notification.type),
                          //       actions: [
                          //         TextButton(
                          //             onPressed: () => Navigator.pop(context),
                          //             child: const Text('Закрыть')),
                          //       ],
                          //     ),
                          //   );
                          // },
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
}

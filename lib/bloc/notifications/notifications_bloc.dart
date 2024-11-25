import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_event.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_state.dart';
import 'package:crm_task_manager/models/notifications_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiService apiService;
  bool allNotificationsFetched = false; 

  NotificationBloc(this.apiService) : super(NotificationInitial()) {
    on<FetchNotifications>(_fetchNotifications);
    on<FetchMoreNotifications>(_fetchMoreNotifications);
    // on<DeleteNotification>(_deleteNotification);
  }

  // Метод для поиска уведомлений
 Future<void> _fetchNotifications(FetchNotifications event, Emitter<NotificationState> emit) async {
  emit(NotificationLoading());
  try {
    final notifications = await apiService.getAllNotifications(
      page: 1,
      perPage: 20,
    );
    allNotificationsFetched = notifications.isEmpty;
    emit(NotificationDataLoaded(notifications, currentPage: 1));
  } catch (e) {
    emit(NotificationError('Не удалось загрузить уведомления: ${e.toString()}'));
  }
}

Future<void> _fetchMoreNotifications(FetchMoreNotifications event, Emitter<NotificationState> emit) async {
  if (allNotificationsFetched) return;

  try {
    final notifications = await apiService.getAllNotifications(page: event.currentPage + 1);
    if (notifications.isEmpty) {
      allNotificationsFetched = true;
      return;
    }
    if (state is NotificationDataLoaded) {
      final currentState = state as NotificationDataLoaded;
      final updatedNotifications = List<Notifications>.from(currentState.notifications)
        ..addAll(notifications);
      emit(NotificationDataLoaded(updatedNotifications, currentPage: event.currentPage + 1));
    }
  } catch (e) {
    emit(NotificationError('Не удалось загрузить уведомления: ${e.toString()}'));
  }
}



}



  // Future<void> _deleteNotification(DeleteNotification event, Emitter<NotificationState> emit) async {
  //   emit(NotificationLoading());

  //   try {
  //     final response = await apiService.deleteNotification(event.notificationId);
  //     if (response['result'] == 'Success') {
  //       emit(NotificationDeleted('Уведомление удалено успешно'));
  //       add(FetchNotifications(event.notificationId)); // Перезагрузка уведомлений после удаления
  //     } else {
  //       emit(NotificationError('Ошибка удаления уведомления'));
  //     }
  //   } catch (e) {
  //     emit(NotificationError('Ошибка удаления уведомления: ${e.toString()}'));
  //   }
  // }
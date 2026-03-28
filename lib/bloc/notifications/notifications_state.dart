import 'package:crm_task_manager/models/notifications_model.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}



class NotificationDataLoaded extends NotificationState {
  final List<Notifications> notifications; // Заменить Notification на Notifications
  final int currentPage;

  NotificationDataLoaded(this.notifications, {this.currentPage = 1});

  // Метод для объединения с новыми уведомлениями
  NotificationDataLoaded merge(List<Notifications> newNotifications) {
    return NotificationDataLoaded([...notifications, ...newNotifications],
        currentPage: currentPage + 1);
  }
}


class NotificationError extends NotificationState {
  final String message;
  final int? statusCode;

  NotificationError(this.message, {this.statusCode});
}

class NotificationSuccess extends NotificationState {
  final String message;
  final int? statusCode;

  NotificationSuccess(this.message, {this.statusCode});
}

class NotificationDeleted extends NotificationState {
  final String message;
  final int? statusCode;

  NotificationDeleted(this.message, {this.statusCode});
}

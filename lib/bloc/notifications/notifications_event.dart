abstract class NotificationEvent {}

class FetchNotifications extends NotificationEvent {}

class FetchMoreNotifications extends NotificationEvent {
  final int currentPage;

  FetchMoreNotifications(this.currentPage);
}

class DeleteNotification extends NotificationEvent {
  final int notificationId;

  DeleteNotification(this.notificationId);
}

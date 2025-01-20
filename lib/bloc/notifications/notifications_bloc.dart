import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_event.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_state.dart';
import 'package:crm_task_manager/models/notifications_model.dart';
import 'package:crm_task_manager/notification_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiService apiService;
  bool allNotificationsFetched = false;

  NotificationBloc(this.apiService) : super(NotificationInitial()) {
    on<FetchNotifications>(_fetchNotifications);
    on<FetchMoreNotifications>(_fetchMoreNotifications);
    on<DeleteNotification>(_deleteNotification);
    on<DeleteAllNotification>(_deleteAllNotification); // Обрабатываем событие
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
  Future<void> _fetchMoreNotifications(FetchMoreNotifications event, Emitter<NotificationState> emit) async {
    if (allNotificationsFetched) return;

    if (await _checkInternetConnection()) {
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
        emit(NotificationError('Не удалось загрузить уведомления!'));
      }
    } else {
      emit(NotificationError('Нет подключения к интернету'));
    }
  }

Future<void> _fetchNotifications(FetchNotifications event, Emitter<NotificationState> emit) async {
  print("📥 [FETCH] Начинаем загрузку уведомлений...");
  emit(NotificationLoading());

  // Загружаем данные из кэша
  final cachedNotifications = await NotificationCacheHandler.getNotifications();
  if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
    print("📦 [CACHE] Найдены уведомления в кэше: ${cachedNotifications.length} шт.");
    emit(NotificationDataLoaded(cachedNotifications, currentPage: 1));
  } else {
    print("⚠️ [CACHE] Данных в кэше не найдено.");
    emit(NotificationDataLoaded([], currentPage: 1)); 
  }

  // Проверяем подключение к интернету
  if (await _checkInternetConnection()) {
    print("🌐 [NETWORK] Интернет подключен. Загружаем уведомления с сервера...");
    try {
      final notifications = await apiService.getAllNotifications(page: 1, perPage: 20);

      if (notifications.isNotEmpty) {
        print("✅ [SERVER] Успешно загружены уведомления: ${notifications.length} шт.");
        // Сохраняем данные в кэш
        await NotificationCacheHandler.saveNotifications(notifications);
        print("💾 [CACHE] Уведомления сохранены в кэш.");
        emit(NotificationDataLoaded(notifications, currentPage: 1));
      } else {
        print("⚠️ [SERVER] Сервер вернул пустой список уведомлений.");
        // Очищаем кэш, если сервер вернул пустой список
        await NotificationCacheHandler.clearCache();
        emit(NotificationDataLoaded([], currentPage: 1)); // Отправляем пустое состояние
      }
    } catch (e) {
      print("❌ [ERROR] Ошибка при загрузке уведомлений!");
      emit(NotificationError('Не удалось загрузить уведомления!'));
    }
  } else if (cachedNotifications == null || cachedNotifications.isEmpty) {
    print("🚫 [OFFLINE] Нет подключения к интернету и данных в кэше.");
    emit(NotificationError('Нет подключения к интернету и данных в кэше'));
  }
}


Future<void> _deleteAllNotification(DeleteAllNotification event, Emitter<NotificationState> emit) async {
  print("🗑️ [DELETE ALL] Удаление всех уведомлений...");
  if (await _checkInternetConnection()) {
    print("🌐 [NETWORK] Интернет подключен. Отправляем запрос на удаление всех уведомлений...");
    try {
      await apiService.DeleteAllNotifications();
      print("✅ [SERVER] Все уведомления успешно удалены.");

      // Очистка кэша
      await NotificationCacheHandler.clearCache();
      print("💾 [CACHE] Кэш уведомлений очищен.");
      emit(NotificationDeleted('Все уведомления успешно удалены'));
    } catch (e) {
      print("❌ [ERROR] Ошибка при удалении всех уведомлений!");
      emit(NotificationError('Ошибка удаления всех уведомлений'));
    }
  } else {
    print("🚫 [OFFLINE] Нет подключения к интернету. Удаление невозможно.");
    emit(NotificationError('Нет подключения к интернету'));
  }
}

Future<void> _deleteNotification(DeleteNotification event, Emitter<NotificationState> emit) async {
  print("🗑️ [DELETE] Удаление уведомления с ID: ${event.notificationId}...");
  if (await _checkInternetConnection()) {
    print("🌐 [NETWORK] Интернет подключен. Отправляем запрос на удаление уведомления...");
    try {
      await apiService.DeleteNotifications(notificationId: event.notificationId);
      print("✅ [SERVER] Уведомление с ID: ${event.notificationId} успешно удалено.");

      if (state is NotificationDataLoaded) {
        final currentState = state as NotificationDataLoaded;

        final updatedNotifications = currentState.notifications
            .where((notification) => notification.id != event.notificationId)
            .toList();

        // Обновляем кэш
        await NotificationCacheHandler.saveNotifications(updatedNotifications);
        print("💾 [CACHE] Кэш обновлен после удаления уведомления.");

        emit(NotificationDataLoaded(updatedNotifications, currentPage: currentState.currentPage));
      }
    } catch (e) {
      print("❌ [ERROR] Ошибка при удалении уведомления: $e");
      emit(NotificationError('Ошибка удаления уведомления!'));
    }
  } else {
    print("🚫 [OFFLINE] Нет подключения к интернету. Удаление невозможно.");
    emit(NotificationError('Нет подключения к интернету'));
  }
}
}

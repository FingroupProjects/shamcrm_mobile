import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_event.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_state.dart';
import 'package:crm_task_manager/models/notifications_model.dart';
import 'package:crm_task_manager/notification_cache.dart';
import 'package:flutter/material.dart';
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

  String _mapNotificationLoadError(Object error) {
    if (error is TimeoutException) {
      return 'Не удалось загрузить уведомления. Сервер долго не отвечает. Попробуйте еще раз.';
    }

    if (error is SocketException) {
      return 'Не удалось загрузить уведомления. Проверьте подключение к интернету.';
    }

    final errorText = error.toString().toLowerCase();

    if (errorText.contains('timeoutexception') ||
        errorText.contains('превышено время ожидания') ||
        errorText.contains('timed out')) {
      return 'Не удалось загрузить уведомления. Сервер долго не отвечает. Попробуйте еще раз.';
    }

    if (errorText.contains('socketexception') ||
        errorText.contains('connection') ||
        errorText.contains('network')) {
      return 'Не удалось загрузить уведомления. Проверьте подключение к интернету.';
    }

    return 'Не удалось загрузить уведомления. Попробуйте позже.';
  }

  String _mapNotificationDeleteError(Object error) {
    if (error is TimeoutException) {
      return 'Не удалось выполнить действие. Сервер долго не отвечает.';
    }

    if (error is SocketException) {
      return 'Не удалось выполнить действие. Проверьте подключение к интернету.';
    }

    return 'Не удалось выполнить действие. Попробуйте позже.';
  }

  Future<void> _fetchMoreNotifications(
      FetchMoreNotifications event, Emitter<NotificationState> emit) async {
    if (allNotificationsFetched) return;

    if (await _checkInternetConnection()) {
      try {
        final notifications =
            await apiService.getAllNotifications(page: event.currentPage + 1);
        if (notifications.isEmpty) {
          allNotificationsFetched = true;
          return;
        }
        if (state is NotificationDataLoaded) {
          final currentState = state as NotificationDataLoaded;
          final updatedNotifications =
              List<Notifications>.from(currentState.notifications)
                ..addAll(notifications);
          emit(NotificationDataLoaded(updatedNotifications,
              currentPage: event.currentPage + 1));
        }
      } catch (e) {
        emit(NotificationError(_mapNotificationLoadError(e)));
      }
    } else {
      emit(NotificationError('Нет подключения к интернету'));
    }
  }

  Future<void> _fetchNotifications(
      FetchNotifications event, Emitter<NotificationState> emit) async {
    //print("📥 [FETCH] Начинаем загрузку уведомлений...");
    emit(NotificationLoading());

    if (await _checkInternetConnection()) {
      //print("🌐 [NETWORK] Интернет подключен. Загружаем уведомления с сервера...");
      try {
        final notifications =
            await apiService.getAllNotifications(page: 1, perPage: 20);
        //print("✅ [SERVER] Успешно загружены уведомления: ${notifications.length} шт.");

        // Сохраняем данные в кэш
        await NotificationCacheHandler.saveNotifications(notifications);
        //print("💾 [CACHE] Уведомления сохранены в кэш.");
        emit(NotificationDataLoaded(notifications, currentPage: 1));
      } catch (e) {
        //print("❌ [ERROR] Ошибка при загрузке уведомлений: $e");
        // Пробуем загрузить из кэша, если сервер недоступен
        final cachedNotifications =
            await NotificationCacheHandler.getNotifications();
        if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
          //print("📦 [CACHE] Найдены уведомления в кэше: ${cachedNotifications.length} шт.");
          emit(NotificationDataLoaded(cachedNotifications, currentPage: 1));
        } else {
          //print("🚫 [OFFLINE] Нет данных в кэше.");
          emit(NotificationError(_mapNotificationLoadError(e)));
        }
      }
    } else {
      //print("🚫 [OFFLINE] Нет подключения к интернету. Проверяем кэш...");
      final cachedNotifications =
          await NotificationCacheHandler.getNotifications();
      if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
        //print("📦 [CACHE] Найдены уведомления в кэше: ${cachedNotifications.length} шт.");
        emit(NotificationDataLoaded(cachedNotifications, currentPage: 1));
      } else {
        //print("🚫 [OFFLINE] Нет подключения к интернету и данных в кэше.");
        emit(NotificationError('Нет подключения к интернету и данных в кэше'));
      }
    }
  }

  Future<void> _deleteAllNotification(
      DeleteAllNotification event, Emitter<NotificationState> emit) async {
    debugPrint("🗑️ [DELETE ALL] Удаление всех уведомлений...");

    // Проверяем, есть ли уведомления для удаления
    if (state is NotificationDataLoaded) {
      final currentState = state as NotificationDataLoaded;
      if (currentState.notifications.isEmpty) {
        debugPrint(
            "⚠️ [DELETE ALL] Список уведомлений пуст, пропускаем запрос");
        return;
      }
    }

    if (await _checkInternetConnection()) {
      debugPrint(
          "🌐 [NETWORK] Интернет подключен. Отправляем запрос на удаление всех уведомлений...");

      try {
        final statusCode = await apiService.DeleteAllNotifications();
        debugPrint(
            "✅ [SERVER] Все уведомления успешно удалены. Status code: $statusCode");

        // Очистка кэша
        await NotificationCacheHandler.clearCache();
        debugPrint("💾 [CACHE] Кэш уведомлений очищен.");

        final successCodes = [200, 201, 204, 429];
        if (successCodes.contains(statusCode)) {
          // Сначала эмитим пустой список
          emit(NotificationDataLoaded([], currentPage: 1));

          // Небольшая задержка перед показом сообщения об успехе
          await Future.delayed(Duration(milliseconds: 100));

          // Затем эмитим состояние успеха для snackbar
          emit(NotificationDeleted(
            'Все уведомления успешно удалены',
            statusCode: statusCode,
          ));
        } else {
          emit(NotificationError(
            'Ошибка удаления всех уведомлений',
            statusCode: statusCode,
          ));
        }
      } catch (e, stackTrace) {
        debugPrint("❌ [ERROR] Ошибка при удалении всех уведомлений: $e");
        debugPrint("StackTrace: $stackTrace");
        emit(NotificationError(_mapNotificationDeleteError(e)));
      }
    } else {
      debugPrint(
          "🚫 [OFFLINE] Нет подключения к интернету. Удаление невозможно.");
      emit(NotificationError('Нет подключения к интернету'));
    }
  }

  Future<void> _deleteNotification(
      DeleteNotification event, Emitter<NotificationState> emit) async {
    ////print("🗑️ [DELETE] Удаление уведомления с ID: ${event.notificationId}...");
    if (await _checkInternetConnection()) {
      ////print("🌐 [NETWORK] Интернет подключен. Отправляем запрос на удаление уведомления...");
      try {
        final statusCode = await apiService.DeleteNotifications(
            notificationId: event.notificationId);
        ////print("✅ [SERVER] Уведомление с ID: ${event.notificationId} успешно удалено. Status code: $statusCode");

        // Успешные коды: 200, 201, 204, 429
        final successCodes = [200, 201, 204, 429];
        if (successCodes.contains(statusCode)) {
          if (state is NotificationDataLoaded) {
            final currentState = state as NotificationDataLoaded;

            final updatedNotifications = currentState.notifications
                .where(
                    (notification) => notification.id != event.notificationId)
                .toList();

            // Обновляем кэш
            await NotificationCacheHandler.saveNotifications(
                updatedNotifications);
            ////print("💾 [CACHE] Кэш обновлен после удаления уведомления.");

            emit(NotificationDataLoaded(updatedNotifications,
                currentPage: currentState.currentPage));
          }
        } else {
          emit(NotificationError('Ошибка удаления уведомления!',
              statusCode: statusCode));
        }
      } catch (e) {
        ////print("❌ [ERROR] Ошибка при удалении уведомления: $e");
        emit(NotificationError(_mapNotificationDeleteError(e)));
      }
    } else {
      ////print("🚫 [OFFLINE] Нет подключения к интернету. Удаление невозможно.");
      emit(NotificationError('Нет подключения к интернету'));
    }
  }
}

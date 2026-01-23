import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/localization_service.dart';
import 'package:crm_task_manager/api/service/widget_service.dart';
import 'package:crm_task_manager/bloc/permission/permession_event.dart';
import 'package:crm_task_manager/bloc/permission/permession_state.dart';
import 'package:crm_task_manager/models/permission.dart';
import 'package:crm_task_manager/screens/profile/languages/local_manager_lang.dart';
import 'package:flutter/foundation.dart';

class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  final ApiService apiService;

  PermissionsBloc(this.apiService) : super(PermissionsInitial()) {
    on<FetchPermissionsEvent>(_fetchPermissions);
  }

  Future<void> _fetchPermissions(
      FetchPermissionsEvent event, Emitter<PermissionsState> emit) async {
    emit(PermissionsLoading());
    
    // Количество попыток при сетевых ошибках
    const int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        final permissions = await apiService.fetchPermissionsByRoleId();

        // ✅ КЛЮЧЕВАЯ ЛОГИКА: Если пришел пустой массив - это реально нет доступа
        if (permissions.isEmpty) {
          if (kDebugMode) {
            debugPrint('PermissionsBloc: Получен пустой массив permissions - нет доступа');
          }
          emit(PermissionsNoAccess());
          return;
        }

        List<PermissionsModel> permissionModels = permissions
            .map((permission) => PermissionsModel(permissions: [permission]))
            .toList();

        await apiService.savePermissions(permissions);
        
        // ✅ ИЗМЕНЕНО: Запрос локализации синхронно (await), чтобы применялось сразу
        await _fetchAndApplyLocalization();
        
        // Sync permissions to iOS widget via App Groups
        await WidgetService.syncPermissionsToWidget(permissions);
        
        // Sync visibility flags to Android widget
        // Warehouse/Accounting - requires accounting_of_goods OR accounting_money
        final hasWarehouseAccess = permissions.contains('accounting_of_goods') || 
                                   permissions.contains('accounting_money');
        
        // Orders - requires order.read AND warehouse access
        final hasOrdersAccess = permissions.contains('order.read') && hasWarehouseAccess;
        
        // Online Store - requires order.read WITHOUT warehouse access
        final hasOnlineStoreAccess = permissions.contains('order.read') && !hasWarehouseAccess;
        
        await WidgetService.syncWidgetVisibilityToAndroid({
          'dashboard': permissions.contains('section.dashboard'),
          'tasks': permissions.contains('task.read'),
          'leads': permissions.contains('lead.read'),
          'deals': permissions.contains('deal.read'),
          'chats': true, // Chats always visible
          'warehouse': hasWarehouseAccess,
          'orders': hasOrdersAccess,
          'online_store': hasOnlineStoreAccess,
        });
        
        // Also sync current language to widget
        await LanguageManager.syncCurrentLanguageToWidget();
        
        emit(PermissionsLoaded(permissionModels));
        return; // Успешно загружено, выходим
      } catch (e) {
        // Проверяем, является ли это сетевой ошибкой
        final isNetworkError = _isNetworkError(e);
        
        if (isNetworkError) {
          retryCount++;
          if (kDebugMode) {
            debugPrint('PermissionsBloc: Сетевая ошибка (попытка $retryCount/$maxRetries): $e');
          }
          
          if (retryCount < maxRetries) {
            // Ждем перед повторной попыткой (экспоненциальная задержка)
            await Future.delayed(Duration(seconds: retryCount));
            continue; // Повторяем попытку
          } else {
            // Все попытки исчерпаны
            if (kDebugMode) {
              debugPrint('PermissionsBloc: Все попытки исчерпаны, сетевой сбой');
            }
            emit(PermissionsNetworkError('Не удалось получить данные. Проверьте подключение к интернету.'));
            return;
          }
        } else {
          // Это не сетевая ошибка (например, ошибка авторизации или другая)
          if (kDebugMode) {
            debugPrint('PermissionsBloc: Ошибка (не сетевая): $e');
          }
          emit(PermissionsError('Ошибка при загрузке прав доступа!'));
          return;
        }
      }
    }
  }

  /// Проверяет, является ли ошибка сетевой
  bool _isNetworkError(dynamic error) {
    if (error is SocketException) {
      return true;
    }
    if (error is TimeoutException) {
      return true;
    }
    if (error is HttpException) {
      return true;
    }
    // Проверяем строковое представление ошибки
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socket') ||
        errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('no internet')) {
      return true;
    }
    return false;
  }

  /// Получить и применить локализацию с сервера (синхронно)
  Future<void> _fetchAndApplyLocalization() async {
    try {
      if (kDebugMode) {
        debugPrint('PermissionsBloc: Получаем локализацию с сервера...');
      }
      
      final localizationResponse = await apiService.getLocalization();
      
      if (localizationResponse?.result != null) {
        final newLanguage = localizationResponse!.result!.language ?? 'ru';
        final newPhoneCode = localizationResponse.result!.countryPhoneCodes ?? '+992';
        
        // Получаем текущие сохранённые значения
        final currentLanguage = await LocalizationService.getLanguage();
        final currentPhoneCode = await LocalizationService.getDialCode();
        
        if (kDebugMode) {
          debugPrint('PermissionsBloc: Текущие настройки - язык: $currentLanguage, код: $currentPhoneCode');
          debugPrint('PermissionsBloc: Новые настройки - язык: $newLanguage, код: $newPhoneCode');
        }
        
        // Сохраняем настройки локализации в SharedPreferences
        await LocalizationService.applyLocalizationSettings(
          language: newLanguage,
          phoneCode: newPhoneCode,
        );
        
        if (kDebugMode) {
          debugPrint('PermissionsBloc: Локализация сохранена и применена успешно');
        }
      } else {
        if (kDebugMode) {
          debugPrint('PermissionsBloc: Не удалось получить локализацию с сервера');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PermissionsBloc: Ошибка при получении локализации: $e');
      }
      // Ошибка не критична - используем сохранённые настройки
    }
  }

  /// Получить список всех разрешений из текущего состояния
  List<String> getAllPermissions() {
    if (state is PermissionsLoaded) {
      final loadedState = state as PermissionsLoaded;
      // Извлекаем все разрешения из списка PermissionsModel
      return loadedState.permissions
          .expand((model) => model.permissions)
          .toList();
    }
    return [];
  }

  /// Проверить наличие конкретного разрешения
  bool hasPermission(String permission) {
    return getAllPermissions().contains(permission);
  }
}
